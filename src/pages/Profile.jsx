import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Dashboard.css';

const API_BASE = window.location.origin;

function Profile({ user, onLogout }) {
  const navigate = useNavigate();
  const [section, setSection] = useState('account'); // 'account' | 'password' | 'email' | 'danger'

  const [pwForm, setPwForm] = useState({ current_password: '', new_password: '', confirm: '' });
  const [emailForm, setEmailForm] = useState({ password: '', new_email: '' });
  const [msg, setMsg] = useState('');
  const [err, setErr] = useState('');
  const [copying, setCopying] = useState(false);
  const [newApiKey, setNewApiKey] = useState(null);
  const [deletePassword, setDeletePassword] = useState('');

  const headers = {
    'Authorization': `Bearer ${user?.token}`,
    'Content-Type': 'application/json',
  };

  const flash = (text, isError = false) => {
    if (isError) { setErr(text); setMsg(''); }
    else { setMsg(text); setErr(''); }
  };

  const handlePasswordChange = async (e) => {
    e.preventDefault();
    if (pwForm.new_password !== pwForm.confirm) {
      flash('New passwords do not match', true); return;
    }
    if (pwForm.new_password.length < 8) {
      flash('New password must be at least 8 characters', true); return;
    }
    const res = await fetch(`${API_BASE}/api/auth/change-password`, {
      method: 'POST', headers,
      body: JSON.stringify({ current_password: pwForm.current_password, new_password: pwForm.new_password }),
    });
    if (res.ok) {
      setPwForm({ current_password: '', new_password: '', confirm: '' });
      flash('Password updated successfully.');
    } else {
      const d = await res.json().catch(() => ({}));
      flash(d.detail || 'Failed to update password', true);
    }
  };

  const handleEmailChange = async (e) => {
    e.preventDefault();
    const res = await fetch(`${API_BASE}/api/auth/change-email`, {
      method: 'POST', headers,
      body: JSON.stringify({ password: emailForm.password, new_email: emailForm.new_email }),
    });
    if (res.ok) {
      const d = await res.json();
      setEmailForm({ password: '', new_email: '' });
      flash(`Email updated to ${d.email}. Please log in again.`);
      // Update local storage
      const saved = JSON.parse(localStorage.getItem('user') || '{}');
      localStorage.setItem('user', JSON.stringify({ ...saved, email: d.email }));
    } else {
      const d = await res.json().catch(() => ({}));
      flash(d.detail || 'Failed to update email', true);
    }
  };

  const handleRegenKey = async () => {
    if (!window.confirm('Regenerate your API key? Your existing integrations will stop working until updated.')) return;
    const res = await fetch(`${API_BASE}/api/auth/regenerate-api-key`, { method: 'POST', headers });
    if (res.ok) {
      const d = await res.json();
      setNewApiKey(d.api_key);
      // Update local storage
      const saved = JSON.parse(localStorage.getItem('user') || '{}');
      localStorage.setItem('user', JSON.stringify({ ...saved, api_key: d.api_key }));
      flash('API key regenerated. Copy your new key — it will not be shown again after you leave this page.');
    }
  };

  const copyKey = (key) => {
    navigator.clipboard.writeText(key);
    setCopying(true);
    setTimeout(() => setCopying(false), 1500);
  };

  const handleDeleteAccount = async (e) => {
    e.preventDefault();
    if (!window.confirm('This will permanently delete your account, all hives, and all readings. This cannot be undone. Continue?')) return;
    const res = await fetch(`${API_BASE}/api/auth/account`, {
      method: 'DELETE', headers,
      body: JSON.stringify({ password: deletePassword }),
    });
    if (res.ok) {
      onLogout();
      navigate('/login');
    } else {
      const d = await res.json().catch(() => ({}));
      flash(d.detail || 'Failed to delete account', true);
    }
  };

  const handleLogout = () => { onLogout(); navigate('/login'); };

  const displayApiKey = newApiKey || user?.api_key || '';
  const maskedKey = displayApiKey ? displayApiKey.slice(0, 8) + '••••••••••••••••••••••••' : '';

  const TIER_BADGE = {
    pro: { bg: '#fef3c7', color: '#92400e', label: 'Pro' },
    free: { bg: '#f3f4f6', color: '#374151', label: 'Free' },
  };
  const tier = TIER_BADGE[user?.subscription_tier] || TIER_BADGE.free;

  return (
    <div className="dashboard-container">
      <aside className="sidebar">
        <div className="sidebar-header">
          <a href="/"><img src="/gaiaforge-logo.png" alt="GaiaForge" className="logo-image" /></a>
        </div>
        <nav className="sidebar-nav">
          <a href="/" className="nav-item back-link"><span className="nav-icon">←</span> Back to Site</a>
          <Link to="/dashboard" className="nav-item"><span className="nav-icon">📊</span> Dashboard</Link>
          <Link to="/analytics" className="nav-item"><span className="nav-icon">🔬</span> Analytics</Link>
          <Link to="/upload" className="nav-item"><span className="nav-icon">⬆️</span> Upload Data</Link>
          <Link to="/devices" className="nav-item"><span className="nav-icon">📟</span> My Hives</Link>
          <Link to="/alerts" className="nav-item"><span className="nav-icon">🔔</span> Alerts</Link>
          <Link to="/profile" className="nav-item active"><span className="nav-icon">👤</span> Profile</Link>
          {user?.is_admin && <Link to="/admin" className="nav-item"><span className="nav-icon">⚙️</span> Admin</Link>}
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
            <h1>Profile Settings</h1>
            <p>Manage your account, security, and API access</p>
          </div>
        </header>

        {msg && <div style={{
          background: '#d1fae5', color: '#065f46', padding: '12px 16px',
          borderRadius: '8px', marginBottom: '20px', fontSize: '14px',
        }}>{msg}</div>}
        {err && <div style={{
          background: '#fef2f2', color: '#dc2626', padding: '12px 16px',
          borderRadius: '8px', marginBottom: '20px', fontSize: '14px',
        }}>{err}</div>}

        <div style={{ display: 'flex', gap: '24px', flexWrap: 'wrap', alignItems: 'flex-start' }}>
          {/* Section nav */}
          <div style={{ minWidth: '180px' }}>
            {[
              { key: 'account', icon: '👤', label: 'Account' },
              { key: 'password', icon: '🔒', label: 'Password' },
              { key: 'email', icon: '✉️', label: 'Change Email' },
              { key: 'apikey', icon: '🔑', label: 'API Key' },
              { key: 'danger', icon: '⚠️', label: 'Danger Zone' },
            ].map(s => (
              <button key={s.key} onClick={() => { setSection(s.key); setMsg(''); setErr(''); }} style={{
                display: 'flex', alignItems: 'center', gap: '8px', width: '100%',
                padding: '10px 14px', background: section === s.key ? '#fef3c7' : 'transparent',
                border: 'none', borderRadius: '8px', cursor: 'pointer', textAlign: 'left',
                fontWeight: section === s.key ? 700 : 500,
                color: s.key === 'danger' ? '#dc2626' : section === s.key ? '#92400e' : '#374151',
                fontSize: '14px', marginBottom: '4px',
              }}>
                <span>{s.icon}</span> {s.label}
              </button>
            ))}
          </div>

          {/* Content */}
          <div style={{ flex: 1, minWidth: '280px', maxWidth: '520px' }}>

            {section === 'account' && (
              <div className="device-selector">
                <h3>Account Information</h3>
                <div className="form-group" style={{ marginBottom: '16px' }}>
                  <label>Name</label>
                  <input type="text" value={user?.name || ''} disabled
                    style={{ padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%', background: '#f9fafb' }} />
                </div>
                <div className="form-group" style={{ marginBottom: '16px' }}>
                  <label>Email</label>
                  <input type="email" value={user?.email || ''} disabled
                    style={{ padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%', background: '#f9fafb' }} />
                </div>
                <div className="form-group">
                  <label>Subscription</label>
                  <div style={{ marginTop: '6px' }}>
                    <span style={{
                      padding: '6px 16px', borderRadius: '20px', fontWeight: 700,
                      fontSize: '14px', background: tier.bg, color: tier.color,
                    }}>{tier.label}</span>
                    {user?.subscription_tier === 'free' && (
                      <span style={{ marginLeft: '12px', fontSize: '13px', color: '#6b7280' }}>
                        Upgrade for unlimited hives and AI insights
                      </span>
                    )}
                  </div>
                </div>
              </div>
            )}

            {section === 'password' && (
              <div className="device-selector">
                <h3>Change Password</h3>
                <form onSubmit={handlePasswordChange}>
                  {['current_password', 'new_password', 'confirm'].map((field, i) => (
                    <div key={field} className="form-group" style={{ marginBottom: '16px' }}>
                      <label>{['Current Password', 'New Password', 'Confirm New Password'][i]}</label>
                      <input type="password" value={pwForm[field]}
                        onChange={e => setPwForm({ ...pwForm, [field]: e.target.value })}
                        style={{ padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%' }} />
                    </div>
                  ))}
                  <button type="submit" style={{
                    padding: '12px 24px', background: '#f59e0b', color: '#fff',
                    border: 'none', borderRadius: '10px', fontWeight: 600, cursor: 'pointer',
                  }}>Update Password</button>
                </form>
              </div>
            )}

            {section === 'email' && (
              <div className="device-selector">
                <h3>Change Email Address</h3>
                <form onSubmit={handleEmailChange}>
                  <div className="form-group" style={{ marginBottom: '16px' }}>
                    <label>New Email Address</label>
                    <input type="email" value={emailForm.new_email}
                      onChange={e => setEmailForm({ ...emailForm, new_email: e.target.value })}
                      style={{ padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%' }} />
                  </div>
                  <div className="form-group" style={{ marginBottom: '20px' }}>
                    <label>Confirm with Password</label>
                    <input type="password" value={emailForm.password}
                      onChange={e => setEmailForm({ ...emailForm, password: e.target.value })}
                      style={{ padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%' }} />
                  </div>
                  <button type="submit" style={{
                    padding: '12px 24px', background: '#f59e0b', color: '#fff',
                    border: 'none', borderRadius: '10px', fontWeight: 600, cursor: 'pointer',
                  }}>Update Email</button>
                </form>
              </div>
            )}

            {section === 'apikey' && (
              <div className="device-selector">
                <h3>API Key</h3>
                <p style={{ color: '#6b7280', fontSize: '14px', marginBottom: '16px' }}>
                  Use this key to authenticate your HiveGuard device sync client.
                </p>
                <div style={{
                  background: '#1f2937', color: '#f9fafb', padding: '14px 16px',
                  borderRadius: '10px', fontFamily: 'monospace', fontSize: '13px',
                  marginBottom: '12px', wordBreak: 'break-all',
                }}>
                  {newApiKey ? displayApiKey : maskedKey}
                </div>
                <div style={{ display: 'flex', gap: '10px' }}>
                  <button onClick={() => copyKey(displayApiKey)} style={{
                    padding: '10px 20px', background: '#1f2937', color: '#f9fafb',
                    border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 600, fontSize: '13px',
                  }}>{copying ? 'Copied!' : 'Copy Key'}</button>
                  <button onClick={handleRegenKey} style={{
                    padding: '10px 20px', background: '#fef2f2', color: '#dc2626',
                    border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 600, fontSize: '13px',
                  }}>Regenerate Key</button>
                </div>
              </div>
            )}

            {section === 'danger' && (
              <div className="device-selector" style={{ border: '2px solid #fca5a5' }}>
                <h3 style={{ color: '#dc2626' }}>Danger Zone</h3>
                <p style={{ color: '#374151', fontSize: '14px', marginBottom: '20px' }}>
                  Permanently delete your account, including all hives, devices, and sensor readings.
                  This action cannot be undone.
                </p>
                <form onSubmit={handleDeleteAccount}>
                  <div className="form-group" style={{ marginBottom: '16px' }}>
                    <label>Confirm your password</label>
                    <input type="password" value={deletePassword}
                      onChange={e => setDeletePassword(e.target.value)}
                      style={{ padding: '12px', border: '2px solid #fca5a5', borderRadius: '10px', width: '100%' }} />
                  </div>
                  <button type="submit" style={{
                    padding: '12px 24px', background: '#dc2626', color: '#fff',
                    border: 'none', borderRadius: '10px', fontWeight: 700, cursor: 'pointer',
                  }}>Delete My Account</button>
                </form>
              </div>
            )}

          </div>
        </div>
      </main>
    </div>
  );
}

export default Profile;
