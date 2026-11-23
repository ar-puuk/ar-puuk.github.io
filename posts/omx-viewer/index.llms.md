I spent way too long writing one-off Python scripts every time I had to check what’s inside an OMX (Open Matrix Format) file. There had to be a better way.

So I built a browser tool to preview OMX files directly: drop a file on the page and you can scroll through every matrix in it, look up any cell, summarize rows and columns, and do simple arithmetic between matrices, with nothing installed and nothing uploaded. This post covers why I wanted it, what it does, and the handful of problems that made “just show the numbers” harder than it sounds.

> **NOTE:**
>
> The same engine now powers an **OMX Viewer extension for VS Code**, so `.omx`, `.h5` and `.hdf5` files open in the viewer straight from the editor, with an *Export Summary as CSV* command. Install it from the [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=arpuuk.omx-viewer) or [Open VSX](https://open-vsx.org/extension/arpuuk/omx-viewer). The web app and the extension are versioned together, and the extension streams large files to its webview in 32 MB chunks, which lifts the practical size limit well into multi-gigabyte territory.

If you work with travel demand models and want to try it, the live app is embedded below.

OMX File Viewer

Fullscreen

[ Open app](https://ar-puuk.github.io/omx-viewer/) [ GitHub](https://github.com/ar-puuk/omx-viewer)

## 1 What’s in an OMX file, and why it’s awkward to peek at

Travel demand models move a lot of zone-to-zone data around: trip tables by purpose and mode, travel time and cost skims, and so on. OMX is the common exchange format for these. It is a convention on top of HDF5: one file holds several named square matrices, all with the same zone dimensions, plus optional lookup tables of zone labels.

``` text
file.omx (HDF5)
├── /data/
│   ├── TAZ_AUTO      (float32 or float64, N × N)
│   ├── TAZ_TRANSIT
│   └── ...
├── /lookup/
│   └── zone_labels   (length N)
└── root attributes: OMX_VERSION, SHAPE
```

HDF5 is a binary format, so you can’t just open it in a text editor or a spreadsheet. The usual answer is a few lines of Python with `openmatrix` or `h5py`, which is fine once, and tedious the twentieth time you want to know “what matrices are in this skim file, and does zone 1,204 to 87 look sensible?” I wanted something closer to a file preview: open, look, close.

## 2 A quick tour

- **Matrix tabs**: every matrix in the file gets its own tab.
- **A scrollable grid** of the whole matrix, with zone labels in the headers when the file has them. Only the rows and columns on screen are ever rendered, so a 3,629 × 3,629 skim scrolls like a small table.
- **Go to cell**: type a row and column (by the zone IDs shown in the headers) and the grid scrolls to centre that cell.
- **Cross-matrix inspector**: click a cell to pin it, and a side panel shows that same origin-destination pair in every matrix in the file at once. Because all matrices in an OMX file share the same zones, this is a quick way to compare, say, auto and transit times for one pair.
- **Summaries**: sum, min, max, mean, median, standard deviation or count of non-zero values, by row or by column, for the active matrix or for all matrices side by side, downloadable as CSV.
- **Arithmetic**: add, subtract, multiply or divide two matrices element by element; the result opens as a temporary tab.
- **Number formatting** with a choice of decimal places and compact notation (1.2M), and a light or dark theme.

## 3 How it works

It is a static site (Svelte 5, TypeScript and Vite) hosted on GitHub Pages, with no backend. The HDF5 parsing is done by [h5wasm](https://github.com/usnistgov/h5wasm), which compiles the HDF5 C library to WebAssembly. When you drop a file, its bytes are written into h5wasm’s in-memory file system and opened as an HDF5 file; from then on the app reads slices of datasets rather than whole matrices.

Three pieces do most of the work:

- **Chunked reads with a cache.** The grid asks for blocks of rows (200 by default, aligned to the dataset’s own HDF5 chunk shape when it has one) through h5wasm’s `slice()`. Each tab keeps a small least-recently-used cache of these blocks, so scrolling back and forth doesn’t re-read the file.
- **A two-way virtualized grid.** [TanStack Virtual](https://tanstack.com/virtual) virtualizes rows and columns independently, so only about 30 rows and 20 columns exist in the page at any moment, whatever the matrix size.
- **A worker for arithmetic.** Element-wise operations run in a plain Web Worker. The two input matrices are handed over as transferable `Float64Array` buffers, so they move between threads without being copied.

h5wasm itself stays on the main thread. That sounds backwards, but every scroll event needs a slice, and sending each request to a worker and back would add serialization cost on exactly the path that has to feel instant.

## 4 The interesting problems

### “No matrices found”

In the first deployed version, opening a real file failed with “No matrices found.” The parser was looking for matrices under `/matrices/` with lowercase attributes, as the original OMX specification describes. Real-world files put them under `/data/` with uppercase `SHAPE` and `OMX_VERSION`. The parser now looks the group up case-insensitively, accepts either name, and falls back to reading the shape from the first matrix if the `SHAPE` attribute is missing.

### A grid that took two minutes to fill

My test file was a skim with 23 matrices of 3,629 × 3,629 float32 values, about 1.2 GB. The grid’s skeleton appeared immediately, but the numbers took one to two minutes to show up. There turned out to be two separate bugs, both about Svelte 5’s reactivity rather than about HDF5:

1.  The function that schedules a row fetch (with a 50 ms debounce) was being called from inside the template, so every re-render reset the timer and the fetch kept getting postponed. It now runs from a plain `onscroll` handler that computes the visible rows from `scrollTop` directly.
2.  Fetched blocks were stored in a `Map`, and Svelte 5 does not track `Map.set()`. The data was there, but nothing told the grid to redraw. A version counter that increments on every cache insert, and that the cell lookup reads, fixed it.

A third bug was hiding behind those: when the visible rows spanned two blocks (rows 180 to 210, say), only the first block was requested. After those fixes, values appear as soon as the grid does.

### Summaries without running out of memory

The first version of the summary panel used DuckDB-WASM: register each matrix as a table, then run SQL aggregates. On the test file it failed with an out-of-memory error. DuckDB-WASM had a memory limit of about 512 MB, a single 3,629-column matrix took about 105 MB as a table, and “all matrices” meant 23 of them.

The replacement is much simpler. Aggregation streams through the matrix one 200-row block at a time (200 × 3,629 × 4 bytes is about 2.9 MB) and accumulates per-row or per-column results in a plain loop, one matrix at a time, yielding to the event loop between blocks so the page stays responsive. Peak memory is one block plus the results. Median by column is the expensive case, since it has to sort a full column. DuckDB is no longer used anywhere in the app, and it was removed when the code was restructured for the VS Code extension.

### Go to cell, off by a column

Centering the grid on a cell sounds trivial, and took several commits. Cells were positioned as flex items *and* shifted with a CSS transform, so each column’s offset was applied twice and the effective column width doubled. Separately, the horizontal and vertical scrolls were two calls that raced each other. Absolute positioning and a single `scrollTo({ top, left })` fixed both. Later, the navigator was changed to accept the zone IDs shown in the headers instead of raw zero-based indexes, which had been landing one row or column off.

### Bringing it to VS Code

In July I restructured the repository into a shared engine with two apps on top: the web app and a VS Code extension. The parsing, aggregation, worker and the whole viewer UI are host-independent, since a VS Code webview is just a Chromium page. What differs is how the file arrives, how theme colours are resolved, and how worker scripts are located.

Getting the file into the webview had its own surprises. VS Code’s webview messaging turned out not to preserve typed arrays, so the extension sends base64 instead. For files above roughly 400 MB, a single base64 string exceeded V8’s maximum string length and failed before the webview received a byte; the extension now sends the file in 32 MB pieces that the webview reassembles into one preallocated buffer.

A smaller fix from the same release is worth mentioning: zone labels and matrix names come from the file, so they are now sanitized before going into exported CSVs, to stop a crafted file from injecting a spreadsheet formula.

## 5 Limits

The web app reads the whole file into the browser’s memory before opening it, so the README recommends files up to about 700 MB and warns above 750 MB. Arithmetic needs both matrices in memory, roughly twice the matrix size. Streaming summaries on a 10,000 × 10,000 matrix take seconds rather than milliseconds. The app needs cross-origin isolation for WebAssembly, which GitHub Pages can’t configure with headers, so a small service worker (`coi-serviceworker`) adds them in the browser.

## 6 What’s next

The [plan](https://github.com/ar-puuk/omx-viewer/blob/main/docs/plan.md) for a second stage is geospatial: load a zone geometry file alongside the matrix, join it by zone ID, and show a row or column as a choropleth, or the largest flows as desire lines on a map. None of that is built yet.

The first working version was generated with Claude, and much of the later work was done the same way; the commit history and the design notes in the repository record what broke and why. If you work with travel demand models and want a quick way to preview the contents of an Open Matrix (OMX) file, give it a try. The code is on [GitHub](https://github.com/ar-puuk/omx-viewer), and issues and PRs are welcome.

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
