// Behaviour for every .app-embed-wrapper on the page:
// - shows the embedded app's address in the bar
// - moves the page's "Open app" / "GitHub" buttons (the .app-links block that follows the
//   embed) into the bar, next to the fullscreen toggle. Without JS they simply stay below.
// - fullscreen toggle; the bar stays visible in fullscreen, and ESC also exits
//   (when focus is outside the iframe)

// The .app-links block for an embed: the next sibling of the embed, or of the layout div
// (e.g. .column-screen-inset) the embed is wrapped in.
const linksFor = (wrapper) => {
  let next = wrapper.nextElementSibling;
  if (!next && wrapper.parentElement && !wrapper.parentElement.matches("main, #quarto-content, .content, section")) {
    next = wrapper.parentElement.nextElementSibling;
  }
  return next && next.classList.contains("app-links") ? next : null;
};

document.querySelectorAll(".app-embed-wrapper").forEach((wrapper) => {
  const iframe = wrapper.querySelector("iframe");
  const bar = wrapper.querySelector(".app-embed-toolbar");
  const fs = wrapper.querySelector(".app-fullscreen-btn");
  const src = iframe && iframe.getAttribute("src");
  if (!bar || !fs) return;

  // The fullscreen label becomes a span, so phones can show just the icon
  fs.innerHTML = '<span class="app-action-label">Fullscreen</span>';

  if (src) {
    try {
      const url = new URL(src, location.href);
      const addr = document.createElement("span");
      addr.className = "app-embed-url";
      addr.title = url.href;
      addr.textContent = url.host + url.pathname.replace(/\/$/, "");
      bar.insertBefore(addr, fs);
    } catch (_) {
      // an unparseable src just means no address pill
    }
  }

  const group = document.createElement("div");
  group.className = "app-embed-actions";
  const links = linksFor(wrapper);
  if (links) {
    links.querySelectorAll("a").forEach((a) => {
      const action = document.createElement("a");
      action.className = "app-embed-action" + (a.classList.contains("btn-primary") ? " is-primary" : "");
      action.href = a.href;
      action.target = "_blank";
      action.rel = "noopener";
      const label = a.textContent.trim();
      action.title = label;
      const icon = a.querySelector("i");
      if (icon) {
        const i = icon.cloneNode(true);
        i.setAttribute("aria-hidden", "true");
        i.removeAttribute("aria-label");
        action.appendChild(i);
      }
      const span = document.createElement("span");
      span.className = "app-action-label";
      span.textContent = label;
      action.appendChild(span);
      group.appendChild(action);
    });
    links.remove();
  }
  group.appendChild(fs);
  bar.appendChild(group);
});

const setFullscreen = (wrapper, on) => {
  const btn = wrapper.querySelector(".app-fullscreen-btn");
  wrapper.classList.toggle("fullscreen", on);
  btn.querySelector(".app-action-label").textContent = on ? "Exit fullscreen" : "Fullscreen";
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
