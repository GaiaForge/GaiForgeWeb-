import React, { useEffect, useState } from 'react';
import { fetchProductDocs, docIcon } from '../docs/productDocs';

// Public document library for a product. Renders the manifest-driven doc list
// as a grid of cards. Used by each product dashboard.
function ProductDocs({ product, title = 'Documentation', emptyText = 'No documents available yet.' }) {
  const [docs, setDocs] = useState(null);

  useEffect(() => {
    let alive = true;
    fetchProductDocs(product).then((d) => { if (alive) setDocs(d); });
    return () => { alive = false; };
  }, [product]);

  return (
    <div className="actions-section">
      <h2>{title}</h2>
      {docs === null ? (
        <p>Loading…</p>
      ) : docs.length === 0 ? (
        <p>{emptyText}</p>
      ) : (
        <div className="actions-grid">
          {docs.map((doc) => (
            <a
              key={doc.id}
              href={doc.url}
              className="action-card"
              target="_blank"
              rel="noreferrer"
            >
              <div className="action-icon">{docIcon(doc)}</div>
              <h3>{doc.title}</h3>
              <p>{doc.description}</p>
              <span className="upload-meta" style={{ marginTop: '10px', display: 'block' }}>
                {doc.type === 'pdf' ? 'PDF Download' : 'View Online'}
              </span>
            </a>
          ))}
        </div>
      )}
    </div>
  );
}

export default ProductDocs;
