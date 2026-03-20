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
  const [editingId, setEditingId] = useState(null);
  const [editValues, setEditValues] = useState({});
  const [deleteModal, setDeleteModal] = useState(null); // { hive, mode: 'hive'|'data', before: '' }
  const [actionMsg, setActionMsg] = useState('');
  const [previewCount, setPreviewCount] = useState(null);

  const headers = {
    'Authorization': `Bearer ${user?.token}`,
    'Content-Type': 'application/json',
  };

  useEffect(() => { fetchHives(); }, []);

  const fetchHives = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/api/hives`, { headers });
      if (res.ok) setHives(await res.json());
    } catch (err) {
      console.error('Failed to fetch hives:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleAddHive = async (e) => {
    e.preventDefault();
    setError('');
    if (!newHive.name) { setError('Hive name is required'); return; }
    const res = await fetch(`${API_BASE}/api/hives`, {
      method: 'POST', headers, body: JSON.stringify(newHive),
    });
    if (res.ok) {
      setNewHive({ name: '', location: '' });
      setShowAdd(false);
      fetchHives();
    } else {
      const d = await res.json().catch(() => ({}));
      setError(d.detail || 'Failed to add hive');
    }
  };

  const startEdit = (hive) => {
    setEditingId(hive.id);
    setEditValues({ name: hive.name, location: hive.location || '' });
  };

  const saveEdit = async (hiveId) => {
    const res = await fetch(`${API_BASE}/api/hives/${hiveId}`, {
      method: 'PATCH', headers, body: JSON.stringify(editValues),
    });
    if (res.ok) { setEditingId(null); fetchHives(); }
  };

  const toggleArchive = async (hive) => {
    await fetch(`${API_BASE}/api/hives/${hive.id}`, {
      method: 'PATCH', headers,
      body: JSON.stringify({ is_archived: !hive.is_archived }),
    });
    fetchHives();
  };

  const confirmDeleteHive = async () => {
    const res = await fetch(`${API_BASE}/api/hives/${deleteModal.hive.id}`, {
      method: 'DELETE', headers,
    });
    setDeleteModal(null);
    if (res.ok) { setActionMsg('Hive deleted.'); fetchHives(); }
  };

  const previewDataDelete = async () => {
    const { hive, before } = deleteModal;
    const url = before
      ? `${API_BASE}/api/hives/${hive.id}/readings/count?before=${encodeURIComponent(before)}`
      : `${API_BASE}/api/hives/${hive.id}/readings/count`;
    const res = await fetch(url, { headers });
    if (res.ok) { const d = await res.json(); setPreviewCount(d.count); }
  };

  const confirmDeleteData = async () => {
    const { hive, before } = deleteModal;
    const url = before
      ? `${API_BASE}/api/hives/${hive.id}/readings?before=${encodeURIComponent(before)}`
      : `${API_BASE}/api/hives/${hive.id}/readings`;
    const res = await fetch(url, { method: 'DELETE', headers });
    if (res.ok) {
      const d = await res.json();
      setDeleteModal(null);
      setPreviewCount(null);
      setActionMsg(`Deleted ${d.deleted} readings.`);
      fetchHives();
    }
  };

  const handleLogout = () => { onLogout(); navigate('/login'); };

  const sidebarNav = (
    <nav className="sidebar-nav">
      <a href="/" className="nav-item back-link"><span className="nav-icon">←</span> Back to Site</a>
      <Link to="/dashboard" className="nav-item"><span className="nav-icon">📊</span> Dashboard</Link>
      <Link to="/analytics" className="nav-item"><span className="nav-icon">🔬</span> Analytics</Link>
      <Link to="/upload" className="nav-item"><span className="nav-icon">⬆️</span> Upload Data</Link>
      <Link to="/devices" className="nav-item active"><span className="nav-icon">📟</span> My Hives</Link>
      <Link to="/alerts" className="nav-item"><span className="nav-icon">🔔</span> Alerts</Link>
      <Link to="/profile" className="nav-item"><span className="nav-icon">👤</span> Profile</Link>
      {user?.is_admin && <Link to="/admin" className="nav-item"><span className="nav-icon">⚙️</span> Admin</Link>}
    </nav>
  );

  return (
    <div className="dashboard-container">
      <aside className="sidebar">
        <div className="sidebar-header">
          <a href="/"><img src="/gaiaforge-logo.png" alt="GaiaForge" className="logo-image" /></a>
        </div>
        {sidebarNav}
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
          <button onClick={() => setShowAdd(!showAdd)} style={{
            padding: '10px 20px', background: '#f59e0b', color: '#fff',
            border: 'none', borderRadius: '10px', fontWeight: 600, cursor: 'pointer',
          }}>+ Add Hive</button>
        </header>

        {actionMsg && (
          <div style={{
            background: '#d1fae5', color: '#065f46', padding: '10px 16px',
            borderRadius: '8px', marginBottom: '16px', fontSize: '14px',
          }}>{actionMsg} <button onClick={() => setActionMsg('')} style={{
            marginLeft: '12px', background: 'none', border: 'none', cursor: 'pointer', color: '#065f46', fontWeight: 700,
          }}>✕</button></div>
        )}

        {showAdd && (
          <div className="device-selector" style={{ marginBottom: '24px' }}>
            <h3>Add New Hive</h3>
            {error && <div style={{
              background: '#fef2f2', color: '#dc2626', padding: '10px 14px',
              borderRadius: '8px', marginBottom: '12px', fontSize: '14px',
            }}>{error}</div>}
            <form onSubmit={handleAddHive}>
              <div className="form-group" style={{ marginBottom: '14px' }}>
                <label>Hive Name</label>
                <input type="text" value={newHive.name}
                  onChange={e => setNewHive({ ...newHive, name: e.target.value })}
                  placeholder="e.g. Backyard Hive #1"
                  style={{ padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%' }} />
              </div>
              <div className="form-group" style={{ marginBottom: '14px' }}>
                <label>Location (optional)</label>
                <input type="text" value={newHive.location}
                  onChange={e => setNewHive({ ...newHive, location: e.target.value })}
                  placeholder="e.g. South field"
                  style={{ padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%' }} />
              </div>
              <button type="submit" style={{
                padding: '12px 24px', background: '#10b981', color: '#fff',
                border: 'none', borderRadius: '10px', fontWeight: 600, cursor: 'pointer',
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
              <div key={hive.id} className="upload-row" style={{
                opacity: hive.is_archived ? 0.6 : 1,
                flexDirection: 'column', alignItems: 'stretch', gap: '12px',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <div className="upload-icon">🐝</div>
                  <div style={{ flex: 1 }}>
                    {editingId === hive.id ? (
                      <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                        <input value={editValues.name}
                          onChange={e => setEditValues({ ...editValues, name: e.target.value })}
                          style={{ padding: '6px 10px', border: '2px solid #f59e0b', borderRadius: '8px', fontWeight: 600 }} />
                        <input value={editValues.location}
                          onChange={e => setEditValues({ ...editValues, location: e.target.value })}
                          placeholder="location"
                          style={{ padding: '6px 10px', border: '2px solid #e5e7eb', borderRadius: '8px' }} />
                        <button onClick={() => saveEdit(hive.id)} style={{
                          padding: '6px 14px', background: '#10b981', color: '#fff',
                          border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 600,
                        }}>Save</button>
                        <button onClick={() => setEditingId(null)} style={{
                          padding: '6px 14px', background: '#e5e7eb', color: '#374151',
                          border: 'none', borderRadius: '8px', cursor: 'pointer',
                        }}>Cancel</button>
                      </div>
                    ) : (
                      <>
                        <div className="upload-name">{hive.name}
                          {hive.is_archived && <span style={{
                            marginLeft: '8px', fontSize: '11px', background: '#fef3c7',
                            color: '#92400e', padding: '2px 8px', borderRadius: '10px',
                          }}>Archived</span>}
                        </div>
                        <div className="upload-meta">
                          {hive.location || 'No location'} · {hive.reading_count.toLocaleString()} readings
                        </div>
                      </>
                    )}
                  </div>
                  <div style={{ display: 'flex', gap: '8px', flexShrink: 0 }}>
                    <button onClick={() => startEdit(hive)} title="Rename" style={{
                      padding: '6px 10px', background: '#f3f4f6', border: 'none',
                      borderRadius: '8px', cursor: 'pointer', fontSize: '14px',
                    }}>✏️</button>
                    <button onClick={() => toggleArchive(hive)} title={hive.is_archived ? 'Unarchive' : 'Archive'} style={{
                      padding: '6px 10px', background: hive.is_archived ? '#d1fae5' : '#fef3c7',
                      color: hive.is_archived ? '#065f46' : '#92400e',
                      border: 'none', borderRadius: '8px', cursor: 'pointer', fontSize: '13px', fontWeight: 600,
                    }}>{hive.is_archived ? 'Unarchive' : 'Archive'}</button>
                    <button onClick={() => { setDeleteModal({ hive, mode: 'data', before: '' }); setPreviewCount(null); }}
                      title="Delete readings" style={{
                        padding: '6px 10px', background: '#fef2f2', color: '#dc2626',
                        border: 'none', borderRadius: '8px', cursor: 'pointer', fontSize: '13px', fontWeight: 600,
                      }}>Clear Data</button>
                    <button onClick={() => setDeleteModal({ hive, mode: 'hive' })}
                      title="Delete hive" style={{
                        padding: '6px 10px', background: '#dc2626', color: '#fff',
                        border: 'none', borderRadius: '8px', cursor: 'pointer', fontSize: '13px', fontWeight: 600,
                      }}>Delete</button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>

      {/* Delete Hive Modal */}
      {deleteModal?.mode === 'hive' && (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000,
        }}>
          <div style={{
            background: '#fff', borderRadius: '16px', padding: '32px',
            maxWidth: '420px', width: '90%', boxShadow: '0 20px 60px rgba(0,0,0,0.3)',
          }}>
            <h2 style={{ color: '#dc2626', marginBottom: '12px' }}>Delete Hive?</h2>
            <p style={{ color: '#374151', marginBottom: '24px' }}>
              This will permanently delete <strong>{deleteModal.hive.name}</strong> and all its readings
              ({deleteModal.hive.reading_count.toLocaleString()} records). This cannot be undone.
            </p>
            <div style={{ display: 'flex', gap: '12px' }}>
              <button onClick={confirmDeleteHive} style={{
                flex: 1, padding: '12px', background: '#dc2626', color: '#fff',
                border: 'none', borderRadius: '10px', fontWeight: 700, cursor: 'pointer',
              }}>Yes, Delete Everything</button>
              <button onClick={() => setDeleteModal(null)} style={{
                flex: 1, padding: '12px', background: '#f3f4f6', color: '#374151',
                border: 'none', borderRadius: '10px', fontWeight: 600, cursor: 'pointer',
              }}>Cancel</button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Data Modal */}
      {deleteModal?.mode === 'data' && (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000,
        }}>
          <div style={{
            background: '#fff', borderRadius: '16px', padding: '32px',
            maxWidth: '460px', width: '90%', boxShadow: '0 20px 60px rgba(0,0,0,0.3)',
          }}>
            <h2 style={{ color: '#dc2626', marginBottom: '8px' }}>Clear Readings</h2>
            <p style={{ color: '#6b7280', marginBottom: '20px', fontSize: '14px' }}>
              <strong>{deleteModal.hive.name}</strong> has {deleteModal.hive.reading_count.toLocaleString()} readings.
              Optionally enter a cutoff date to delete only older records.
            </p>
            <div className="form-group" style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', marginBottom: '6px', fontWeight: 600, fontSize: '14px' }}>
                Delete readings before (leave blank to delete all)
              </label>
              <input type="datetime-local"
                value={deleteModal.before}
                onChange={e => { setDeleteModal({ ...deleteModal, before: e.target.value }); setPreviewCount(null); }}
                style={{ padding: '10px', border: '2px solid #e5e7eb', borderRadius: '8px', width: '100%' }} />
            </div>
            {previewCount !== null && (
              <div style={{
                background: '#fef2f2', color: '#dc2626', padding: '10px 14px',
                borderRadius: '8px', marginBottom: '16px', fontSize: '14px', fontWeight: 600,
              }}>
                {previewCount === 0 ? 'No readings match this criteria.' : `This will delete ${previewCount.toLocaleString()} readings.`}
              </div>
            )}
            <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
              <button onClick={previewDataDelete} style={{
                padding: '10px 16px', background: '#f3f4f6', color: '#374151',
                border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 600, fontSize: '13px',
              }}>Preview Count</button>
              <button onClick={confirmDeleteData} style={{
                padding: '10px 16px', background: '#dc2626', color: '#fff',
                border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 700, fontSize: '13px',
              }}>Delete Readings</button>
              <button onClick={() => { setDeleteModal(null); setPreviewCount(null); }} style={{
                padding: '10px 16px', background: '#e5e7eb', color: '#374151',
                border: 'none', borderRadius: '8px', cursor: 'pointer', fontSize: '13px',
              }}>Cancel</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Devices;
