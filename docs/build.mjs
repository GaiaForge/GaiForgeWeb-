#!/usr/bin/env node
/**
 * GaiaForge documentation build.
 *
 * One Markdown file per document in docs/src/ produces two outputs:
 *   1. a branded PDF in html/downloads/   (what customers download)
 *   2. a page on the website in html/     (what customers read in a browser)
 *
 * Usage:
 *   node docs/build.mjs            build every document
 *   node docs/build.mjs manual     build just the ones whose key matches
 *
 * Requirements: pandoc and Google Chrome. No npm packages.
 * Chrome is driven through its DevTools protocol so the PDF gets proper
 * "Page N of M" footers, which the plain --print-to-pdf flag cannot do.
 */

import { spawn, execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

/* --------------------------------------------------------------------------
 * The document set. Add a new document by dropping a .md in docs/src/ and
 * adding an entry here.
 * ----------------------------------------------------------------------- */
const DOCS = [
  {
    key: 'manual',
    src: 'docs/src/orpheus-manual.md',
    pdf: 'html/downloads/Orpheus-User-Manual.pdf',
    page: 'html/orpheus-manual.html',
    productLine: 'Orpheus',
    title: 'User Manual',
    subtitle:
      'Setup, playback modes, the companion app, power management and field ' +
      'deployment for Orpheus Basic and Orpheus Pro.',
    badge: 'Version 1.8 · Orpheus Basic & Pro',
    pageTitle: 'Orpheus User Manual | GaiaForge',
    pageSubtitle: 'User Manual — Version 1.8 — 2026',
  },
  {
    key: 'quickstart',
    src: 'docs/src/orpheus-quickstart.md',
    pdf: 'html/downloads/Orpheus-Quick-Start-Guide.pdf',
    page: 'html/orpheus-quickstart.html',
    productLine: 'Orpheus',
    title: 'Quick Start Guide',
    subtitle:
      'From unboxing to your first scheduled playback, for Orpheus Basic and ' +
      'Orpheus Pro.',
    badge: 'Version 1.8 · Orpheus Basic & Pro',
    pageTitle: 'Orpheus Quick Start Guide | GaiaForge',
    pageSubtitle: 'Quick Start Guide — Version 1.8 — 2026',
  },
];

/* --------------------------------------------------------------------------
 * Markdown -> HTML fragment
 * ----------------------------------------------------------------------- */
function renderFragment(srcPath) {
  return execFileSync(
    'pandoc',
    [
      srcPath,
      '--from=markdown+fenced_divs+pipe_tables+backtick_code_blocks',
      '--to=html5',
      '--wrap=none',
    ],
    { encoding: 'utf8', maxBuffer: 32 * 1024 * 1024 }
  );
}

/* Build a Contents list from the section headings pandoc emitted. */
function tableOfContents(fragment) {
  const items = [...fragment.matchAll(/<h2 id="([^"]+)"[^>]*>(.*?)<\/h2>/g)].map(
    ([, id, label]) => `        <li><a href="#${id}">${label.replace(/^\d+\.\s*/, '')}</a></li>`
  );
  return items.length
    ? `    <div class="toc">\n      <h3>Contents</h3>\n      <ol>\n${items.join('\n')}\n      </ol>\n    </div>`
    : '';
}

/* --------------------------------------------------------------------------
 * Print document (for the PDF)
 * ----------------------------------------------------------------------- */
