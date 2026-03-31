import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

function OrpheusDashboard({ user, onLogout }) {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('downloads');

  const handleLogout = () => {
    onLogout();
    navigate('/login');
  };

  const firmwareUpdates = [
    {
      version: '2.1.0',
      date: '2026-03-15',
      variant: 'Pro',
      filename: 'Orpheus-Pro-USB-Update-v2.1.0.zip',
      size: '14.2 MB',
      notes: 'Improved scheduling reliability, power management optimizations.',
    },
    {
      version: '2.1.0',
      date: '2026-03-15',
      variant: 'Basic',
      filename: 'Orpheus-Basic-USB-Update-v2.1.0.zip',
      size: '12.8 MB',
      notes: 'Improved scheduling reliability, power management optimizations.',
    },
    {
      version: '2.0.3',
      date: '2026-02-01',
      variant: 'Pro',
      filename: 'Orpheus-Pro-USB-Update-v2.0.3.zip',
      size: '13.9 MB',
      notes: 'Bug fix for playlist shuffle mode, audio fade improvements.',
    },
    {
      version: '2.0.3',
      date: '2026-02-01',
      variant: 'Basic',
      filename: 'Orpheus-Basic-USB-Update-v2.0.3.zip',
      size: '12.5 MB',
      notes: 'Bug fix for playlist shuffle mode, audio fade improvements.',
    },
  ];

  const docs = [
    {
      title: 'Orpheus User Manual',
      description: 'Complete guide covering setup, operation, and maintenance.',
      icon: '📖',
      href: '/orpheus-manual.html',
      type: 'html',
    },
    {
      title: 'Quick Start Guide',
      description: 'Get your Orpheus device up and running quickly.',
      icon: '🚀',
      href: '/downloads/Orpheus-Basic-Quick-Start-Guide.pdf',
      type: 'pdf',
    },
    {
      title: 'Solar Panel Alignment Guide',
      description: 'Optimize solar panel positioning for your deployment site.',
      icon: '☀️',
      href: '/downloads/Orpheus-Solar-Panel-Guide.pdf',
      type: 'pdf',
    },
  ];

  const mobileApp = {
    android: {
      version: '1.8.0',
      href: '/downloads/Orpheus-v1.8.0.apk',
      size: '56 MB',
    },
    ios: null, // coming soon
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
          <button
            className={`nav-item nav-btn ${activeTab === 'downloads' ? 'active' : ''}`}
            onClick={() => setActiveTab('downloads')}
          >
            <span className="nav-icon">📦</span> USB Updates
          </button>
          <button
            className={`nav-item nav-btn ${activeTab === 'docs' ? 'active' : ''}`}
            onClick={() => setActiveTab('docs')}
          >
            <span className="nav-icon">📖</span> Documentation
          </button>
          <button
            className={`nav-item nav-btn ${activeTab === 'app' ? 'active' : ''}`}
            onClick={() => setActiveTab('app')}
          >
            <span className="nav-icon">📱</span> Mobile App
          </button>
          <Link to="/profile" className="nav-item">
            <span className="nav-icon">👤</span> Profile
          </Link>
          {user?.is_admin && <Link to="/admin" className="nav-item">
            <span className="nav-icon">⚙️</span> Admin
          </Link>}
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
            <h1>Orpheus Portal</h1>
            <p>Manage your Orpheus audio playback devices</p>
          </div>
          <div className="user-avatar">
            {user?.name?.charAt(0).toUpperCase() || 'U'}
          </div>
        </header>

        {/* USB Updates Tab */}
        {activeTab === 'downloads' && (
          <>
            <div className="orpheus-info-banner">
              <div className="info-icon">💡</div>
              <div>
                <strong>How USB updates work:</strong> Download the .zip file for your device variant (Basic or Pro).
                Extract to a USB drive and insert into your Orpheus device. The device will apply the update on next boot.
                Update packages are password-protected — use the password provided with your device.
              </div>
            </div>

            <div className="actions-section">
              <h2>Firmware &amp; Software Updates</h2>
              <div className="orpheus-downloads-list">
                {firmwareUpdates.map((update, i) => (
                  <div key={i} className="orpheus-download-row">
                    <div className="orpheus-download-info">
                      <div className="orpheus-download-icon">
                        <span className={`variant-badge ${update.variant.toLowerCase()}`}>
                          {update.variant}
                        </span>
                      </div>
                      <div>
                        <div className="upload-name">
                          {update.filename}
                        </div>
                        <div className="upload-meta">
                          v{update.version} &middot; {update.date} &middot; {update.size}
                        </div>
                        <div className="upload-meta" style={{ marginTop: '4px' }}>
                          {update.notes}
                        </div>
                      </div>
                    </div>
                    <a
                      href={`/downloads/orpheus/${update.filename}`}
                      className="btn-download"
                      download
                    >
                      Download
                    </a>
                  </div>
                ))}
              </div>
            </div>
          </>
        )}

        {/* Documentation Tab */}
        {activeTab === 'docs' && (
          <div className="actions-section">
            <h2>Documentation</h2>
            <div className="actions-grid">
              {docs.map((doc, i) => (
                <a
                  key={i}
                  href={doc.href}
                  className="action-card"
                  target="_blank"
                  rel="noreferrer"
                >
                  <div className="action-icon">{doc.icon}</div>
                  <h3>{doc.title}</h3>
                  <p>{doc.description}</p>
                  <span className="upload-meta" style={{ marginTop: '8px', display: 'block' }}>
                    {doc.type === 'pdf' ? 'PDF Download' : 'View Online'}
                  </span>
                </a>
              ))}
            </div>
          </div>
        )}

        {/* Mobile App Tab */}
        {activeTab === 'app' && (
          <div className="actions-section">
            <h2>Orpheus Mobile App</h2>
            <p style={{ color: '#6b7280', marginBottom: '24px' }}>
              Control your Orpheus device via Bluetooth. Create playlists, set schedules, and monitor device status.
            </p>
            <div className="actions-grid">
              <a
                href={mobileApp.android.href}
                className="action-card"
                download
              >
                <div className="action-icon">🤖</div>
                <h3>Android APK</h3>
                <p>Version {mobileApp.android.version} &middot; {mobileApp.android.size}</p>
                <span className="selector-badge-open" style={{ marginTop: '12px', display: 'inline-block' }}>
                  Download APK
                </span>
              </a>
              <div className="action-card" style={{ opacity: 0.5, cursor: 'default' }}>
                <div className="action-icon">🍎</div>
                <h3>iOS App</h3>
                <p>Coming soon to the App Store.</p>
                <span className="selector-badge-soon" style={{ marginTop: '12px', display: 'inline-block' }}>
                  Coming Soon
                </span>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

export default OrpheusDashboard;
