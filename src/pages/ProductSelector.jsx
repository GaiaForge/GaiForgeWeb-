import React from 'react';
import { useNavigate } from 'react-router-dom';

const products = [
  {
    id: 'orpheus',
    name: 'Orpheus',
    description: 'IoT audio playback system for wildlife research. Manage your devices and download the latest firmware updates.',
    image: '/images/Orpheus.png',
    route: '/orpheus',
    available: true,
  },
  {
    id: 'hiveguard',
    name: 'HiveGuard',
    description: 'Bioacoustic beehive monitor. View hive analytics, upload sensor data, and track colony health.',
    image: '/images/hiveguard_logo.png',
    route: '/dashboard',
    available: true,
  },
  {
    id: 'sprigrig',
    name: 'SprigRig',
    description: 'Modular controlled environment agriculture system. Monitor and manage your growing environment.',
    image: '/images/SprigRig.png',
    route: '/sprigrig',
    available: false,
  },
];

function ProductSelector({ user, onLogout }) {
  const navigate = useNavigate();

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

        <div className="selector-grid">
          {products.map((product) => (
            <div
              key={product.id}
              className={`selector-card ${!product.available ? 'coming-soon' : ''}`}
              onClick={() => product.available && navigate(product.route)}
              role="button"
              tabIndex={product.available ? 0 : -1}
              onKeyDown={(e) => e.key === 'Enter' && product.available && navigate(product.route)}
            >
              <div className="selector-card-image">
                <img src={product.image} alt={product.name} />
              </div>
              <div className="selector-card-body">
                <h3>{product.name}</h3>
                <p>{product.description}</p>
                {!product.available && (
                  <span className="selector-badge-soon">Coming Soon</span>
                )}
                {product.available && (
                  <span className="selector-badge-open">Open Portal &rarr;</span>
                )}
              </div>
            </div>
          ))}
        </div>

        <div className="selector-footer">
          <a href="/">Back to GaiaForge.co.za</a>
        </div>
      </div>
    </div>
  );
}

export default ProductSelector;
