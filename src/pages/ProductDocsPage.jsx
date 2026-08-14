import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import ProductDocs from '../components/ProductDocs';
import { PRODUCT_LABELS } from '../docs/productDocs';

// Standalone documentation page for products whose dashboards aren't tab-based
// (HiveGuard, SprigRig). Orpheus renders ProductDocs inside its own tab instead.
function ProductDocsPage({ user, onLogout, product, backTo = '/products' }) {
  const navigate = useNavigate();
  const label = PRODUCT_LABELS[product] || 'Product';

  const handleLogout = () => {
    onLogout();
    navigate('/login');
  };

  return (
    <div className="dashboard-container">
      <aside className="sidebar">
        <div className="sidebar-header">
          <a href="/"><img src="/gaiaforge-logo.png" alt="GaiaForge" className="logo-image" /></a>
        </div>
        <nav className="sidebar-nav">
          <Link to={backTo} className="nav-item back-link">
            <span className="nav-icon">←</span> Back to {label}
          </Link>
          <Link to="/profile" className="nav-item">
            <span className="nav-icon">👤</span> Profile
          </Link>
          {user?.is_admin && (
            <Link to="/admin" className="nav-item">
              <span className="nav-icon">⚙️</span> Admin
            </Link>
          )}
        </nav>
        <div className="sidebar-footer">
          <button onClick={handleLogout} className="logout-btn">
            <span className="nav-icon">🚪</span> Logout
          </button>
        </div>
      </aside>

      <main className="main-content">
        <header className="content-header">
          <div>
            <h1>{label} Documentation</h1>
            <p>Guides and downloads for {label}</p>
          </div>
          <div className="user-avatar">
            {user?.name?.charAt(0).toUpperCase() || 'U'}
          </div>
        </header>

        <ProductDocs product={product} title="Documentation" />
      </main>
    </div>
  );
}

export default ProductDocsPage;
