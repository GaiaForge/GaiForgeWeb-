import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Dashboard.css';
import './Admin.css';

const API_BASE = window.location.origin;

function Admin({ user, onLogout }) {
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [apiKey, setApiKey] = useState('');
  const [keySaving, setKeySaving] = useState(false);
  const [keyMessage, setKeyMessage] = useState(null);

  const headers = {
    'Authorization': `Bearer ${user?.token}`,
    'Content-Type': 'application/json',
  };

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [statsRes, usersRes] = await Promise.all([
        fetch(`${API_BASE}/api/admin/stats`, { headers }),
        fetch(`${API_BASE}/api/admin/users`, { headers }),
      ]);

      if (statsRes.status === 403 || usersRes.status === 403) {
        setError('Admin access required.');
        setLoading(false);
        return;
      }

      if (statsRes.ok) setStats(await statsRes.json());
      if (usersRes.ok) setUsers(await usersRes.json());
    } catch (err) {
      setError('Failed to load admin data.');
    } finally {
      setLoading(false);
    }
  };

  const saveApiKey = async () => {
    if (!apiKey.trim()) return;
    setKeySaving(true);
    setKeyMessage(null);
    try {
      const res = await fetch(`${API_BASE}/api/admin/config/api-key`, {
        method: 'PUT',
        headers,
        body: JSON.stringify({ api_key: apiKey.trim() }),
      });
      if (res.ok) {
        setKeyMessage({ type: 'ok', text: 'API key saved successfully' });
        setApiKey('');
        setStats({ ...stats, ai_configured: true });
      } else {
        setKeyMessage({ type: 'err', text: 'Failed to save API key' });
      }
    } catch (err) {
      setKeyMessage({ type: 'err', text: 'Connection error' });
    } finally {
      setKeySaving(false);
    }
  };

  const toggleSubscription = async (userId, currentTier) => {
    const newTier = currentTier === 'pro' ? 'free' : 'pro';
    try {
      const res = await fetch(`${API_BASE}/api/admin/users/${userId}/subscription`, {
        method: 'PUT',
        headers,
        body: JSON.stringify({ subscription_tier: newTier }),
      });
      if (res.ok) {
        setUsers(users.map(u =>
          u.id === userId ? { ...u, subscription_tier: newTier } : u
        ));
      }
    } catch (err) {
      console.error('Failed to update subscription:', err);
    }
  };

  const toggleActive = async (userId) => {
    try {
      const res = await fetch(`${API_BASE}/api/admin/users/${userId}/active`, {
        method: 'PUT',
        headers,
      });
      if (res.ok) {
        const data = await res.json();
        setUsers(users.map(u =>
          u.id === userId ? { ...u, is_active: data.is_active } : u
        ));
      }
    } catch (err) {
      console.error('Failed to toggle user:', err);
    }
  };

  const handleLogout = () => { onLogout(); navigate('/login'); };

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
            <span className="nav-icon">📊</span> Dashboard
          </Link>
          <Link to="/analytics" className="nav-item">
            <span className="nav-icon">🔬</span> Analytics
          </Link>
          <Link to="/upload" className="nav-item">
            <span className="nav-icon">⬆️</span> Upload Data
          </Link>
          <Link to="/devices" className="nav-item">
            <span className="nav-icon">📟</span> My Hives
          </Link>
          <Link to="/admin" className="nav-item active">
            <span className="nav-icon">⚙️</span> Admin
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
            <h1>Admin Panel</h1>
            <p>Platform management and user overview</p>
          </div>
        </header>

        {error && <div className="error-message">{error}</div>}

        {loading ? (
          <div className="loading-state">Loading admin data...</div>
        ) : (
          <>
            {/* Platform Stats */}
            {stats && (
              <div className="stats-grid">
                <div className="stat-card">
                  <div className="stat-icon">👥</div>
                  <div className="stat-content">
                    <div className="stat-value">{stats.total_users}</div>
                    <div className="stat-label">Total Users</div>
                  </div>
                </div>
                <div className="stat-card">
                  <div className="stat-icon">⭐</div>
                  <div className="stat-content">
                    <div className="stat-value">{stats.pro_users}</div>
                    <div className="stat-label">Pro Subscribers</div>
                  </div>
                </div>
                <div className="stat-card">
                  <div className="stat-icon">🐝</div>
                  <div className="stat-content">
                    <div className="stat-value">{stats.total_hives}</div>
                    <div className="stat-label">Total Hives</div>
                  </div>
                </div>
                <div className="stat-card">
                  <div className="stat-icon">📊</div>
                  <div className="stat-content">
                    <div className="stat-value">{stats.total_readings.toLocaleString()}</div>
                    <div className="stat-label">Total Readings</div>
                  </div>
                </div>
              </div>
            )}

            {/* AI Config Status */}
            {stats && (
              <div className={`admin-card ${stats.ai_configured ? 'status-ok' : 'status-warn'}`}>
                <h3>AI Insights Configuration</h3>
                <div className="config-row">
                  <span>Claude API Key</span>
                  <span className={`config-status ${stats.ai_configured ? 'ok' : 'missing'}`}>
                    {stats.ai_configured ? '✓ Configured' : '✗ Not set'}
                  </span>
                </div>
                <div style={{marginTop: '16px', display: 'flex', gap: '10px', alignItems: 'center'}}>
                  <input
                    type="password"
                    value={apiKey}
                    onChange={e => setApiKey(e.target.value)}
                    placeholder={stats.ai_configured ? 'Enter new key to update...' : 'Paste your Anthropic API key...'}
                    style={{
                      flex: 1, padding: '10px 14px', border: '2px solid #e5e7eb',
                      borderRadius: '10px', fontSize: '14px',
                    }}
                  />
                  <button
                    onClick={saveApiKey}
                    disabled={keySaving || !apiKey.trim()}
                    style={{
                      padding: '10px 20px', background: '#f59e0b', color: '#fff',
                      border: 'none', borderRadius: '10px', fontWeight: 600,
                      cursor: 'pointer', opacity: keySaving || !apiKey.trim() ? 0.5 : 1,
                    }}
                  >
                    {keySaving ? 'Saving...' : 'Save Key'}
                  </button>
                </div>
                {keyMessage && (
                  <p style={{
                    marginTop: '10px', fontSize: '13px',
                    color: keyMessage.type === 'ok' ? '#10b981' : '#ef4444',
                  }}>
                    {keyMessage.text}
                  </p>
                )}
                <p className="config-hint" style={{marginTop: '12px'}}>
                  Your key is stored securely on the server and never sent to the browser. It powers AI colony reports for Pro subscribers.
                </p>
              </div>
            )}

            {/* User Management */}
            <div className="admin-card">
              <h3>User Management</h3>
              <table className="admin-table">
                <thead>
                  <tr>
                    <th>User</th>
                    <th>Email</th>
                    <th>Joined</th>
                    <th>Hives</th>
                    <th>Readings</th>
                    <th>Tier</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map(u => (
                    <tr key={u.id} className={!u.is_active ? 'row-inactive' : ''}>
                      <td>
                        <div className="user-cell">
                          <div className="user-mini-avatar">
                            {u.name.charAt(0).toUpperCase()}
                          </div>
                          {u.name}
                          {u.id === 1 && <span className="admin-tag">admin</span>}
                        </div>
                      </td>
                      <td>{u.email}</td>
                      <td>{new Date(u.created_at).toLocaleDateString()}</td>
                      <td>{u.hive_count}</td>
                      <td>{u.reading_count.toLocaleString()}</td>
                      <td>
                        <span className={`tier-badge ${u.subscription_tier}`}>
                          {u.subscription_tier}
                        </span>
                      </td>
                      <td>
                        <span className={`status-dot ${u.is_active ? 'active' : 'inactive'}`}></span>
                        {u.is_active ? 'Active' : 'Disabled'}
                      </td>
                      <td>
                        <div className="action-buttons">
                          <button
                            className="btn-small btn-tier"
                            onClick={() => toggleSubscription(u.id, u.subscription_tier)}
                          >
                            {u.subscription_tier === 'pro' ? 'Downgrade' : 'Upgrade'}
                          </button>
                          {u.id !== 1 && (
                            <button
                              className="btn-small btn-toggle"
                              onClick={() => toggleActive(u.id)}
                            >
                              {u.is_active ? 'Disable' : 'Enable'}
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}
      </main>
    </div>
  );
}

export default Admin;