function printHtml(doc, fragment) {
  const css = readFileSync(join(ROOT, 'docs/assets/print.css'), 'utf8');
  const logo = join(ROOT, 'html/images/gaiaforge-logo.png');
  // Keep the first section on the page after the Contents rather than
  // pushing a blank one, since every other <h2> forces a page break.
  const body = fragment.replace('<h2', '<h2 class="first"');

  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<title>${doc.productLine} ${doc.title}</title>
<style>${css}</style>
</head><body>
<div class="cover">
  <img src="file://${logo}" alt="">
  <p class="brand">GaiaForge</p>
  <p class="product">${doc.productLine}</p>
  <p class="doc-title">${doc.title}</p>
  <p class="doc-sub">${doc.subtitle}</p>
  <p class="badge">${doc.badge}</p>
</div>
${tableOfContents(fragment)}
${body}
</body></html>`;
}

/* --------------------------------------------------------------------------
 * Website page — reuses the existing site shell so the page keeps the site
 * header, footer and styling.
 * ----------------------------------------------------------------------- */
function sitePage(doc, fragment) {
  const shell = readFileSync(join(ROOT, 'docs/templates/page.html'), 'utf8');
  return shell
    .replace(/\{\{PAGE_TITLE\}\}/g, doc.pageTitle)
    .replace(/\{\{DOC_TITLE\}\}/g, `${doc.productLine} ${doc.title}`)
    .replace(/\{\{DOC_SUBTITLE\}\}/g, doc.pageSubtitle)
    .replace(/\{\{PDF_HREF\}\}/g, '/' + doc.pdf.replace(/^html\//, ''))
    .replace(/\{\{TOC\}\}/g, tableOfContents(fragment))
    .replace(/\{\{CONTENT\}\}/g, fragment);
}

/* --------------------------------------------------------------------------
 * Chrome DevTools Protocol driver (Node's built-in WebSocket, no deps)
 * ----------------------------------------------------------------------- */
class Chrome {
  static async launch() {
    const proc = spawn(CHROME, [
      '--headless=new',
      '--disable-gpu',
      '--no-first-run',
      '--no-default-browser-check',
      '--remote-debugging-port=0',
    ]);

    const wsUrl = await new Promise((ok, fail) => {
      let buf = '';
      const timer = setTimeout(
        () => fail(new Error('Chrome did not report a debugging port')),
        20000
      );
      proc.stderr.on('data', (d) => {
        buf += d;
        const m = buf.match(/DevTools listening on (ws:\/\/\S+)/);
        if (m) {
          clearTimeout(timer);
          ok(m[1]);
        }
      });
      proc.on('exit', (c) => fail(new Error(`Chrome exited early (${c})`)));
    });

    const chrome = new Chrome();
    chrome.proc = proc;
    chrome.ws = new WebSocket(wsUrl);
    chrome.id = 0;
    chrome.pending = new Map();
    chrome.waiters = [];

    await new Promise((ok, fail) => {
      chrome.ws.onopen = ok;
      chrome.ws.onerror = () => fail(new Error('CDP socket failed'));
    });

    chrome.ws.onmessage = (ev) => {
      const msg = JSON.parse(ev.data);
      if (msg.id && chrome.pending.has(msg.id)) {
        const { ok, fail } = chrome.pending.get(msg.id);
        chrome.pending.delete(msg.id);
        msg.error ? fail(new Error(msg.error.message)) : ok(msg.result);
      } else if (msg.method) {
        chrome.waiters = chrome.waiters.filter((w) => {
          if (w.method === msg.method && w.session === msg.sessionId) {
            w.ok(msg.params);
            return false;
          }
          return true;
        });
      }
    };

    return chrome;
  }

  send(method, params = {}, sessionId) {
    const id = ++this.id;
    return new Promise((ok, fail) => {
      this.pending.set(id, { ok, fail });
      this.ws.send(JSON.stringify({ id, method, params, sessionId }));
    });
  }

  once(method, session) {
    return new Promise((ok) => this.waiters.push({ method, session, ok }));
  }

  /** Render a local HTML file to PDF bytes. */
  async pdf(fileUrl, footerLabel) {
    const { targetId } = await this.send('Target.createTarget', {
      url: 'about:blank',
    });
    const { sessionId } = await this.send('Target.attachToTarget', {
      targetId,
      flatten: true,
    });

    await this.send('Page.enable', {}, sessionId);
    const loaded = this.once('Page.loadEventFired', sessionId);
    await this.send('Page.navigate', { url: fileUrl }, sessionId);
    await loaded;
    // Let webfonts and image decoding settle before painting.
    await this.send(
      'Runtime.evaluate',
      { expression: 'document.fonts.ready.then(() => true)', awaitPromise: true },
      sessionId
    );

    const footer =
      `<div style="font-size:7pt;color:#8a8a8a;width:100%;margin:0 16mm;` +
      `display:flex;justify-content:space-between;">` +
      `<span>GaiaForge · ${footerLabel}</span>` +
      `<span>Page <span class="pageNumber"></span> of ` +
      `<span class="totalPages"></span></span></div>`;

    const { data } = await this.send(
      'Page.printToPDF',
      {
        paperWidth: 8.27, // A4
        paperHeight: 11.69,
        marginTop: 0.7,
        marginBottom: 0.8,
        marginLeft: 0.63,
        marginRight: 0.63,
        printBackground: true,
        displayHeaderFooter: true,
        headerTemplate: '<div></div>',
        footerTemplate: footer,
      },
      sessionId
    );

    await this.send('Target.closeTarget', { targetId });
    return Buffer.from(data, 'base64');
  }

  close() {
    try { this.ws.close(); } catch {}
    this.proc.kill();
  }
}

/* --------------------------------------------------------------------------
 * Main
 * ----------------------------------------------------------------------- */
const filter = process.argv[2];
const targets = filter ? DOCS.filter((d) => d.key.includes(filter)) : DOCS;

if (!targets.length) {
  console.error(`No document matches "${filter}". Known: ${DOCS.map((d) => d.key).join(', ')}`);
  process.exit(1);
}

const tmp = mkdtempSync(join(tmpdir(), 'gf-docs-'));
const chrome = await Chrome.launch();

try {
  for (const doc of targets) {
    const fragment = renderFragment(join(ROOT, doc.src));

    // 1. website page
    writeFileSync(join(ROOT, doc.page), sitePage(doc, fragment));

    // 2. PDF
    const scratch = join(tmp, `${doc.key}.html`);
    writeFileSync(scratch, printHtml(doc, fragment));
    const bytes = await chrome.pdf(
      `file://${scratch}`,
      `${doc.productLine} ${doc.title}`
    );
    writeFileSync(join(ROOT, doc.pdf), bytes);

    const kb = (bytes.length / 1024).toFixed(0);
    console.log(`  ${doc.key.padEnd(11)} -> ${doc.page}`);
    console.log(`  ${''.padEnd(11)}    ${doc.pdf} (${kb} KB)`);
  }
  console.log('\nDone. Commit the .md sources and the generated .html/.pdf together.');
} finally {
  chrome.close();
  rmSync(tmp, { recursive: true, force: true });
}
