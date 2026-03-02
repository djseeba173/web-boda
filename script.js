// REVEAL ON SCROLL
const reveals = document.querySelectorAll(".reveal");

if ("IntersectionObserver" in window) {
  const revealObserver = new IntersectionObserver((entries, observer) => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) {
        return;
      }

      entry.target.classList.add("active");
      observer.unobserve(entry.target);
    });
  }, {
    rootMargin: "0px 0px -100px 0px"
  });

  reveals.forEach(element => {
    revealObserver.observe(element);
  });
} else {
  reveals.forEach(element => {
    element.classList.add("active");
  });
}

// COUNTDOWN
const weddingDate = new Date("2026-09-27T00:00:00").getTime();

const updateCountdown = () => {
  const now = new Date().getTime();
  const diff = weddingDate - now;

  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diff / (1000 * 60 * 60)) % 24);
  const minutes = Math.floor((diff / (1000 * 60)) % 60);
  const seconds = Math.floor((diff / 1000) % 60);

  document.getElementById("days").textContent = days;
  document.getElementById("hours").textContent = hours;
  document.getElementById("minutes").textContent = minutes;
  document.getElementById("seconds").textContent = seconds;
};

setInterval(updateCountdown, 1000);
updateCountdown();

// FLASHCARDS MOBILE TAP
document.querySelectorAll(".flashcard").forEach(card => {
  card.addEventListener("click", () => {
    card.querySelector(".flashcard-inner").classList.toggle("rotate");
  });
});

// BANK MODAL
const bankModal = document.getElementById("bankModal");
const openBankModalButton = document.getElementById("openBankModal");
const closeBankModalButton = document.getElementById("closeBankModal");

if (bankModal && openBankModalButton && closeBankModalButton) {
  const closeBankModal = () => {
    bankModal.classList.remove("is-open");
    bankModal.setAttribute("aria-hidden", "true");
  };

  const openBankModal = () => {
    bankModal.classList.add("is-open");
    bankModal.setAttribute("aria-hidden", "false");
  };

  openBankModalButton.addEventListener("click", openBankModal);
  closeBankModalButton.addEventListener("click", closeBankModal);

  bankModal.querySelectorAll("[data-close-bank-modal]").forEach(element => {
    element.addEventListener("click", closeBankModal);
  });

  document.addEventListener("keydown", event => {
    if (event.key === "Escape" && bankModal.classList.contains("is-open")) {
      closeBankModal();
    }
  });
}
