import React, { useState, useEffect, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';

const API_BASE = window.location.origin;

const CATEGORIES = [
  { key: 'observation', label: 'Observation', icon: '👁️', color: '#10b981' },
  { key: 'deployment', label: 'Deployment', icon: '📍', color: '#3b82f6' },
  { key: 'maintenance', label: 'Maintenance', icon: '🔧', color: '#f59e0b' },
  { key: 'collection', label: 'Collection', icon: '📦', color: '#8b5cf6' },
  { key: 'incident', label: 'Incident', icon: '⚠️', color: '#ef4444' },
];

function OrpheusJournal({ user, onLogout }) {
  const navigate = useNavigate();
  const [devices, setDevices] = useState([]);
  const [selectedDevice, setSelectedDevice] = useState('');
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(false);
  const [filterCat, setFilterCat] = useState('');

  // New entry form
  const [showForm, setShowForm] = useState(false);
  const [formCat, setFormCat] = useState('observation');
  const [formNote, setFormNote] = useState('');
  const [formWeather, setFormWeather] = useState('');
  const [formLocation, setFormLocation] = useState('');
  const [saving, setSaving] = useState(false);

  // Edit
  const [editId, setEditId] = useState(null);
  const [editNote, setEditNote] = useState('');
  const [editCat, setEditCat] = useState('');

  const headers = {
    'Authorization': `Bearer ${user?.token}`,
    'Content-Type': 'application/json',
  };

  const handleLogout = () => { onLogout(); navigate('/login'); };

  useEffect(() => {
    fetch(`${API_BASE}/api/orpheus/devices`, { headers })
      .then(r => r.ok ? r.json() : [])
      .then(data => {
        setDevices(data);
        if (data.length > 0 && !selectedDevice) setSelectedDevice(String(data[0].id));
      });
  }, []);

  const fetchEntries = useCallback(async () => {
    setLoading(true);
    const params = new URLSearchParams();
    if (filterCat) params.set('category', filterCat);
    if (selectedDevice) params.set('device_id', selectedDevice);
    try {
      const res = await fetch(`${API_BASE}/api/orpheus/journal?${params}`, { headers });
      if (res.ok) setEntries(await res.json());
    } catch (err) {
      console.error('Failed to fetch journal:', err);
    } finally {
      setLoading(false);
    }
  }, [selectedDevice, filterCat]);

  useEffect(() => { fetchEntries(); }, [fetchEntries]);

  const handleCreate = async () => {
    if (!formNote.trim()) return;
    setSaving(true);
    try {
      const res = await fetch(`${API_BASE}/api/orpheus/journal`, {
        method: 'POST', headers,
        body: JSON.stringify({
          device_id: selectedDevice ? Number(selectedDevice) : null,
          category: formCat,
          note: formNote.trim(),
          weather_note: formWeather.trim() || null,
          location_name: formLocation.trim() || null,
        }),
      });
      if (res.ok) {
        setFormNote(''); setFormWeather(''); setFormLocation('');
        setShowForm(false);
        fetchEntries();
      }
    } finally { setSaving(false); }
  };

  const handleUpdate = async (id) => {
    const res = await fetch(`${API_BASE}/api/orpheus/journal/${id}`, {
      method: 'PUT', headers,
      body: JSON.stringify({ note: editNote, category: editCat }),
    });
    if (res.ok) { setEditId(null); fetchEntries(); }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this journal entry?')) return;
    const res = await fetch(`${API_BASE}/api/orpheus/journal/${id}`, {
      method: 'DELETE', headers,
    });
    if (res.ok) fetchEntries();
  };

  const catInfo = (key) => CATEGORIES.find(c => c.key === key) || CATEGORIES[0];

  const formatDate = (ts) => {
    const d = new Date(ts);
    return d.toLocaleDateString('en-GB', { weekday: 'short', day: '2-digit', month: 'short', year: 'numeric' })
      + ' ' + d.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
  };

  return (
    <div className="dashboard-container">
      <aside className="sidebar">
        <div className="sidebar-header">
          <a href="/"><img src="/gaiaforge-logo.png" alt="GaiaForge" className="logo-image" /></a>
        </div>
        <nav className="sidebar-nav">
          <Link to="/orpheus" className="nav-item back-link">
            <span className="nav-icon">&larr;</span> Orpheus Portal
          </Link>
          <Link to="/orpheus/analytics" className="nav-item">
            <span className="nav-icon">📊</span> Analytics
          </Link>
          <Link to="/orpheus/journal" className="nav-item active">
            <span className="nav-icon">📝</span> Journal
          </Link>
          <Link to="/profile?from=orpheus" className="nav-item">
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
            <h1>Researcher Journal</h1>
            <p>Field notes, observations, and deployment records</p>
          </div>
          <div className="user-avatar">
            {user?.name?.charAt(0).toUpperCase() || 'U'}
          </div>
        </header>

        {/* Controls bar */}
        <div style={{ display: 'flex', gap: 12, marginBottom: 24, flexWrap: 'wrap', alignItems: 'center' }}>
          {devices.length > 1 && (
            <select value={selectedDevice} onChange={e => setSelectedDevice(e.target.value)}
              style={{ padding: '8px 12px', borderRadius: 8, border: '1px solid #d1d5db', fontSize: 13 }}>
              <option value="">All devices</option>
              {devices.map(d => (
                <option key={d.id} value={d.id}>{d.name || d.serial}</option>
              ))}
            </select>
          )}
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            <button onClick={() => setFilterCat('')}
              style={{
                padding: '6px 12px', borderRadius: 8, border: '1px solid #d1d5db', fontSize: 12,
                background: !filterCat ? '#1e40af' : '#fff', color: !filterCat ? '#fff' : '#374151',
                cursor: 'pointer', fontWeight: 600,
              }}>All</button>
            {CATEGORIES.map(c => (
              <button key={c.key} onClick={() => setFilterCat(c.key)}
                style={{
                  padding: '6px 12px', borderRadius: 8, border: `1px solid ${c.color}`, fontSize: 12,
                  background: filterCat === c.key ? c.color : '#fff',
                  color: filterCat === c.key ? '#fff' : c.color,
                  cursor: 'pointer', fontWeight: 600,
                }}>{c.icon} {c.label}</button>
            ))}
          </div>
          <button onClick={() => setShowForm(!showForm)}
            style={{
              marginLeft: 'auto', padding: '8px 20px', borderRadius: 8, border: 'none',
              background: showForm ? '#6b7280' : '#10b981', color: '#fff',
              cursor: 'pointer', fontWeight: 600, fontSize: 13,
            }}>{showForm ? 'Cancel' : '+ New Entry'}</button>
        </div>

        {/* New entry form */}
        {showForm && (
          <div className="admin-card" style={{ marginBottom: 24 }}>
            <h3 style={{ margin: '0 0 16px' }}>New Journal Entry</h3>
            <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginBottom: 16 }}>
              {CATEGORIES.map(c => (
                <button key={c.key} onClick={() => setFormCat(c.key)}
                  style={{
                    padding: '8px 16px', borderRadius: 8, border: `2px solid ${c.color}`, fontSize: 13,
                    background: formCat === c.key ? c.color : '#fff',
                    color: formCat === c.key ? '#fff' : c.color,
                    cursor: 'pointer', fontWeight: 600,
                  }}>{c.icon} {c.label}</button>
              ))}
            </div>
            <textarea value={formNote} onChange={e => setFormNote(e.target.value)}
              placeholder="Write your field note here..."
              rows={4} style={{
                width: '100%', padding: 12, borderRadius: 10, border: '2px solid #e5e7eb',
                fontSize: 14, resize: 'vertical', marginBottom: 12,
              }} />
            <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginBottom: 16 }}>
              <input type="text" value={formLocation} onChange={e => setFormLocation(e.target.value)}
                placeholder="Location (e.g. Schlammwiss North)"
                style={{ flex: 1, minWidth: 200, padding: '10px 14px', borderRadius: 10, border: '2px solid #e5e7eb', fontSize: 14 }} />
              <input type="text" value={formWeather} onChange={e => setFormWeather(e.target.value)}
                placeholder="Weather (e.g. Overcast, 12C, light wind)"
                style={{ flex: 1, minWidth: 200, padding: '10px 14px', borderRadius: 10, border: '2px solid #e5e7eb', fontSize: 14 }} />
            </div>
            <button onClick={handleCreate} disabled={saving || !formNote.trim()}
              style={{
                padding: '10px 24px', borderRadius: 10, border: 'none',
                background: '#10b981', color: '#fff', cursor: 'pointer',
                fontWeight: 600, fontSize: 14, opacity: saving || !formNote.trim() ? 0.5 : 1,
              }}>{saving ? 'Saving...' : 'Save Entry'}</button>
          </div>
        )}

        {/* Entries list */}
        {loading ? (
          <div className="loading-state">Loading journal entries...</div>
        ) : entries.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">📝</div>
            <h2>No journal entries yet</h2>
            <p>Click "+ New Entry" to record your first field observation.</p>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            {entries.map(entry => {
              const cat = catInfo(entry.category);
              const isEditing = editId === entry.id;
              return (
                <div key={entry.id} className="admin-card" style={{ borderLeft: `4px solid ${cat.color}` }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 8 }}>
                    <div>
                      <span style={{
                        padding: '2px 10px', borderRadius: 6, fontSize: 11, fontWeight: 700,
                        background: cat.color + '20', color: cat.color,
                      }}>{cat.icon} {cat.label}</span>
                      {entry.device_name && (
                        <span style={{ marginLeft: 8, fontSize: 12, color: '#6b7280' }}>
                          {entry.device_name}
                        </span>
                      )}
                      {entry.location_name && (
                        <span style={{ marginLeft: 8, fontSize: 12, color: '#9ca3af' }}>
                          — {entry.location_name}
                        </span>
                      )}
                    </div>
                    <div style={{ display: 'flex', gap: 6, flexShrink: 0 }}>
                      <button onClick={() => {
                        if (isEditing) { setEditId(null); }
                        else { setEditId(entry.id); setEditNote(entry.note); setEditCat(entry.category); }
                      }} style={{
                        background: 'none', border: 'none', cursor: 'pointer', fontSize: 14, color: '#6b7280',
                      }}>{isEditing ? 'Cancel' : 'Edit'}</button>
                      <button onClick={() => handleDelete(entry.id)}
                        style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 14, color: '#ef4444' }}>
                        Delete
                      </button>
                    </div>
                  </div>

                  {isEditing ? (
                    <div>
                      <div style={{ display: 'flex', gap: 6, marginBottom: 8, flexWrap: 'wrap' }}>
                        {CATEGORIES.map(c => (
                          <button key={c.key} onClick={() => setEditCat(c.key)}
                            style={{
                              padding: '4px 10px', borderRadius: 6, border: `1px solid ${c.color}`, fontSize: 11,
                              background: editCat === c.key ? c.color : '#fff',
                              color: editCat === c.key ? '#fff' : c.color,
                              cursor: 'pointer', fontWeight: 600,
                            }}>{c.icon} {c.label}</button>
                        ))}
                      </div>
                      <textarea value={editNote} onChange={e => setEditNote(e.target.value)}
                        rows={3} style={{
                          width: '100%', padding: 10, borderRadius: 8, border: '2px solid #e5e7eb',
                          fontSize: 14, resize: 'vertical', marginBottom: 8,
                        }} />
                      <button onClick={() => handleUpdate(entry.id)}
                        style={{
                          padding: '6px 16px', borderRadius: 8, border: 'none',
                          background: '#10b981', color: '#fff', cursor: 'pointer', fontWeight: 600, fontSize: 13,
                        }}>Save</button>
                    </div>
                  ) : (
                    <p style={{ fontSize: 14, lineHeight: 1.6, color: '#374151', margin: '8px 0', whiteSpace: 'pre-wrap' }}>
                      {entry.note}
                    </p>
                  )}

                  <div style={{ display: 'flex', gap: 16, fontSize: 12, color: '#9ca3af', marginTop: 8 }}>
                    <span>{formatDate(entry.timestamp)}</span>
                    {entry.author_name && <span>by {entry.author_name}</span>}
                    {entry.weather_note && <span>{entry.weather_note}</span>}
                    {entry.temperature != null && <span>{entry.temperature}°C</span>}
                    {entry.humidity != null && <span>{entry.humidity}%</span>}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </main>
    </div>
  );
}

export default OrpheusJournal;
