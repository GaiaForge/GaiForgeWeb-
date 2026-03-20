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

  // Data management
  const [allHives, setAllHives] = useState([]);
  const [archiveHiveId, setArchiveHiveId] = useState('');
  const [archiveBefore, setArchiveBefore] = useState('');
  const [archiveCount, setArchiveCount] = useState(null);
  const [archiving, setArchiving] = useState(false);
  const [archiveMessage, setArchiveMessage] = useState(null);

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
      const [statsRes, usersRes, hivesRes] = await Promise.all([
        fetch(`${API_BASE}/api/admin/stats`, { headers }),
        fetch(`${API_BASE}/api/admin/users`, { headers }),
        fetch(`${API_BASE}/api/admin/hives`, { headers }),
      ]);

      if (statsRes.status === 403 || usersRes.status === 403) {
        setError('Admin access required.');
        setLoading(false);
        return;
      }

      if (statsRes.ok) setStats(await statsRes.json());
      if (usersRes.ok) setUsers(await usersRes.json());
      if (hivesRes.ok) setAllHives(await hivesRes.json());
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

  const fetchArchiveCount = async (hiveId, before) => {
    if (!before) { setArchiveCount(null); return; }
    try {
      const params = new URLSearchParams({ before });
      if (hiveId) params.set('hive_id', hiveId);
      const res = await fetch(`${API_BASE}/api/admin/readings/count?${params}`, { headers });
      if (res.ok) { const data = await res.json(); setArchiveCount(data.count); }
    } catch { setArchiveCount(null); }
  };

  const handleArchiveHiveChange = (val) => {
    setArchiveHiveId(val);
    setArchiveCount(null);
    fetchArchiveCount(val, archiveBefore);
  };

  const handleArchiveDateChange = (val) => {
    setArchiveBefore(val);
    setArchiveCount(null);
    fetchArchiveCount(archiveHiveId, val ? val + 'T00:00:00Z' : '');
  };

  const runArchive = async () => {
    if (!archiveBefore || archiveCount === 0) return;
    if (!window.confirm(`Archive and delete ${archiveCount.toLocaleString()} readings before ${archiveBefore}? This cannot be undone.`)) return;
    setArchiving(true);
    setArchiveMessage(null);
    try {
      const params = new URLSearchParams({ before: archiveBefore + 'T00:00:00Z' });
      if (archiveHiveId) params.set('hive_id', archiveHiveId);
      const res = await fetch(`${API_BASE}/api/admin/readings/archive?${params}`, {
        method: 'POST', headers,
      });
      if (res.ok) {
        const blob = await res.blob();
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = res.headers.get('Content-Disposition')?.split('filename=')[1] || 'archive.csv';
        a.click();
        URL.revokeObjectURL(url);
        setArchiveMessage({ type: 'ok', text: `Archived and deleted ${archiveCount.toLocaleString()} readings.` });
        setArchiveCount(null);
        fetchData();
      } else {
        const err = await res.json();
        setArchiveMessage({ type: 'err', text: err.detail || 'Archive failed' });
      }
    } catch {
      setArchiveMessage({ type: 'err', text: 'Connection error' });
    } finally {
      setArchiving(false);
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

            {/* Data Management */}
            <div className="admin-card status-warn">
              <h3>Data Management</h3>
              <p style={{fontSize: '14px', color: '#6b7280', marginBottom: '20px'}}>
                Export readings to CSV then permanently delete them from the database.
                The CSV will download automatically before deletion.
              </p>
              <div style={{display: 'flex', gap: '12px', flexWrap: 'wrap', alignItems: 'flex-end', marginBottom: '16px'}}>
                <div>
                  <label style={{display: 'block', fontSize: '13px', fontWeight: 600, color: '#374151', marginBottom: '6px'}}>
                    Hive
                  </label>
                  <select
                    value={archiveHiveId}
                    onChange={e => handleArchiveHiveChange(e.target.value)}
                    style={{padding: '10px 14px', border: '2px solid #e5e7eb', borderRadius: '10px', fontSize: '14px', background: '#fff', minWidth: '200px'}}
                  >
                    <option value="">All hives</option>
                    {allHives.map(h => (
                      <option key={h.id} value={h.id}>{h.name} ({h.owner})</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label style={{display: 'block', fontSize: '13px', fontWeight: 600, color: '#374151', marginBottom: '6px'}}>
                    Delete readings before
                  </label>
                  <input
                    type="date"
                    value={archiveBefore}
                    onChange={e => handleArchiveDateChange(e.target.value)}
                    style={{padding: '10px 14px', border: '2px solid #e5e7eb', borderRadius: '10px', fontSize: '14px'}}
                  />
                </div>
                <div style={{paddingBottom: '2px'}}>
                  {archiveCount !== null && (
                    <div style={{fontSize: '13px', color: archiveCount === 0 ? '#6b7280' : '#92400e', fontWeight: 600, marginBottom: '8px'}}>
                      {archiveCount === 0 ? 'No readings in this range' : `${archiveCount.toLocaleString()} readings will be deleted`}
                    </div>
                  )}
                  <button
                    onClick={runArchive}
                    disabled={archiving || !archiveBefore || archiveCount === 0 || archiveCount === null}
                    style={{
                      padding: '10px 20px', background: '#ef4444', color: '#fff',
                      border: 'none', borderRadius: '10px', fontWeight: 600,
                      cursor: 'pointer', fontSize: '14px',
                      opacity: (archiving || !archiveBefore || archiveCount === 0 || archiveCount === null) ? 0.5 : 1,
                    }}
                  >
                    {archiving ? 'Archiving...' : 'Archive & Delete'}
                  </button>
                </div>
              </div>
              {archiveMessage && (
                <p style={{fontSize: '13px', color: archiveMessage.type === 'ok' ? '#10b981' : '#ef4444'}}>
                  {archiveMessage.text}
                </p>
              )}
            </div>

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
