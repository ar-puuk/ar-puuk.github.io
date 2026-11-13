// Behaviour for every .app-embed-wrapper on the page:
// - shows the embedded app's address in the bar (it also opens the app in a new tab)
// - fullscreen toggle; the bar stays visible in fullscreen, and ESC also exits
//   (when focus is outside the iframe)

document.querySelectorAll(".app-embed-wrapper").forEach((wrapper) => {
  const iframe = wrapper.querySelector("iframe");
  const bar = wrapper.querySelector(".app-embed-toolbar");
  const src = iframe && iframe.getAttribute("src");
  if (!bar || !src) return;
  try {
    const url = new URL(src, location.href);
    const link = document.createElement("a");
    link.className = "app-embed-url";
    link.href = url.href;
    link.target = "_blank";
    link.rel = "noopener";
    link.title = "Open " + url.href;
    link.textContent = url.host + url.pathname.replace(/\/$/, "");
    bar.insertBefore(link, bar.querySelector(".app-fullscreen-btn"));
  } catch (_) {
    // an unparseable src just means no address pill
  }
});

const setFullscreen = (wrapper, on) => {
  const btn = wrapper.querySelector(".app-fullscreen-btn");
  wrapper.classList.toggle("fullscreen", on);
  btn.textContent = on ? "Exit fullscreen" : "Fullscreen";
  btn.setAttribute("aria-pressed", String(on));
  document.body.style.overflow = on ? "hidden" : "";
  return btn;
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
  // put focus back on the button so keyboard users land where they started
  if (wrapper) setFullscreen(wrapper, false).focus();
});
