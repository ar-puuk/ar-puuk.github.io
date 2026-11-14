// Quarto Live puts "Show Solution" in a separate bar above the editor when an exercise sits inside
// a tabset (R / Python tabs). Move it into the editor's own header, next to "Start Over", which is
// where the extension puts it for exercises outside a tabset. The button keeps its click handler.
(function () {
  function relocate() {
    document
      .querySelectorAll(".exercise-tab-pane-header .btn-exercise-solution")
      .forEach(function (btn) {
        var pane = btn.closest(".tab-pane");
        if (!pane) return;
        var group = pane.querySelector(
          ".exercise-editor-header .btn-group-exercise-editor"
        );
        if (group && !group.contains(btn)) {
          var bar = btn.closest(".exercise-tab-pane-header");
          group.appendChild(btn);
          // the now-empty bar would otherwise leave a gap above the editor
          if (bar && !bar.querySelector("a, button")) bar.style.display = "none";
        }
      });
  }

  var queued = false;
  function schedule() {
    if (queued) return;
    queued = true;
    requestAnimationFrame(function () {
      queued = false;
      relocate();
    });
  }

  new MutationObserver(schedule).observe(document.documentElement, {
    childList: true,
    subtree: true,
  });
  document.addEventListener("DOMContentLoaded", schedule);
})();
