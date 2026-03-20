import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Dashboard.css';

const API_BASE = window.location.origin;

function Devices({ user, onLogout }) {
  const navigate = useNavigate();
  const [hives, setHives] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);
  const [newHive, setNewHive] = useState({ name: '', location: '' });
  const [error, setError] = useState('');

  const headers = {
    'Authorization': `Bearer ${user?.token}`,
    'Content-Type': 'application/json',
  };

  useEffect(() => {
    fetchHives();
  }, []);

  const fetchHives = async () => {
    try {
      const res = await fetch(`${API_BASE}/api/hives`, { headers });
      if (res.ok) {
        setHives(await res.json());
      }
    } catch (err) {
      console.error('Failed to fetch hives:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleAddHive = async (e) => {
    e.preventDefault();
    setError('');
    if (!newHive.name) {
      setError('Hive name is required');
      return;
    }
    try {
      const res = await fetch(`${API_BASE}/api/hives`, {
        method: 'POST',
        headers,
        body: JSON.stringify(newHive),
      });
      if (res.ok) {
        setNewHive({ name: '', location: '' });
        setShowAdd(false);
        fetchHives();
      } else {
        const data = await res.json().catch(() => ({}));
        setError(data.detail || 'Failed to add hive');
      }
    } catch (err) {
      setError('Network error');
    }
  };

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
            <span className="nav-icon">📊</span> Dashboard
          </Link>
          <Link to="/analytics" className="nav-item">
            <span className="nav-icon">🔬</span> Analytics
          </Link>
          <Link to="/upload" className="nav-item">
            <span className="nav-icon">⬆️</span> Upload Data
          </Link>
          <Link to="/devices" className="nav-item active">
            <span className="nav-icon">📟</span> My Hives
          </Link>
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
            <h1>My Hives</h1>
            <p>Manage your beehive monitoring stations</p>
          </div>
          <button
            onClick={() => setShowAdd(!showAdd)}
            style={{
              padding: '10px 20px', background: '#f59e0b', color: '#fff',
              border: 'none', borderRadius: '10px', fontWeight: 600, cursor: 'pointer'
            }}
          >
            + Add Hive
          </button>
        </header>

        {showAdd && (
          <div className="device-selector" style={{marginBottom: '24px'}}>
            <h3>Add New Hive</h3>
            {error && <div className="error-message" style={{
              background: '#fef2f2', color: '#dc2626', padding: '10px 14px',
              borderRadius: '8px', marginBottom: '12px', fontSize: '14px'
            }}>{error}</div>}
            <form onSubmit={handleAddHive}>
              <div className="form-group" style={{marginBottom: '14px'}}>
                <label>Hive Name</label>
                <input type="text" value={newHive.name}
                  onChange={e => setNewHive({...newHive, name: e.target.value})}
                  placeholder="e.g. Backyard Hive #1"
                  style={{padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%'}} />
              </div>
              <div className="form-group" style={{marginBottom: '14px'}}>
                <label>Location (optional)</label>
                <input type="text" value={newHive.location}
                  onChange={e => setNewHive({...newHive, location: e.target.value})}
                  placeholder="e.g. South field"
                  style={{padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%'}} />
              </div>
              <button type="submit" style={{
                padding: '12px 24px', background: '#10b981', color: '#fff',
                border: 'none', borderRadius: '10px', fontWeight: 600, cursor: 'pointer'
              }}>Save Hive</button>
            </form>
          </div>
        )}

        {loading ? (
          <div className="loading-state">Loading hives...</div>
        ) : hives.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">🐝</div>
            <h2>No hives registered</h2>
            <p>Click "Add Hive" to register your first beehive.</p>
          </div>
        ) : (
          <div className="uploads-table">
            {hives.map(hive => (
              <div key={hive.id} className="upload-row">
                <div className="upload-info">
                  <div className="upload-icon">🐝</div>
                  <div>
                    <div className="upload-name">{hive.name}</div>
                    <div className="upload-meta">
                      {hive.location || 'No location'} · ID: {hive.id}
                    </div>
                  </div>
                </div>
                <div>
                  <span style={{
                    padding: '4px 12px', borderRadius: '12px', fontSize: '13px',
                    fontWeight: '500', background: '#d1fae5', color: '#065f46'
                  }}>Active</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}

export default Devices;
