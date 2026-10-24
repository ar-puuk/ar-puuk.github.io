// Fullscreen toggle for every .app-embed-wrapper on the page (ESC exits).
document.addEventListener("click", (e) => {
  const btn = e.target.closest(".app-fullscreen-btn");
  if (!btn) return;
  const frame = btn
    .closest(".app-embed-wrapper")
    .querySelector(".app-embed-frame");
  const on = frame.classList.toggle("fullscreen");
  btn.textContent = on ? "Exit fullscreen" : "Fullscreen";
  document.body.style.overflow = on ? "hidden" : "";
});
document.addEventListener("keydown", (e) => {
  if (e.key !== "Escape") return;
  const frame = document.querySelector(".app-embed-frame.fullscreen");
  if (frame) frame.closest(".app-embed-wrapper").querySelector(".app-fullscreen-btn").click();
});
