// Shared document-library helpers used by the product dashboards and the
// Admin document manager.
//
// Documents are served from a per-product manifest at
//   /downloads/<product>/docs/manifest.json
// which the backend seeds and the admin manager edits. If that manifest can't
// be reached (e.g. the new backend hasn't been deployed yet), we fall back to
// the built-in defaults below so the product pages still show their core docs.

const API_BASE = typeof window !== 'undefined' ? window.location.origin : '';

export const PRODUCTS = ['orpheus', 'hiveguard', 'sprigrig'];

export const PRODUCT_LABELS = {
  orpheus: 'Orpheus',
  hiveguard: 'HiveGuard',
  sprigrig: 'SprigRig',
};

// Must mirror DEFAULT_DOCS in server/orpheus_firmware_api.py. Used only as a
// fallback when the manifest is unavailable.
export const PRODUCT_DOC_DEFAULTS = {
  orpheus: [
    { id: 'builtin-manual', title: 'Orpheus User Manual', icon: '📖',
      description: 'Complete guide covering setup, operation, and maintenance.',
      url: '/orpheus-manual.html', type: 'html', builtin: true },
    { id: 'builtin-quickstart', title: 'Quick Start Guide', icon: '🚀',
      description: 'Get your Orpheus device up and running quickly.',
      url: '/downloads/Orpheus-Basic-Quick-Start-Guide.pdf', type: 'pdf', builtin: true },
    { id: 'builtin-solar', title: 'Solar Panel Alignment Guide', icon: '☀️',
      description: 'Optimize solar panel positioning for your deployment site.',
      url: '/downloads/Orpheus-Solar-Panel-Guide.pdf', type: 'pdf', builtin: true },
    { id: 'builtin-recording', title: 'Pro Recording & Field Guide', icon: '🎙️',
      description: 'Recording modes, mic sensitivity, and placement — getting the best from Orpheus Pro.',
      url: '/downloads/Orpheus-Pro-Recording-Field-Guide.pdf', type: 'pdf', builtin: true },
  ],
  hiveguard: [],
  sprigrig: [],
};

export function docIcon(doc) {
  if (doc.icon) return doc.icon;
  return doc.type === 'html' ? '🌐' : '📄';
}

// Fetch a product's document list. Returns the manifest's `documents` array,
// or the built-in defaults if the manifest is missing/unreadable.
export async function fetchProductDocs(product) {
  try {
    const res = await fetch(
      `${API_BASE}/downloads/${product}/docs/manifest.json?t=${Date.now()}`
    );
    if (res.ok) {
      const data = await res.json();
      if (data && Array.isArray(data.documents)) return data.documents;
    }
  } catch {
    // fall through to defaults
  }
  return PRODUCT_DOC_DEFAULTS[product] || [];
}
