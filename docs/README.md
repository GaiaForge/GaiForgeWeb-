# Orpheus documentation

Editable sources for the customer-facing documents. **Edit the Markdown, never
the generated files** — the HTML pages and PDFs are overwritten on every build.

```
docs/src/*.md          the documents you edit
docs/assets/print.css  how the PDF looks
docs/templates/        the website page shell
docs/build.mjs         the build
```

## Editing and rebuilding

```bash
node docs/build.mjs              # rebuild everything
node docs/build.mjs manual       # rebuild just the manual
node docs/build.mjs quickstart   # rebuild just the quick start
```

Each source produces two outputs:

| Source | Web page | PDF |
|---|---|---|
| `src/orpheus-manual.md` | `html/orpheus-manual.html` | `html/downloads/Orpheus-User-Manual.pdf` |
| `src/orpheus-quickstart.md` | `html/orpheus-quickstart.html` | `html/downloads/Orpheus-Quick-Start-Guide.pdf` |

Commit the `.md` **and** the generated `.html` / `.pdf` together — the site
deploys committed files, so a rebuild that isn't committed never goes live.

Needs `pandoc` and Google Chrome; both are already installed. No npm packages.
Chrome is driven through its DevTools protocol because the plain
`--print-to-pdf` flag cannot produce the "Page N of M" footers.

## Writing conventions

`##` is a numbered section and **starts a new page in the PDF**. `###` is a
subsection. Callout boxes are written as fenced divs, with the label as the
first bold text:

```markdown
::: note
**HOTSPOT TIMEOUT**
The WiFi hotspot switches off after 5 minutes of inactivity.
:::
```

- `::: note` — green, for guidance
- `::: warn` — amber, for anything that loses data, time or legal standing
- `::: checklist` — a list rendered with tick boxes
- `::: contact` — the closing address block

Only the *first* bold run in a callout becomes the label; bold used later in
that paragraph stays inline.

## Where the document set is defined

Adding a document means dropping a `.md` in `src/` and adding an entry to the
`DOCS` array at the top of `build.mjs` (title, cover subtitle, output paths).

## Keeping the portal in sync

The four built-in Orpheus document cards in the portal are defined in **three
places that must agree**:

1. `server/orpheus_firmware_api.py` → `DEFAULT_DOCS` (seeds the live manifest)
2. `src/docs/productDocs.js` → `PRODUCT_DOC_DEFAULTS` (frontend fallback)
3. `html/orpheus.html` → the Documentation download cards

Changing a document's **filename** means updating all three, rebuilding the
portal (`npm run build`), and refreshing the already-seeded live manifest at
`/var/www/html/downloads/orpheus/docs/manifest.json` on the VPS — startup
seeding only writes a manifest that is *missing*, so it will not correct an
existing one.

## Not yet migrated

`html/docs/solar-panel-guide.md` is the old source for the Solar Panel Guide
PDF and is not part of this pipeline yet. Moving it to `docs/src/` and adding a
`DOCS` entry would bring the last document in line.
