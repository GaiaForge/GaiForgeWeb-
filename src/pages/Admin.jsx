import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { fetchProductDocs, PRODUCTS, PRODUCT_LABELS } from '../docs/productDocs';
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
  const [newSerial, setNewSerial] = useState({ serial: '', product: 'orpheus', notes: '' });
  const [serialAdding, setSerialAdding] = useState(false);
  const [serialMsg, setSerialMsg] = useState(null);
  const [serialDeleting, setSerialDeleting] = useState(null);
  const [serialFilter, setSerialFilter] = useState('');
  const [serialProductFilter, setSerialProductFilter] = useState('');
  const [serialStatusFilter, setSerialStatusFilter] = useState('');

  // Password reset
  const [passwordResetUser, setPasswordResetUser] = useState(null);
  const [generatedPassword, setGeneratedPassword] = useState('');
  const [resettingPassword, setResettingPassword] = useState(false);
  const [resetMessage, setResetMessage] = useState(null);

  // Add user
  const [showAddUser, setShowAddUser] = useState(false);
  const [newUser, setNewUser] = useState({
    name: '', email: '', password: '', subscription_tier: 'free',
    device_serial: '', device_type: 'orpheus',
  });
  const [addingUser, setAddingUser] = useState(false);
  const [addUserMsg, setAddUserMsg] = useState(null);

  // Data management
  const [allHives, setAllHives] = useState([]);
  const [archiveHiveId, setArchiveHiveId] = useState('');
  const [archiveBefore, setArchiveBefore] = useState('');
  const [archiveCount, setArchiveCount] = useState(null);
  const [archiving, setArchiving] = useState(false);
  const [archiveMessage, setArchiveMessage] = useState(null);

  // Document library management (per product)
  const [docsProduct, setDocsProduct] = useState('orpheus');
  const [docsList, setDocsList] = useState([]);
  const [docsLoading, setDocsLoading] = useState(false);
  const [docTitle, setDocTitle] = useState('');
  const [docDesc, setDocDesc] = useState('');
  const [docFile, setDocFile] = useState(null);
  const [docUploading, setDocUploading] = useState(false);
  const [docsMsg, setDocsMsg] = useState(null);
  const [docFileKey, setDocFileKey] = useState(0);

  const headers = {
    'Authorization': `Bearer ${user?.token}`,
    'Content-Type': 'application/json',
  };

  useEffect(() => {
    fetchData();
  }, []);

  const loadDocs = async (product) => {
    setDocsLoading(true);
    try {
      setDocsList(await fetchProductDocs(product));
    } finally {
      setDocsLoading(false);
    }
  };

  useEffect(() => {
    if (activeTab === 'documents') loadDocs(docsProduct);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab, docsProduct]);

  const uploadDoc = async () => {
    if (!docTitle.trim() || !docFile) {
      setDocsMsg({ type: 'error', text: 'A title and a file are required.' });
      return;
    }
    setDocUploading(true);
    setDocsMsg(null);
    const fd = new FormData();
    fd.append('file', docFile);
    fd.append('title', docTitle.trim());
    fd.append('description', docDesc.trim());
    try {
      const res = await fetch(`${API_BASE}/api/${docsProduct}/docs`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${user?.token}` },
        body: fd,
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.detail || 'Upload failed');
      }
      setDocsMsg({ type: 'success', text: 'Document added.' });
      setDocTitle(''); setDocDesc(''); setDocFile(null);
      setDocFileKey((k) => k + 1);
      loadDocs(docsProduct);
    } catch (err) {
      setDocsMsg({ type: 'error', text: err.message || 'Upload failed' });
    } finally {
      setDocUploading(false);
    }
  };

  const deleteDoc = async (id) => {
    setDocsMsg(null);
    try {
      const res = await fetch(`${API_BASE}/api/${docsProduct}/docs/${id}`, {
        method: 'DELETE',
        headers,
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.detail || 'Delete failed');
      }
      loadDocs(docsProduct);
    } catch (err) {
      setDocsMsg({ type: 'error', text: err.message || 'Delete failed' });
    }
  };

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

  const generateRandomPassword = () => {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#$%&*';
    let password = '';
    for (let i = 0; i < 16; i++) {
      password += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return password;
  };

  const resetUserPassword = async (userId, userEmail) => {
    const newPassword = generateRandomPassword();
    setResettingPassword(true);
    setResetMessage(null);
    try {
      const res = await fetch(`${API_BASE}/api/admin/users/${userId}/reset-password`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ new_password: newPassword }),
      });
      if (res.ok) {
        setGeneratedPassword(newPassword);
        setPasswordResetUser({ id: userId, email: userEmail });
        setResetMessage({
          type: 'ok',
          text: `Password reset successfully for ${userEmail}. Make sure to copy the password before closing!`
        });
      } else {
        const err = await res.json().catch(() => ({}));
        setResetMessage({ type: 'err', text: err.detail || 'Failed to reset password' });
      }
    } catch (err) {
      setResetMessage({ type: 'err', text: 'Connection error' });
    } finally {
      setResettingPassword(false);
    }
  };

  const copyPasswordToClipboard = () => {
    navigator.clipboard.writeText(generatedPassword);
    alert('Password copied to clipboard!');
  };

  const closePasswordReset = () => {
    if (generatedPassword && !window.confirm('Have you copied the password? It cannot be recovered after closing.')) {
      return;
    }
    setPasswordResetUser(null);
    setGeneratedPassword('');
    setResetMessage(null);
  };

  const createUser = async () => {
    if (!newUser.name.trim() || !newUser.email.trim() || !newUser.password) return;
    setAddingUser(true);
    setAddUserMsg(null);
    try {
      const res = await fetch(`${API_BASE}/api/admin/users`, {
        method: 'POST', headers,
        body: JSON.stringify({
          name: newUser.name.trim(),
          email: newUser.email.trim(),
          password: newUser.password,
          subscription_tier: newUser.subscription_tier,
          device_serial: newUser.device_serial.trim() || null,
          device_type: newUser.device_serial.trim() ? newUser.device_type : null,
        }),
      });
      const data = await res.json().catch(() => ({}));
      if (res.ok) {
        setAddUserMsg({ type: 'ok', text: `${newUser.email.trim()} created` });
        setNewUser({ name: '', email: '', password: '', subscription_tier: 'free', device_serial: '', device_type: 'orpheus' });
        fetchData();
        setTimeout(() => { setShowAddUser(false); setAddUserMsg(null); }, 1200);
      } else {
        setAddUserMsg({ type: 'err', text: data.detail || 'Failed to create user' });
      }
    } catch {
      setAddUserMsg({ type: 'err', text: 'Connection error' });
    } finally {
      setAddingUser(false);
    }
  };

  const addSerial = async () => {
    if (!newSerial.serial.trim()) return;
    setSerialAdding(true);
    setSerialMsg(null);
    try {
      const res = await fetch(`${API_BASE}/api/admin/serials`, {
        method: 'POST', headers,
        body: JSON.stringify({
          serial: newSerial.serial.trim(),
          product: newSerial.product,
          notes: newSerial.notes.trim() || null,
        }),
      });
      if (res.ok) {
        setSerialMsg({ type: 'ok', text: `${newSerial.serial.trim()} added` });
        setNewSerial({ serial: '', product: newSerial.product, notes: '' });
        fetchData();
      } else {
        const data = await res.json().catch(() => ({}));
        setSerialMsg({ type: 'err', text: data.detail || 'Failed to add serial' });
      }
    } catch {
      setSerialMsg({ type: 'err', text: 'Connection error' });
    } finally {
      setSerialAdding(false);
    }
  };

  const deleteSerial = async (id, serial) => {
    if (!window.confirm(`Delete serial ${serial}? Only unclaimed serials can be deleted.`)) return;
    setSerialDeleting(id);
    try {
      const res = await fetch(`${API_BASE}/api/admin/serials/${id}`, { method: 'DELETE', headers });
      if (res.ok) {
        fetchData();
      } else {
        const data = await res.json().catch(() => ({}));
        alert(data.detail || 'Failed to delete serial');
      }
    } catch {
      alert('Connection error');
    } finally {
      setSerialDeleting(null);
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
          <button className={`nav-item nav-btn ${activeTab === 'documents' ? 'active' : ''}`}
            onClick={() => setActiveTab('documents')}>
            <span className="nav-icon">📚</span> Documents
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
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <h3>User Management</h3>
                  <button onClick={() => setShowAddUser(true)}
                    style={{
                      padding: '10px 18px', background: '#10b981', color: '#fff', border: 'none',
                      borderRadius: '10px', fontWeight: 600, cursor: 'pointer', fontSize: '14px',
                    }}>
                    + Add User
                  </button>
                </div>
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
                              <button
                                className="btn-small"
                                onClick={() => resetUserPassword(u.id, u.email)}
                                disabled={resettingPassword}
                                style={{background:'#f59e0b',color:'#fff',border:'none',borderRadius:'6px',padding:'4px 10px',fontSize:'12px',cursor:'pointer',opacity:resettingPassword?0.5:1}}>
                                Reset Password
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
              <>
              {/* Add serial form */}
              <div className="admin-card" style={{marginBottom:'24px'}}>
                <h3>Add Device Serial</h3>
                <div style={{display:'flex', gap:'12px', flexWrap:'wrap', alignItems:'flex-end', marginTop:'12px'}}>
                  <div>
                    <label style={{display:'block', fontSize:'13px', fontWeight:600, color:'#374151', marginBottom:'6px'}}>Serial Number</label>
                    <input type="text" value={newSerial.serial} onChange={e => setNewSerial({...newSerial, serial: e.target.value})}
                      placeholder="e.g. ORPB-2026-010"
                      style={{padding:'10px 14px', border:'2px solid #e5e7eb', borderRadius:'10px', fontSize:'14px', minWidth:'200px'}} />
                  </div>
                  <div>
                    <label style={{display:'block', fontSize:'13px', fontWeight:600, color:'#374151', marginBottom:'6px'}}>Product</label>
                    <select value={newSerial.product} onChange={e => setNewSerial({...newSerial, product: e.target.value})}
                      style={{padding:'10px 14px', border:'2px solid #e5e7eb', borderRadius:'10px', fontSize:'14px', background:'#fff'}}>
                      <option value="orpheus">Orpheus</option>
                      <option value="hiveguard">HiveGuard</option>
                      <option value="sprigrig">SprigRig</option>
                    </select>
                  </div>
                  <div style={{flex:1, minWidth:'200px'}}>
                    <label style={{display:'block', fontSize:'13px', fontWeight:600, color:'#374151', marginBottom:'6px'}}>Notes</label>
                    <input type="text" value={newSerial.notes} onChange={e => setNewSerial({...newSerial, notes: e.target.value})}
                      placeholder="e.g. Basic v1.6 | Customer name, location"
                      style={{padding:'10px 14px', border:'2px solid #e5e7eb', borderRadius:'10px', fontSize:'14px', width:'100%'}} />
                  </div>
                  <button onClick={addSerial} disabled={serialAdding || !newSerial.serial.trim()}
                    style={{padding:'10px 20px', background:'#10b981', color:'#fff', border:'none', borderRadius:'10px',
                      fontWeight:600, cursor:'pointer', fontSize:'14px', opacity: serialAdding || !newSerial.serial.trim() ? 0.5 : 1}}>
                    {serialAdding ? 'Adding...' : 'Add Serial'}
                  </button>
                </div>
                {serialMsg && (
                  <p style={{marginTop:'10px', fontSize:'13px', color: serialMsg.type === 'ok' ? '#10b981' : '#ef4444'}}>
                    {serialMsg.text}
                  </p>
                )}
              </div>

              <div className="admin-card">
                <div style={{display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:'16px', flexWrap:'wrap', gap:'12px'}}>
                  <div>
                    <h3 style={{margin:0}}>All Serials</h3>
                    <p style={{fontSize:'13px', color:'#6b7280', marginTop:'4px'}}>
                      {allSerials.length} total &middot; {allSerials.filter(s => s.claimed_by).length} claimed &middot; {allSerials.filter(s => !s.claimed_by).length} available
                    </p>
                  </div>
                  <div style={{display:'flex', gap:'8px', flexWrap:'wrap'}}>
                    <input type="text" value={serialFilter} onChange={e => setSerialFilter(e.target.value)}
                      placeholder="Search serial, customer, notes..."
                      style={{padding:'8px 12px', border:'2px solid #e5e7eb', borderRadius:'8px', fontSize:'13px', minWidth:'220px'}} />
                    <select value={serialProductFilter} onChange={e => setSerialProductFilter(e.target.value)}
                      style={{padding:'8px 12px', border:'2px solid #e5e7eb', borderRadius:'8px', fontSize:'13px'}}>
                      <option value="">All products</option>
                      <option value="orpheus">Orpheus</option>
                      <option value="hiveguard">HiveGuard</option>
                      <option value="sprigrig">SprigRig</option>
                    </select>
                    <select value={serialStatusFilter} onChange={e => setSerialStatusFilter(e.target.value)}
                      style={{padding:'8px 12px', border:'2px solid #e5e7eb', borderRadius:'8px', fontSize:'13px'}}>
                      <option value="">All statuses</option>
                      <option value="claimed">Claimed</option>
                      <option value="available">Available</option>
                    </select>
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
                        <th></th>
                      </tr>
                    </thead>
                    <tbody>
                      {(() => {
                        const q = serialFilter.toLowerCase();
                        const filtered = allSerials.filter(s => {
                          if (serialProductFilter && s.product !== serialProductFilter) return false;
                          if (serialStatusFilter === 'claimed' && !s.claimed_by) return false;
                          if (serialStatusFilter === 'available' && s.claimed_by) return false;
                          if (q) {
                            const claimedUser = s.claimed_by ? users.find(u => u.id === s.claimed_by) : null;
                            const searchStr = [s.serial, s.product, s.notes || '', claimedUser?.name || '', claimedUser?.email || ''].join(' ').toLowerCase();
                            if (!searchStr.includes(q)) return false;
                          }
                          return true;
                        });
                        return filtered.length === 0 ? (
                        <tr><td colSpan="7" style={{color:'#9ca3af', textAlign:'center', padding:'24px'}}>
                          {allSerials.length === 0 ? 'No device serials registered yet.' : 'No serials match your filters.'}
                        </td></tr>
                      ) : (
                        filtered.map(s => {
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
                              <td>
                                {!s.claimed_by && (
                                  <button onClick={() => deleteSerial(s.id, s.serial)}
                                    disabled={serialDeleting === s.id}
                                    style={{background:'#ef4444', color:'#fff', border:'none', borderRadius:'6px',
                                      padding:'4px 10px', fontSize:'12px', cursor:'pointer',
                                      opacity: serialDeleting === s.id ? 0.5 : 1}}>
                                    {serialDeleting === s.id ? '...' : 'Delete'}
                                  </button>
                                )}
                              </td>
                            </tr>
                          );
                        })
                      );
                      })()}
                    </tbody>
                  </table>
                </div>
              </div>
              </>
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
              <>
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

              {/* BirdNET Config */}
              <div className="admin-card" style={{marginTop:'24px'}}>
                <h3>BirdNET Analyzer</h3>
                <p style={{fontSize:'14px', color:'#6b7280', marginBottom:'16px'}}>
                  Analyzes Orpheus Pro field recordings to identify bird species automatically.
                </p>
                <div style={{display:'flex', gap:'12px', alignItems:'center'}}>
                  <button onClick={async () => {
                    const res = await fetch(`${API_BASE}/api/admin/birdnet/status`, { headers });
                    if (res.ok) {
                      const data = await res.json();
                      alert(data.installed
                        ? `BirdNET installed — version ${data.version}`
                        : 'BirdNET is not installed. Click Update to install it.');
                    }
                  }} style={{
                    padding:'10px 20px', background:'#3b82f6', color:'#fff', border:'none',
                    borderRadius:'10px', fontWeight:600, cursor:'pointer', fontSize:'14px',
                  }}>Check Status</button>
                  <button onClick={async () => {
                    if (!window.confirm('Install/update BirdNET? This may take a minute.')) return;
                    const res = await fetch(`${API_BASE}/api/admin/birdnet/update`, {
                      method:'POST', headers,
                    });
                    if (res.ok) {
                      const data = await res.json();
                      alert(data.status === 'ok'
                        ? `BirdNET updated to version ${data.version}`
                        : `Update failed: ${data.error}`);
                    } else {
                      alert('Update request failed');
                    }
                  }} style={{
                    padding:'10px 20px', background:'#10b981', color:'#fff', border:'none',
                    borderRadius:'10px', fontWeight:600, cursor:'pointer', fontSize:'14px',
                  }}>Update BirdNET</button>
                </div>
              </div>
              </>
            )}

            {/* ==================== DOCUMENTS TAB ==================== */}
            {activeTab === 'documents' && (
              <div>
                <h2>Product Documentation</h2>
                <p style={{ color: '#6b7280', marginBottom: '16px' }}>
                  Upload or remove documents shown on each product's Documentation page.
                  Changes are live immediately — no code deploy needed.
                </p>

                <div style={{ display: 'flex', gap: '10px', alignItems: 'center', marginBottom: '20px', flexWrap: 'wrap' }}>
                  <label style={{ fontWeight: 600 }}>Product:</label>
                  <select value={docsProduct} onChange={(e) => setDocsProduct(e.target.value)}
                    style={{ padding: '8px 12px', borderRadius: '8px', border: '1px solid #d1d5db' }}>
                    {PRODUCTS.map((p) => (<option key={p} value={p}>{PRODUCT_LABELS[p]}</option>))}
                  </select>
                </div>

                {docsMsg && (
                  <div style={{
                    padding: '10px 14px', borderRadius: '8px', marginBottom: '14px',
                    background: docsMsg.type === 'error' ? '#fef2f2' : '#ecfdf5',
                    color: docsMsg.type === 'error' ? '#b91c1c' : '#065f46',
                    border: `1px solid ${docsMsg.type === 'error' ? '#fecaca' : '#a7f3d0'}`,
                  }}>{docsMsg.text}</div>
                )}

                <div style={{ background: '#f9fafb', border: '1px solid #e5e7eb', borderRadius: '12px', padding: '18px', marginBottom: '24px' }}>
                  <h3 style={{ marginTop: 0 }}>Add a document</h3>
                  <div style={{ display: 'grid', gap: '10px', maxWidth: '560px' }}>
                    <input type="text" placeholder="Title" value={docTitle} onChange={(e) => setDocTitle(e.target.value)}
                      style={{ padding: '10px 12px', borderRadius: '8px', border: '1px solid #d1d5db' }} />
                    <textarea placeholder="Short description" value={docDesc} onChange={(e) => setDocDesc(e.target.value)} rows={2}
                      style={{ padding: '10px 12px', borderRadius: '8px', border: '1px solid #d1d5db', resize: 'vertical' }} />
                    <input key={docFileKey} type="file" accept=".pdf,.html"
                      onChange={(e) => setDocFile(e.target.files[0] || null)} />
                    <button onClick={uploadDoc} disabled={docUploading}
                      style={{ padding: '10px 18px', background: '#10b981', color: '#fff', border: 'none', borderRadius: '10px', fontWeight: 600, cursor: 'pointer', width: 'fit-content', opacity: docUploading ? 0.6 : 1 }}>
                      {docUploading ? 'Uploading…' : 'Add document'}
                    </button>
                  </div>
                </div>

                <h3>Current documents</h3>
                {docsLoading ? (
                  <div className="loading-state">Loading…</div>
                ) : docsList.length === 0 ? (
                  <p style={{ color: '#6b7280' }}>No documents yet.</p>
                ) : (
                  <div style={{ display: 'grid', gap: '10px' }}>
                    {docsList.map((doc) => (
                      <div key={doc.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px', padding: '12px 14px', border: '1px solid #e5e7eb', borderRadius: '10px', background: '#fff' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', minWidth: 0 }}>
                          <span style={{ fontSize: '24px' }}>{doc.icon || (doc.type === 'html' ? '🌐' : '📄')}</span>
                          <div style={{ minWidth: 0 }}>
                            <div style={{ fontWeight: 600 }}>
                              {doc.title}
                              {doc.builtin && (
                                <span style={{ marginLeft: '8px', fontSize: '11px', color: '#6b7280', border: '1px solid #d1d5db', borderRadius: '20px', padding: '1px 8px' }}>built-in</span>
                              )}
                            </div>
                            <div style={{ fontSize: '12px', color: '#6b7280', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                              {doc.description}{doc.date ? ` · ${doc.date}` : ''}{doc.size ? ` · ${doc.size}` : ''}
                            </div>
                          </div>
                        </div>
                        <div style={{ display: 'flex', gap: '8px', flexShrink: 0 }}>
                          <a href={doc.url} target="_blank" rel="noreferrer" style={{ padding: '6px 12px', borderRadius: '8px', border: '1px solid #d1d5db', color: '#374151', textDecoration: 'none', fontSize: '13px' }}>View</a>
                          <button onClick={() => { if (window.confirm(`Delete "${doc.title}"?`)) deleteDoc(doc.id); }}
                            style={{ padding: '6px 12px', borderRadius: '8px', border: 'none', background: '#ef4444', color: '#fff', cursor: 'pointer', fontSize: '13px' }}>Delete</button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </>
        )}
      </main>

      {/* Password Reset Modal */}
      {passwordResetUser && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center',
          justifyContent: 'center', zIndex: 9999
        }} onClick={closePasswordReset}>
          <div style={{
            background: '#1f2937', borderRadius: '16px', padding: '32px',
            maxWidth: '500px', width: '90%', boxShadow: '0 20px 60px rgba(0,0,0,0.5)'
          }} onClick={e => e.stopPropagation()}>
            <h2 style={{ color: '#f59e0b', marginBottom: '16px', fontSize: '24px' }}>
              🔑 Password Reset
            </h2>
            <p style={{ color: '#e5e5e5', marginBottom: '8px' }}>
              New password for <strong>{passwordResetUser.email}</strong>:
            </p>
            <div style={{
              background: '#374151', padding: '16px', borderRadius: '10px',
              marginBottom: '16px', position: 'relative'
            }}>
              <code style={{
                fontSize: '18px', color: '#10b981', fontWeight: 600,
                wordBreak: 'break-all', display: 'block'
              }}>
                {generatedPassword}
              </code>
              <button
                onClick={copyPasswordToClipboard}
                style={{
                  position: 'absolute', top: '8px', right: '8px',
                  padding: '6px 12px', background: '#10b981', color: '#fff',
                  border: 'none', borderRadius: '6px', fontSize: '12px',
                  cursor: 'pointer', fontWeight: 600
                }}
              >
                📋 Copy
              </button>
            </div>
            <p style={{ color: '#fbbf24', fontSize: '13px', marginBottom: '20px' }}>
              ⚠️ <strong>Important:</strong> Copy this password now! It cannot be recovered after closing this window.
              Send it to the user via a secure channel (not regular email).
            </p>
            {resetMessage && (
              <p style={{
                fontSize: '13px', padding: '12px', borderRadius: '8px',
                marginBottom: '16px',
                background: resetMessage.type === 'ok' ? 'rgba(16,185,129,0.15)' : 'rgba(239,68,68,0.15)',
                color: resetMessage.type === 'ok' ? '#10b981' : '#ef4444'
              }}>
                {resetMessage.text}
              </p>
            )}
            <div style={{ display: 'flex', gap: '12px' }}>
              <button
                onClick={copyPasswordToClipboard}
                style={{
                  flex: 1, padding: '12px 20px', background: '#10b981',
                  color: '#fff', border: 'none', borderRadius: '10px',
                  fontWeight: 600, cursor: 'pointer', fontSize: '14px'
                }}
              >
                Copy Password
              </button>
              <button
                onClick={closePasswordReset}
                style={{
                  flex: 1, padding: '12px 20px', background: '#6b7280',
                  color: '#fff', border: 'none', borderRadius: '10px',
                  fontWeight: 600, cursor: 'pointer', fontSize: '14px'
                }}
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add User Modal */}
      {showAddUser && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center',
          justifyContent: 'center', zIndex: 9999
        }} onClick={() => setShowAddUser(false)}>
          <div style={{
            background: '#1f2937', borderRadius: '16px', padding: '32px',
            maxWidth: '480px', width: '90%', boxShadow: '0 20px 60px rgba(0,0,0,0.5)'
          }} onClick={e => e.stopPropagation()}>
            <h2 style={{ color: '#10b981', marginBottom: '20px', fontSize: '24px' }}>
              + Add User
            </h2>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginBottom: '16px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#e5e5e5', marginBottom: '6px' }}>Name</label>
                <input type="text" value={newUser.name} onChange={e => setNewUser({ ...newUser, name: e.target.value })}
                  style={{ padding: '10px 14px', border: 'none', borderRadius: '10px', fontSize: '14px', width: '100%', boxSizing: 'border-box' }} />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#e5e5e5', marginBottom: '6px' }}>Email</label>
                <input type="email" value={newUser.email} onChange={e => setNewUser({ ...newUser, email: e.target.value })}
                  style={{ padding: '10px 14px', border: 'none', borderRadius: '10px', fontSize: '14px', width: '100%', boxSizing: 'border-box' }} />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#e5e5e5', marginBottom: '6px' }}>Password</label>
                <input type="text" value={newUser.password} onChange={e => setNewUser({ ...newUser, password: e.target.value })}
                  placeholder="min. 8 characters"
                  style={{ padding: '10px 14px', border: 'none', borderRadius: '10px', fontSize: '14px', width: '100%', boxSizing: 'border-box' }} />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#e5e5e5', marginBottom: '6px' }}>Subscription</label>
                <select value={newUser.subscription_tier} onChange={e => setNewUser({ ...newUser, subscription_tier: e.target.value })}
                  style={{ padding: '10px 14px', border: 'none', borderRadius: '10px', fontSize: '14px', width: '100%', boxSizing: 'border-box' }}>
                  <option value="free">Free</option>
                  <option value="pro">Pro</option>
                </select>
              </div>

              <div style={{ borderTop: '1px solid #374151', paddingTop: '14px', marginTop: '4px' }}>
                <p style={{ color: '#9ca3af', fontSize: '12px', marginBottom: '10px' }}>
                  Optional — claim an existing serial, or type a new one to register it on the spot.
                </p>
                <div style={{ display: 'flex', gap: '10px' }}>
                  <div style={{ flex: 1 }}>
                    <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#e5e5e5', marginBottom: '6px' }}>Device Serial</label>
                    <input type="text" value={newUser.device_serial} onChange={e => setNewUser({ ...newUser, device_serial: e.target.value })}
                      placeholder="e.g. ORPB-2026-010"
                      style={{ padding: '10px 14px', border: 'none', borderRadius: '10px', fontSize: '14px', width: '100%', boxSizing: 'border-box' }} />
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#e5e5e5', marginBottom: '6px' }}>Product</label>
                    <select value={newUser.device_type} onChange={e => setNewUser({ ...newUser, device_type: e.target.value })}
                      disabled={!newUser.device_serial.trim()}
                      style={{ padding: '10px 14px', border: 'none', borderRadius: '10px', fontSize: '14px' }}>
                      <option value="orpheus">Orpheus</option>
                      <option value="hiveguard">HiveGuard</option>
                      <option value="sprigrig">SprigRig</option>
                    </select>
                  </div>
                </div>
              </div>
            </div>

            {addUserMsg && (
              <p style={{
                fontSize: '13px', padding: '12px', borderRadius: '8px',
                marginBottom: '16px',
                background: addUserMsg.type === 'ok' ? 'rgba(16,185,129,0.15)' : 'rgba(239,68,68,0.15)',
                color: addUserMsg.type === 'ok' ? '#10b981' : '#ef4444'
              }}>
                {addUserMsg.text}
              </p>
            )}

            <div style={{ display: 'flex', gap: '12px' }}>
              <button
                onClick={createUser}
                disabled={addingUser || !newUser.name.trim() || !newUser.email.trim() || !newUser.password}
                style={{
                  flex: 1, padding: '12px 20px', background: '#10b981',
                  color: '#fff', border: 'none', borderRadius: '10px',
                  fontWeight: 600, cursor: 'pointer', fontSize: '14px',
                  opacity: (addingUser || !newUser.name.trim() || !newUser.email.trim() || !newUser.password) ? 0.5 : 1,
                }}
              >
                {addingUser ? 'Creating...' : 'Create User'}
              </button>
              <button
                onClick={() => { setShowAddUser(false); setAddUserMsg(null); }}
                style={{
                  flex: 1, padding: '12px 20px', background: '#6b7280',
                  color: '#fff', border: 'none', borderRadius: '10px',
                  fontWeight: 600, cursor: 'pointer', fontSize: '14px'
                }}
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Admin;
