import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Dashboard.css';

function Profile({ user, onLogout }) {
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
          <a href="/" className="nav-item back-link">
            <span className="nav-icon">←</span> Back to Site
          </a>
          <Link to="/dashboard" className="nav-item">
            <span className="nav-icon">📊</span>
            Dashboard
          </Link>
          <Link to="/upload" className="nav-item">
            <span className="nav-icon">⬆️</span>
            Upload Data
          </Link>
          <Link to="/devices" className="nav-item">
            <span className="nav-icon">📟</span>
            My Devices
          </Link>
          <Link to="/profile" className="nav-item active">
            <span className="nav-icon">👤</span>
            Profile
          </Link>
        </nav>
        
        <div className="sidebar-footer">
          <button onClick={handleLogout} className="logout-btn">
            <span className="nav-icon">🚪</span>
            Logout
          </button>
        </div>
      </aside>

      <main className="main-content">
        <header className="content-header">
          <div>
            <h1>Profile Settings</h1>
            <p>Manage your account settings and preferences</p>
          </div>
        </header>

        <div style={{maxWidth: '600px'}}>
          <div className="device-selector">
            <h3>Account Information</h3>
            <div className="form-group" style={{marginBottom: '20px'}}>
              <label>Name</label>
              <input type="text" value={user?.name || ''} disabled style={{padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%', background: '#f9fafb'}} />
            </div>
            <div className="form-group">
              <label>Email</label>
              <input type="email" value={user?.email || ''} disabled style={{padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%', background: '#f9fafb'}} />
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

export default Profile;