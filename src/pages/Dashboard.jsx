import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Dashboard.css';

const API_BASE = window.location.origin;

function Dashboard({ user, onLogout }) {
  const navigate = useNavigate();
  const [hives, setHives] = useState([]);
  const [overview, setOverview] = useState(null);
  const [loading, setLoading] = useState(true);
  const [selectedHive, setSelectedHive] = useState(null);

  const headers = {
    'Authorization': `Bearer ${user?.token}`,
    'Content-Type': 'application/json',
  };

  useEffect(() => {
    fetchHives();
  }, []);

  useEffect(() => {
    if (selectedHive) {
      fetchOverview(selectedHive);
    }
  }, [selectedHive]);

  const fetchHives = async () => {
    try {
      const res = await fetch(`${API_BASE}/api/hives`, { headers });
      if (res.ok) {
        const data = await res.json();
        setHives(data);
        if (data.length > 0) {
          setSelectedHive(data[0].id);
        }
      }
    } catch (err) {
      console.error('Failed to fetch hives:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchOverview = async (hiveId) => {
    try {
      const res = await fetch(`${API_BASE}/api/analysis/hive/${hiveId}/overview`, { headers });
      if (res.ok) {
        const data = await res.json();
        setOverview(data);
      }
    } catch (err) {
      console.error('Failed to fetch overview:', err);
    }
  };

  const handleLogout = () => {
    onLogout();
    navigate('/login');
  };

  const getHealthColor = (score) => {
    if (score >= 80) return '#10b981';
    if (score >= 50) return '#f59e0b';
    return '#ef4444';
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
          <Link to="/dashboard" className="nav-item active">
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
            <h1>Welcome back, {user?.name || 'User'}!</h1>
            <p>Your hive monitoring dashboard</p>
          </div>
          <div className="user-avatar">
            {user?.name?.charAt(0).toUpperCase() || 'U'}
          </div>
        </header>

        {loading ? (
          <div className="loading-state">Loading your hives...</div>
        ) : hives.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">🐝</div>
            <h2>No hives yet</h2>
            <p>Add your first hive to start monitoring. Sync data from the HiveGuard app or upload CSV files from the SD card.</p>
            <div className="actions-grid" style={{marginTop: '24px'}}>
              <Link to="/devices" className="action-card">
                <div className="action-icon">➕</div>
                <h3>Add a Hive</h3>
                <p>Register your first beehive</p>
              </Link>
              <Link to="/upload" className="action-card">
                <div className="action-icon">⬆️</div>
                <h3>Upload CSV Data</h3>
                <p>Import data from SD card</p>
              </Link>
            </div>
          </div>
        ) : (
          <>
            {/* Hive selector */}
            {hives.length > 1 && (
              <div className="hive-selector">
                {hives.map(h => (
                  <button
                    key={h.id}
                    className={`hive-tab ${selectedHive === h.id ? 'active' : ''}`}
                    onClick={() => setSelectedHive(h.id)}
                  >
                    🐝 {h.name}
                  </button>
                ))}
              </div>
            )}

            {/* Health Score */}
            {overview?.health && (
              <div className="stats-grid">
                <div className="stat-card health-card">
                  <div className="health-score" style={{color: getHealthColor(overview.health.score)}}>
                    {overview.health.score}
                  </div>
                  <div className="stat-content">
                    <div className="stat-value">{overview.health.category}</div>
                    <div className="stat-label">Health Score</div>
                  </div>
                </div>
                <div className="stat-card">
                  <div className="stat-icon">👑</div>
                  <div className="stat-content">
                    <div className="stat-value">{overview.health.queen_presence_pct}%</div>
                    <div className="stat-label">Queen Presence</div>
                  </div>
                </div>
                <div className="stat-card">
                  <div className="stat-icon">⚠️</div>
                  <div className="stat-content">
                    <div className="stat-value">{overview.health.stress_pct}%</div>
                    <div className="stat-label">Stress Level</div>
                  </div>
                </div>
                <div className="stat-card">
                  <div className="stat-icon">📊</div>
                  <div className="stat-content">
                    <div className="stat-value">{overview.health.total_readings}</div>
                    <div className="stat-label">Total Readings</div>
                  </div>
                </div>
              </div>
            )}

            {/* Bee State Distribution */}
            {overview?.bee_states && overview.bee_states.length > 0 && (
              <div className="recent-section">
                <h2>Bee State Distribution</h2>
                <div className="uploads-table">
                  {overview.bee_states.map((state, i) => (
                    <div key={i} className="upload-row">
                      <div className="upload-info">
                        <div className="upload-icon">🐝</div>
                        <div>
                          <div className="upload-name">{state.label}</div>
                          <div className="upload-meta">{state.count} readings</div>
                        </div>
                      </div>
                      <div style={{display: 'flex', alignItems: 'center', gap: '12px'}}>
                        <div style={{
                          width: '120px', height: '8px', background: '#e5e7eb',
                          borderRadius: '4px', overflow: 'hidden'
                        }}>
                          <div style={{
                            width: `${state.percentage}%`, height: '100%',
                            background: '#f59e0b', borderRadius: '4px'
                          }}></div>
                        </div>
                        <span style={{fontWeight: 600, color: '#1f2937', minWidth: '48px', textAlign: 'right'}}>
                          {state.percentage}%
                        </span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Daily Summaries */}
            {overview?.daily_summaries && overview.daily_summaries.length > 0 && (
              <div className="recent-section">
                <h2>Daily Trends</h2>
                <div className="uploads-table">
                  {overview.daily_summaries.slice(-7).map((day, i) => (
                    <div key={i} className="upload-row">
                      <div className="upload-info">
                        <div className="upload-icon">📅</div>
                        <div>
                          <div className="upload-name">{day.date}</div>
                          <div className="upload-meta">
                            {day.reading_count} readings · Avg {day.avg_sound_level} dB · {day.avg_dominant_freq} Hz
                          </div>
                        </div>
                      </div>
                      <div className="upload-date">
                        Risk: {day.max_absconding_risk}%
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Quick Actions */}
            <div className="actions-section">
              <h2>Quick Actions</h2>
              <div className="actions-grid">
                <Link to="/upload" className="action-card">
                  <div className="action-icon">⬆️</div>
                  <h3>Upload CSV Data</h3>
                  <p>Import sensor data from SD card</p>
                </Link>
                <Link to="/devices" className="action-card">
                  <div className="action-icon">➕</div>
                  <h3>Add Hive</h3>
                  <p>Register a new beehive</p>
                </Link>
                <a href="/docs" className="action-card" target="_blank" rel="noreferrer">
                  <div className="action-icon">📖</div>
                  <h3>API Docs</h3>
                  <p>View the full API reference</p>
                </a>
              </div>
            </div>
          </>
        )}
      </main>
    </div>
  );
}

export default Dashboard;
