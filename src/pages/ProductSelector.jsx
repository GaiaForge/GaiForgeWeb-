import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

const allProducts = [
  {
    id: 'orpheus',
    name: 'Orpheus',
    description: 'IoT audio playback system for wildlife research. Manage your devices and download the latest firmware updates.',
    image: '/images/Orpheus.png',
    route: '/orpheus',
  },
  {
    id: 'hiveguard',
    name: 'HiveGuard',
    description: 'Bioacoustic beehive monitor. View hive analytics, upload sensor data, and track colony health.',
    image: '/images/hiveguard_logo.png',
    route: '/dashboard',
  },
  {
    id: 'sprigrig',
    name: 'SprigRig',
    description: 'Modular controlled environment agriculture system. Monitor and manage your growing environment.',
    image: '/images/SprigRig.png',
    route: '/sprigrig',
  },
];

function ProductSelector({ user, onLogout }) {
  const navigate = useNavigate();
  const userProducts = user?.products || [];
  const isAdmin = user?.is_admin;

  // Admins see all products; regular users only see their unlocked ones
  const visibleProducts = isAdmin
    ? allProducts
    : allProducts.filter(p => userProducts.includes(p.id));

  // Regular users with exactly one product skip the selector and go directly
  // to it. Admins always see the full grid here — they're routed to the admin
  // panel at login instead (see Login.jsx / ForceChangePassword.jsx), so by
  // the time they reach this page they've asked to see it, e.g. via the
  // "Products" back-link on a dashboard.
  useEffect(() => {
    if (!isAdmin && visibleProducts.length === 1) {
      navigate(visibleProducts[0].route, { replace: true });
    }
  }, [isAdmin, visibleProducts, navigate]);

  const handleLogout = () => {
    onLogout();
    navigate('/login');
  };

  return (
    <div className="selector-container">
      <div className="selector-background">
        <div className="auth-blob blob-1"></div>
        <div className="auth-blob blob-2"></div>
        <div className="auth-blob blob-3"></div>
      </div>

      <div className="selector-content">
        <div className="selector-header">
          <div className="selector-logo">
            <img src="/gaiaforge-logo.png" alt="GaiaForge" className="selector-logo-img" />
          </div>
          <div className="selector-user-info">
            <span className="selector-greeting">Welcome, {user?.name || 'User'}</span>
            <button onClick={handleLogout} className="selector-logout-btn">Logout</button>
          </div>
        </div>

        <div className="selector-heading">
          <h1>Select Your Device</h1>
          <p>Choose a product to access its portal</p>
        </div>

        {visibleProducts.length === 0 ? (
          <div style={{ textAlign: 'center', color: '#94a3b8', padding: '40px 0' }}>
            <p style={{ fontSize: '18px', marginBottom: '12px' }}>No devices registered yet.</p>
            <p style={{ fontSize: '14px' }}>Contact GaiaForge support if you believe this is an error.</p>
          </div>
        ) : (
          <div className="selector-grid" style={visibleProducts.length < 3 ? { gridTemplateColumns: `repeat(${visibleProducts.length}, 1fr)`, maxWidth: `${visibleProducts.length * 360}px`, margin: '0 auto 48px' } : {}}>
            {visibleProducts.map((product) => (
              <div
                key={product.id}
                className="selector-card"
                onClick={() => navigate(product.route)}
                role="button"
                tabIndex={0}
                onKeyDown={(e) => e.key === 'Enter' && navigate(product.route)}
              >
                <div className="selector-card-image">
                  <img src={product.image} alt={product.name} />
                </div>
                <div className="selector-card-body">
                  <h3>{product.name}</h3>
                  <p>{product.description}</p>
                  <span className="selector-badge-open">Open Portal &rarr;</span>
                </div>
              </div>
            ))}
          </div>
        )}

        <div className="selector-footer">
          <a href="/">Back to GaiaForge.co.za</a>
        </div>
      </div>
    </div>
  );
}

export default ProductSelector;
