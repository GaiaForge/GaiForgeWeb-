import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Dashboard.css';
import './Admin.css';

const API_BASE = window.location.origin;

function Admin({ user, onLogout }) {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('overview');
  const [stats, setStats] = useState(null);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [apiKey, setApiKey] = useState('');
  const [keySaving, setKeySaving] = useState(false);
  const [keyMessage, setKeyMessage] = useState(null);
  const [subEdit, setSubEdit] = useState(null); // { userId, tier, expires, notes }

  // Audit log
  const [auditLogs, setAuditLogs] = useState([]);
  const [auditLoading, setAuditLoading] = useState(false);
  const [auditFilter, setAuditFilter] = useState('');

  // Serials
  const [allSerials, setAllSerials] = useState([]);

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
      const [statsRes, usersRes, hivesRes, serialsRes] = await Promise.all([
        fetch(`${API_BASE}/api/admin/stats`, { headers }),
        fetch(`${API_BASE}/api/admin/users`, { headers }),
        fetch(`${API_BASE}/api/admin/hives`, { headers }),
        fetch(`${API_BASE}/api/admin/serials`, { headers }),
      ]);

      if (statsRes.status === 403 || usersRes.status === 403) {
        setError('Admin access required.');
        setLoading(false);
        return;
      }

      if (statsRes.ok) setStats(await statsRes.json());
      if (usersRes.ok) setUsers(await usersRes.json());
      if (hivesRes.ok) setAllHives(await hivesRes.json());
      if (serialsRes.ok) setAllSerials(await serialsRes.json());
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

  const saveSubEdit = async () => {
    const { userId, tier, expires, notes } = subEdit;
    try {
      const res = await fetch(`${API_BASE}/api/admin/users/${userId}/subscription`, {
        method: 'PUT',
        headers,
        body: JSON.stringify({
          subscription_tier: tier,
          subscription_expires_at: expires || '',
          subscription_notes: notes,
        }),
      });
      if (res.ok) {
        setUsers(users.map(u =>
          u.id === userId ? { ...u, subscription_tier: tier, subscription_expires_at: expires || null, subscription_notes: notes } : u
        ));
        setSubEdit(null);
      }
    } catch (err) {
      console.error('Failed to save subscription:', err);
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

  const fetchAuditLog = async (action) => {
    setAuditLoading(true);
    try {
      const params = new URLSearchParams({ limit: '200' });
      if (action) params.set('action', action);
      const res = await fetch(`${API_BASE}/api/admin/audit-log?${params}`, { headers });
      if (res.ok) setAuditLogs(await res.json());
    } catch {} finally { setAuditLoading(false); }
  };

  const exportUserData = async (userId) => {
    try {
      const res = await fetch(`${API_BASE}/api/admin/users/${userId}/export`, { headers });
      if (res.ok) {
        const blob = await res.blob();
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `user_${userId}_data_export.csv`;
        a.click();
        URL.revokeObjectURL(url);
      }
    } catch {}
  };

  const deleteUserData = async (userId, email) => {
    if (!window.confirm(`GDPR Erasure: This will permanently delete ALL data for ${email} including hives, readings, and their account. This cannot be undone. Continue?`)) return;
    try {
      const res = await fetch(`${API_BASE}/api/admin/users/${userId}/data`, { method: 'DELETE', headers });
      if (res.ok) {
        fetchData();
        alert(`All data for ${email} has been deleted.`);
      } else {
        const err = await res.json().catch(() => ({}));
        alert(err.detail || 'Deletion failed');
      }
    } catch { alert('Connection error'); }
  };

  const handleLogout = () => { onLogout(); navigate('/login'); };

  return (
    <div className="dashboard-container">
      <aside className="sidebar">
        <div className="sidebar-header">
          <a href="/"><img src="/gaiaforge-logo.png" alt="GaiaForge" className="logo-image" /></a>
        </div>
        <nav className="sidebar-nav">
          <Link to="/products" className="nav-item back-link">
            <span className="nav-icon">&larr;</span> Products
          </Link>
          <button className={`nav-item nav-btn ${activeTab === 'overview' ? 'active' : ''}`}
            onClick={() => setActiveTab('overview')}>
            <span className="nav-icon">📊</span> Overview
          </button>
          <button className={`nav-item nav-btn ${activeTab === 'users' ? 'active' : ''}`}
            onClick={() => setActiveTab('users')}>
            <span className="nav-icon">👥</span> Users
          </button>
          <button className={`nav-item nav-btn ${activeTab === 'serials' ? 'active' : ''}`}
            onClick={() => setActiveTab('serials')}>
            <span className="nav-icon">📟</span> Device Serials
          </button>
          <button className={`nav-item nav-btn ${activeTab === 'data' ? 'active' : ''}`}
            onClick={() => setActiveTab('data')}>
            <span className="nav-icon">🗄️</span> Data Management
          </button>
          <button className={`nav-item nav-btn ${activeTab === 'audit' ? 'active' : ''}`}
            onClick={() => setActiveTab('audit')}>
            <span className="nav-icon">🔒</span> Audit Log
          </button>
          <button className={`nav-item nav-btn ${activeTab === 'config' ? 'active' : ''}`}
            onClick={() => setActiveTab('config')}>
            <span className="nav-icon">⚙️</span> Config
          </button>
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
            {/* ==================== OVERVIEW TAB ==================== */}
            {activeTab === 'overview' && stats && (
              <>
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
                      <div className="stat-label">HiveGuard Hives</div>
                    </div>
                  </div>
                  <div className="stat-card">
                    <div className="stat-icon">🔊</div>
                    <div className="stat-content">
                      <div className="stat-value">{stats.total_orpheus_devices || 0}</div>
                      <div className="stat-label">Orpheus Devices</div>
                    </div>
                  </div>
                  <div className="stat-card">
                    <div className="stat-icon">🌱</div>
                    <div className="stat-content">
                      <div className="stat-value">—</div>
                      <div className="stat-label">SprigRig Devices</div>
                    </div>
                  </div>
                  <div className="stat-card">
                    <div className="stat-icon">📊</div>
                    <div className="stat-content">
                      <div className="stat-value">{stats.total_readings.toLocaleString()}</div>
                      <div className="stat-label">HiveGuard Readings</div>
                    </div>
                  </div>
                </div>

                {/* Quick user summary */}
                <div className="admin-card" style={{marginTop:'24px'}}>
                  <h3>Recent Users</h3>
                  <div style={{overflowX:'auto'}}>
                    <table className="admin-table" style={{fontSize:'13px'}}>
                      <thead>
                        <tr>
                          <th>User</th>
                          <th>Products</th>
                          <th>Joined</th>
                          <th>Status</th>
                        </tr>
                      </thead>
                      <tbody>
                        {users.slice(0, 10).map(u => (
                          <tr key={u.id}>
                            <td>
                              <div className="user-cell">
                                <div className="user-mini-avatar">{u.name.charAt(0).toUpperCase()}</div>
                                {u.name}
                                {u.id === 1 && <span className="admin-tag">admin</span>}
                              </div>
                            </td>
                            <td>
                              {(u.products || []).length > 0 ? (
                                <div style={{display:'flex', gap:'4px', flexWrap:'wrap'}}>
                                  {u.products.map(p => (
                                    <span key={p} style={{
                                      padding:'2px 8px', borderRadius:'4px', fontSize:'11px', fontWeight:600,
                                      background: p === 'orpheus' ? '#dbeafe' : p === 'hiveguard' ? '#fef3c7' : '#dcfce7',
                                      color: p === 'orpheus' ? '#1e40af' : p === 'hiveguard' ? '#92400e' : '#166534',
                                    }}>{p}</span>
                                  ))}
                                </div>
                              ) : <span style={{color:'#9ca3af', fontSize:'12px'}}>none</span>}
                            </td>
                            <td>{new Date(u.created_at).toLocaleDateString()}</td>
                            <td>
                              <span className={`status-dot ${u.is_active ? 'active' : 'inactive'}`}></span>
                              {u.is_active ? 'Active' : 'Disabled'}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              </>
            )}

            {/* ==================== USERS TAB ==================== */}
            {activeTab === 'users' && (
              <div className="admin-card">
                <h3>User Management</h3>
                <div style={{overflowX:'auto'}}>
                  <table className="admin-table">
                    <thead>
                      <tr>
                        <th>User</th>
                        <th>Email</th>
                        <th>Joined</th>
                        <th>Devices &amp; Serials</th>
                        <th>Subscription</th>
                        <th>Status</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {users.map(u => (
                        <React.Fragment key={u.id}>
                        <tr className={!u.is_active ? 'row-inactive' : ''}>
                          <td>
                            <div className="user-cell">
                              <div className="user-mini-avatar">{u.name.charAt(0).toUpperCase()}</div>
                              {u.name}
                              {u.id === 1 && <span className="admin-tag">admin</span>}
                            </div>
                          </td>
                          <td>{u.email}</td>
                          <td>{new Date(u.created_at).toLocaleDateString()}</td>
                          <td>
                            <div style={{fontSize:'12px'}}>
                              {(u.serials || []).length > 0 ? (
                                u.serials.map((s, i) => (
                                  <div key={i} style={{marginBottom:'4px'}}>
                                    <span style={{
                                      padding:'1px 6px', borderRadius:'3px', fontSize:'10px', fontWeight:600, marginRight:'4px',
                                      background: s.product === 'orpheus' ? '#dbeafe' : s.product === 'hiveguard' ? '#fef3c7' : '#dcfce7',
                                      color: s.product === 'orpheus' ? '#1e40af' : s.product === 'hiveguard' ? '#92400e' : '#166534',
                                    }}>{s.product}</span>
                                    <code style={{fontSize:'11px', color:'#374151'}}>{s.serial}</code>
                                    {s.claimed_at && (
                                      <span style={{fontSize:'10px', color:'#9ca3af', marginLeft:'6px'}}>
                                        reg {new Date(s.claimed_at).toLocaleDateString()}
                                      </span>
                                    )}
                                  </div>
                                ))
                              ) : <span style={{color:'#9ca3af'}}>no devices</span>}
                              {u.hive_count > 0 && <div style={{marginTop:'4px', color:'#6b7280'}}>{u.hive_count} hive{u.hive_count !== 1 ? 's' : ''} &middot; {u.reading_count.toLocaleString()} readings</div>}
                            </div>
                          </td>
                          <td>
                            <span className={`tier-badge ${u.subscription_tier}`}>{u.subscription_tier}</span>
                            {u.subscription_tier === 'pro' && u.subscription_expires_at && (
                              <div style={{fontSize:'11px', color:'#6b7280', marginTop:'3px'}}>
                                Expires {new Date(u.subscription_expires_at).toLocaleDateString()}
                              </div>
                            )}
                            {u.subscription_notes && (
                              <div style={{fontSize:'11px', color:'#9ca3af', marginTop:'2px', fontStyle:'italic'}}>
                                {u.subscription_notes}
                              </div>
                            )}
                          </td>
                          <td>
                            <span className={`status-dot ${u.is_active ? 'active' : 'inactive'}`}></span>
                            {u.is_active ? 'Active' : 'Disabled'}
                          </td>
                          <td>
                            <div className="action-buttons">
                              <button
                                className="btn-small btn-tier"
                                onClick={() => setSubEdit({
                                  userId: u.id,
                                  tier: u.subscription_tier,
                                  expires: u.subscription_expires_at ? u.subscription_expires_at.slice(0,10) : '',
                                  notes: u.subscription_notes || '',
                                })}
                              >
                                Edit Sub
                              </button>
                              <button className="btn-small" onClick={() => exportUserData(u.id)}
                                style={{background:'#3b82f6',color:'#fff',border:'none',borderRadius:'6px',padding:'4px 10px',fontSize:'12px',cursor:'pointer'}}>
                                Export
                              </button>
                              {u.id !== 1 && (
                                <>
                                <button className="btn-small btn-toggle" onClick={() => toggleActive(u.id)}>
                                  {u.is_active ? 'Disable' : 'Enable'}
                                </button>
                                <button className="btn-small" onClick={() => deleteUserData(u.id, u.email)}
                                  style={{background:'#ef4444',color:'#fff',border:'none',borderRadius:'6px',padding:'4px 10px',fontSize:'12px',cursor:'pointer'}}>
                                  Erase
                                </button>
                                </>
                              )}
                            </div>
                          </td>
                        </tr>
                        {subEdit?.userId === u.id && (
                          <tr>
                            <td colSpan="7" style={{background:'#fef3c7', padding:'16px 20px'}}>
                              <div style={{display:'flex', gap:'12px', flexWrap:'wrap', alignItems:'flex-end'}}>
                                <div>
                                  <label style={{display:'block', fontSize:'12px', fontWeight:600, marginBottom:'4px'}}>Tier</label>
                                  <select value={subEdit.tier} onChange={e => setSubEdit({...subEdit, tier: e.target.value})}
                                    style={{padding:'8px 12px', border:'2px solid #e5e7eb', borderRadius:'8px'}}>
                                    <option value="free">Free</option>
                                    <option value="pro">Pro</option>
                                  </select>
                                </div>
                                <div>
                                  <label style={{display:'block', fontSize:'12px', fontWeight:600, marginBottom:'4px'}}>Expires (blank = forever)</label>
                                  <input type="date" value={subEdit.expires}
                                    onChange={e => setSubEdit({...subEdit, expires: e.target.value})}
                                    style={{padding:'8px 12px', border:'2px solid #e5e7eb', borderRadius:'8px'}} />
                                </div>
                                <div style={{flex:1, minWidth:'200px'}}>
                                  <label style={{display:'block', fontSize:'12px', fontWeight:600, marginBottom:'4px'}}>Notes (payment ref, etc.)</label>
                                  <input type="text" value={subEdit.notes}
                                    onChange={e => setSubEdit({...subEdit, notes: e.target.value})}
                                    placeholder="e.g. Paid via PayPal 2026-03-20"
                                    style={{padding:'8px 12px', border:'2px solid #e5e7eb', borderRadius:'8px', width:'100%'}} />
                                </div>
                                <button onClick={saveSubEdit}
                                  style={{padding:'8px 18px', background:'#10b981', color:'#fff', border:'none', borderRadius:'8px', fontWeight:700, cursor:'pointer'}}>
                                  Save
                                </button>
                                <button onClick={() => setSubEdit(null)}
                                  style={{padding:'8px 14px', background:'#e5e7eb', color:'#374151', border:'none', borderRadius:'8px', cursor:'pointer'}}>
                                  Cancel
                                </button>
                              </div>
                            </td>
                          </tr>
                        )}
                        </React.Fragment>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* ==================== SERIALS TAB ==================== */}
            {activeTab === 'serials' && (
              <div className="admin-card">
                <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:'16px'}}>
                  <div>
                    <h3 style={{margin:0}}>Device Serials</h3>
                    <p style={{fontSize:'13px', color:'#6b7280', marginTop:'4px'}}>
                      {allSerials.length} total &middot; {allSerials.filter(s => s.claimed_by).length} claimed &middot; {allSerials.filter(s => !s.claimed_by).length} available
                    </p>
                  </div>
                </div>
                <div style={{overflowX:'auto'}}>
                  <table className="admin-table" style={{fontSize:'13px'}}>
                    <thead>
                      <tr>
                        <th>Product</th>
                        <th>Serial</th>
                        <th>Status</th>
                        <th>Customer</th>
                        <th>Notes</th>
                        <th>Added</th>
                      </tr>
                    </thead>
                    <tbody>
                      {allSerials.length === 0 ? (
                        <tr><td colSpan="6" style={{color:'#9ca3af', textAlign:'center', padding:'24px'}}>No device serials registered yet.</td></tr>
                      ) : (
                        allSerials.map(s => {
                          const claimedUser = s.claimed_by ? users.find(u => u.id === s.claimed_by) : null;
                          return (
                            <tr key={s.id}>
                              <td>
                                <span style={{
                                  padding:'2px 8px', borderRadius:'4px', fontSize:'11px', fontWeight:600,
                                  background: s.product === 'orpheus' ? '#dbeafe' : s.product === 'hiveguard' ? '#fef3c7' : '#dcfce7',
                                  color: s.product === 'orpheus' ? '#1e40af' : s.product === 'hiveguard' ? '#92400e' : '#166534',
                                }}>{s.product}</span>
                              </td>
                              <td><code style={{fontSize:'12px'}}>{s.serial}</code></td>
                              <td>
                                {s.claimed_by ? (
                                  <span style={{color:'#10b981', fontWeight:600, fontSize:'12px'}}>Claimed</span>
                                ) : (
                                  <span style={{color:'#f59e0b', fontWeight:600, fontSize:'12px'}}>Available</span>
                                )}
                              </td>
                              <td>
                                {claimedUser ? (
                                  <div>
                                    <div>{claimedUser.name}</div>
                                    <div style={{fontSize:'11px', color:'#9ca3af'}}>{claimedUser.email}</div>
                                    {s.claimed_at && <div style={{fontSize:'10px', color:'#9ca3af'}}>claimed {new Date(s.claimed_at).toLocaleDateString()}</div>}
                                  </div>
                                ) : <span style={{color:'#9ca3af'}}>—</span>}
                              </td>
                              <td style={{fontSize:'12px', color:'#6b7280', maxWidth:'250px'}}>{s.notes || '—'}</td>
                              <td style={{fontSize:'12px', color:'#9ca3af'}}>{new Date(s.created_at).toLocaleDateString()}</td>
                            </tr>
                          );
                        })
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* ==================== DATA MANAGEMENT TAB ==================== */}
            {activeTab === 'data' && (
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
            )}

            {/* ==================== AUDIT LOG TAB ==================== */}
            {activeTab === 'audit' && (
              <div className="admin-card">
                <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:'16px'}}>
                  <h3 style={{margin:0}}>Security Audit Log</h3>
                  <div style={{display:'flex', gap:'8px', alignItems:'center'}}>
                    <select value={auditFilter} onChange={e => setAuditFilter(e.target.value)}
                      style={{padding:'8px 12px', border:'2px solid #e5e7eb', borderRadius:'8px', fontSize:'13px'}}>
                      <option value="">All actions</option>
                      <option value="login">Logins</option>
                      <option value="login_failed">Failed logins</option>
                      <option value="register">Registrations</option>
                      <option value="change_password">Password changes</option>
                      <option value="change_password_failed">Failed password changes</option>
                      <option value="forgot_password">Password resets</option>
                      <option value="reset_password">Password reset completions</option>
                      <option value="change_email">Email changes</option>
                      <option value="delete_account">Account deletions</option>
                      <option value="regenerate_api_key">API key regenerations</option>
                    </select>
                    <button onClick={() => fetchAuditLog(auditFilter)}
                      style={{padding:'8px 16px', background:'#f59e0b', color:'#fff', border:'none', borderRadius:'8px', fontWeight:600, cursor:'pointer', fontSize:'13px'}}>
                      {auditLoading ? 'Loading...' : 'Load Log'}
                    </button>
                  </div>
                </div>
                {auditLogs.length > 0 ? (
                  <div style={{maxHeight:'600px', overflowY:'auto'}}>
                    <table className="admin-table" style={{fontSize:'13px'}}>
                      <thead>
                        <tr>
                          <th>Time</th>
                          <th>Action</th>
                          <th>Email</th>
                          <th>IP</th>
                          <th>Status</th>
                          <th>Detail</th>
                        </tr>
                      </thead>
                      <tbody>
                        {auditLogs.map(log => (
                          <tr key={log.id} style={{background: log.success ? undefined : 'rgba(239,68,68,0.08)'}}>
                            <td style={{whiteSpace:'nowrap'}}>{new Date(log.timestamp).toLocaleString()}</td>
                            <td><span style={{
                              padding:'2px 8px', borderRadius:'4px', fontSize:'11px', fontWeight:600,
                              background: log.success ? 'rgba(16,185,129,0.15)' : 'rgba(239,68,68,0.15)',
                              color: log.success ? '#10b981' : '#ef4444',
                            }}>{log.action}</span></td>
                            <td>{log.email || '-'}</td>
                            <td style={{fontFamily:'monospace', fontSize:'12px'}}>{log.ip_address || '-'}</td>
                            <td>{log.success ? '✓' : '✗'}</td>
                            <td style={{color:'#6b7280', maxWidth:'200px', overflow:'hidden', textOverflow:'ellipsis'}}>{log.detail || '-'}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <p style={{color:'#6b7280', fontSize:'14px'}}>Click "Load Log" to view security audit events.</p>
                )}
              </div>
            )}

            {/* ==================== CONFIG TAB ==================== */}
            {activeTab === 'config' && stats && (
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
          </>
        )}
      </main>
    </div>
  );
}

export default Admin;
