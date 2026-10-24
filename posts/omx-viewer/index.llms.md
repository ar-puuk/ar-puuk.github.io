I spent way too long writing one-off Python scripts everytime I had to check what’s inside an OMX (Open Matrix Format) file. There had to be a better way.

So, I built a browser tool to preview OMX files directly. You can: - Browse individual matrices as separate tabs - Navigate to a specific row/col and see that cell’s value across all matrices at once - Run aggregations (sum, mean, median, etc.) across zones or across matrices - Do basic matrix arithmetic and export results

Built on WebAssembly so it’s fast and works without any backend, right on your browser. Files in the 300 to 700 MB range are supported; the matrix grid only renders the rows and columns on screen and reads chunks on demand, so it never loads a whole matrix into memory.

> **TIP:**
>
> The same engine now powers an **OMX Viewer extension for VS Code**, so `.omx`, `.h5` and `.hdf5` files open in the viewer straight from the editor, with an *Export Summary as CSV* command. Install it from the [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=arpuuk.omx-viewer) or [Open VSX](https://open-vsx.org/extension/arpuuk/omx-viewer). The web app and the extension are versioned together, and the extension streams large files to its webview in 32 MB chunks, which lifts the practical size limit well into multi-gigabyte territory.

If you work with travel demand models and want to try it, the live app is embedded below.

OMX File Viewer

Fullscreen

[ Open app](https://ar-puuk.github.io/omx-viewer/) [ GitHub](https://github.com/ar-puuk/omx-viewer)

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
  langid = {en-US}
}
```

For attribution, please cite this work as:

Bhandari, Pukar. 2026. “Building a Client-Side Open Matrix (OMX) File Viewer.” April 11. <https://ar-puuk.github.io/posts/omx-viewer/>.
