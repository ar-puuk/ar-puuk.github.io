// Fullscreen toggle for every .app-embed-wrapper on the page. The toolbar stays
// visible in fullscreen; ESC also exits (when focus is outside the iframe).
const setFullscreen = (wrapper, on) => {
  wrapper.classList.toggle("fullscreen", on);
  wrapper.querySelector(".app-fullscreen-btn").textContent = on
    ? "Exit fullscreen"
    : "Fullscreen";
  document.body.style.overflow = on ? "hidden" : "";
};
document.addEventListener("click", (e) => {
  const btn = e.target.closest(".app-fullscreen-btn");
  if (!btn) return;
  const wrapper = btn.closest(".app-embed-wrapper");
  setFullscreen(wrapper, !wrapper.classList.contains("fullscreen"));
});
document.addEventListener("keydown", (e) => {
  if (e.key !== "Escape") return;
  const wrapper = document.querySelector(".app-embed-wrapper.fullscreen");
  if (wrapper) setFullscreen(wrapper, false);
});
