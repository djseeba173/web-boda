const guestCodeInput = document.getElementById("guestCode");
const errorMsg = document.getElementById("errorMsg");
const stepInput = document.getElementById("step-input");
const stepWelcome = document.getElementById("step-welcome");
const welcomeTitle = document.getElementById("welcomeTitle");
const guestCount = document.getElementById("guestCount");

function formatGuestList(guests) {
  if (!Array.isArray(guests) || guests.length === 0) {
    return "";
  }

  if (guests.length === 1) {
    return guests[0];
  }

  if (guests.length === 2) {
    return guests.join(" y ");
  }

  return guests.slice(0, -1).join(", ") + " y " + guests[guests.length - 1];
}

function hideError() {
  errorMsg.style.display = "none";
  guestCodeInput.style.borderColor = "var(--gold)";
}

function verifyGuestCode() {
  const code = guestCodeInput.value.trim().toUpperCase();
  const guestGroup = window.GUEST_GROUPS[code];

  if (!guestGroup) {
    errorMsg.style.display = "block";
    guestCodeInput.style.borderColor = "var(--bordo)";
    return;
  }

  hideError();
  stepInput.style.display = "none";
  stepWelcome.style.display = "block";
  welcomeTitle.textContent = formatGuestList(guestGroup.guests);
  guestCount.textContent = guestGroup.guestCount;
}

guestCodeInput.addEventListener("input", hideError);
guestCodeInput.addEventListener("keydown", event => {
  if (event.key === "Enter") {
    verifyGuestCode();
  }
});

window.verificarCodigo = verifyGuestCode;
