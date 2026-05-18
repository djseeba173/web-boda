Add-Type -AssemblyName System.IO.Compression

$excelPath = Join-Path $PSScriptRoot "resources\excel invitados+mesa.xlsx"
$outputPath = Join-Path $PSScriptRoot "guest-data.js"

if (-not (Test-Path $excelPath)) {
  throw "No se encontro el archivo Excel en: $excelPath"
}

function Get-CellValue {
  param(
    [object]$Cell,
    [string[]]$SharedStrings
  )

  $value = [string]$Cell.v

  if ($Cell.t -eq "s" -and $value -ne "") {
    return $SharedStrings[[int]$value]
  }

  return $value
}

function Convert-DisplayName {
  param([string]$Name)

  if ([string]::IsNullOrWhiteSpace($Name)) {
    return ""
  }

  $textInfo = [System.Globalization.CultureInfo]::GetCultureInfo("es-AR").TextInfo
  $words = $Name -split "\s+"
  $convertedWords = foreach ($word in $words) {
    if ($word -cmatch "^[A-Z0-9/]+$") {
      $textInfo.ToTitleCase($word.ToLower())
    } else {
      $word
    }
  }

  return ($convertedWords -join " ")
}

function ConvertTo-JsStringLiteral {
  param([string]$Value)

  if ($null -eq $Value) {
    return '""'
  }

  $builder = New-Object System.Text.StringBuilder
  [void]$builder.Append('"')

  foreach ($char in $Value.ToCharArray()) {
    $code = [int][char]$char

    if ($char -eq '\') {
      [void]$builder.Append('\\')
    } elseif ($char -eq '"') {
      [void]$builder.Append('\"')
    } elseif ($code -lt 32 -or $code -gt 126) {
      [void]$builder.AppendFormat('\u{0:X4}', $code)
    } else {
      [void]$builder.Append($char)
    }
  }

  [void]$builder.Append('"')
  return $builder.ToString()
}

$fileStream = [System.IO.File]::Open(
  $excelPath,
  [System.IO.FileMode]::Open,
  [System.IO.FileAccess]::Read,
  [System.IO.FileShare]::ReadWrite
)

try {
  $zip = [System.IO.Compression.ZipArchive]::new(
    $fileStream,
    [System.IO.Compression.ZipArchiveMode]::Read,
    $false
  )

  try {
    $sharedStringsEntry = $zip.GetEntry("xl/sharedStrings.xml")
    $sheetEntry = $zip.GetEntry("xl/worksheets/sheet1.xml")

    $reader = [System.IO.StreamReader]::new($sharedStringsEntry.Open())
    try {
      [xml]$sharedStringsXml = $reader.ReadToEnd()
    } finally {
      $reader.Dispose()
    }

    $reader = [System.IO.StreamReader]::new($sheetEntry.Open())
    try {
      [xml]$sheetXml = $reader.ReadToEnd()
    } finally {
      $reader.Dispose()
    }
  } finally {
    $zip.Dispose()
  }
} finally {
  $fileStream.Dispose()
}

$sharedStrings = foreach ($item in $sharedStringsXml.sst.si) {
  if ($item.t) {
    [string]$item.t
  } elseif ($item.r) {
    ($item.r | ForEach-Object {
      if ($_.t -is [string]) {
        $_.t
      } elseif ($_.t.'#text') {
        $_.t.'#text'
      } else {
        [string]$_.t
      }
    }) -join ""
  } else {
    ""
  }
}

$groups = @{}

foreach ($row in ($sheetXml.worksheet.sheetData.row | Select-Object -Skip 1)) {
  $values = @{}

  foreach ($cell in $row.c) {
    $column = $cell.r -replace "\d", ""
    $values[$column] = Get-CellValue -Cell $cell -SharedStrings $sharedStrings
  }

  $code = $values["F"]

  if ([string]::IsNullOrWhiteSpace($code)) {
    continue
  }

  if (-not $groups.ContainsKey($code)) {
    $groups[$code] = [ordered]@{
      guests = New-Object System.Collections.ArrayList
      guestCount = 0
      table = [string]$values["E"]
    }
  }

  [void]$groups[$code].guests.Add((Convert-DisplayName -Name $values["B"]))
  $groups[$code].guestCount = $groups[$code].guests.Count
}

$lines = @("window.GUEST_GROUPS = {")
$sortedGroups = $groups.GetEnumerator() | Sort-Object Name

for ($index = 0; $index -lt $sortedGroups.Count; $index++) {
  $entry = $sortedGroups[$index]
  $guestNames = $entry.Value.guests | ForEach-Object { ConvertTo-JsStringLiteral -Value $_ }
  $tableValue = ConvertTo-JsStringLiteral -Value $entry.Value.table
  $suffix = if ($index -lt ($sortedGroups.Count - 1)) { "," } else { "" }
  $lines += "  $($entry.Key): { guests: [$($guestNames -join ', ')], guestCount: $($entry.Value.guestCount), table: $tableValue }$suffix"
}

$lines += "};"
[System.IO.File]::WriteAllLines($outputPath, $lines)
