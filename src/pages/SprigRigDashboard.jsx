import React from 'react';
import { Link, useNavigate } from 'react-router-dom';

function SprigRigDashboard({ user, onLogout }) {
  const navigate = useNavigate();

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
          <Link to="/products" className="nav-item back-link">
            <span className="nav-icon">&larr;</span> All Products
          </Link>
          <Link to="/profile" className="nav-item">
            <span className="nav-icon">👤</span> Profile
          </Link>
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
            <h1>SprigRig Portal</h1>
            <p>Controlled environment agriculture management</p>
          </div>
          <div className="user-avatar">
            {user?.name?.charAt(0).toUpperCase() || 'U'}
          </div>
        </header>

        <div className="empty-state">
          <div className="empty-icon">🌱</div>
          <h2>Coming Soon</h2>
          <p>
            The SprigRig portal is under development. You'll be able to monitor and manage your
            growing environments, view sensor data, and configure automation schedules here.
          </p>
          <Link to="/products" className="btn-primary-link" style={{ marginTop: '24px', display: 'inline-block' }}>
            Back to Products
          </Link>
        </div>
      </main>
    </div>
  );
}

export default SprigRigDashboard;
