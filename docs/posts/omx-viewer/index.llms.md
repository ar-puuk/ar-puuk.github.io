I spent way too long writing one-off Python scripts everytime I had to check what’s inside an OMX (Open Matrix Format) file. There had to be a better way.

So, I built a browser tool to preview OMX files directly. You can: - Browse individual matrices as separate tabs - Navigate to a specific row/col and see that cell’s value across all matrices at once - Run aggregations (sum, mean, median, etc.) across zones or across matrices - Do basic matrix arithmetic and export results

Built on WebAssembly so it’s fast and works without any backend, right on your browser. Tested up to 120 MB, should handle more than that though I’d cap expectations around ~300 MB for most laptops.

Still rough around the edges but functional. If you work with travel demand models and want to try it, the live app is embedded below.

⬡ OMX File Viewer

[↗ Open app](https://ar-puuk.github.io/omx-viewer/ "Open in new tab") [⌥ GitHub](https://github.com/ar-puuk/omx-viewer "View source on GitHub")

⤢ Fullscreen

If you work with travel demand model and want a quick way to preview the contents of an Open Matrix (OMX) file, give it a try. The code is on [GitHub](https://github.com/ar-puuk/omx-viewer) — issues and PRs welcome.

## Citation

BibTeX citation:

``` quarto-appendix-bibtex
@online{bhandari2026,
  author = {Bhandari, Pukar},
  title = {Building a {Client-Side} {Open} {Matrix} {(OMX)} {File}
    {Viewer}},
  date = {2026-04-11},
  url = {https://ar-puuk.github.io/posts/omx-viewer/},
  langid = {en}
}
```

For attribution, please cite this work as:

Bhandari, Pukar. 2026. “Building a Client-Side Open Matrix (OMX) File Viewer.” April 11. <https://ar-puuk.github.io/posts/omx-viewer/>.
