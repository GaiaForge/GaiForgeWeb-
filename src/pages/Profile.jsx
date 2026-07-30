import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import './Dashboard.css';

const API_BASE = window.location.origin;

function DevicesSection({ user }) {
  const [devices, setDevices] = React.useState([]);
  const [loading, setLoading] = React.useState(true);
  const [newSerial, setNewSerial] = React.useState('');
  const [adding, setAdding] = React.useState(false);
  const [devMsg, setDevMsg] = React.useState(null);

  const headers = {
    'Authorization': `Bearer ${user?.token}`,
    'Content-Type': 'application/json',
  };

  React.useEffect(() => { fetchDevices(); }, []);

  const fetchDevices = async () => {
    try {
      const res = await fetch(`${API_BASE}/api/auth/my-devices`, { headers });
      if (res.ok) setDevices(await res.json());
    } catch (e) { console.error(e); }
    finally { setLoading(false); }
  };

  const addDevice = async () => {
    if (!newSerial.trim()) return;
    setAdding(true);
    setDevMsg(null);
    try {
      const res = await fetch(`${API_BASE}/api/auth/add-device`, {
        method: 'POST', headers,
        body: JSON.stringify({ serial: newSerial.trim() }),
      });
      const data = await res.json();
      if (res.ok) {
        setDevMsg({ type: 'ok', text: `${newSerial.trim()} added (${data.product})` });
        setNewSerial('');
        fetchDevices();
      } else {
        setDevMsg({ type: 'err', text: data.detail || 'Failed to add device' });
      }
    } catch {
      setDevMsg({ type: 'err', text: 'Connection error' });
    } finally { setAdding(false); }
  };

  const productColor = (p) => ({
    background: p === 'orpheus' ? '#dbeafe' : p === 'hiveguard' ? '#fef3c7' : '#dcfce7',
    color: p === 'orpheus' ? '#1e40af' : p === 'hiveguard' ? '#92400e' : '#166534',
  });

  return (
    <div className="device-selector">
      <h3>My Devices</h3>
      <p style={{ color: '#6b7280', fontSize: '14px', marginBottom: '16px' }}>
        Devices registered to your account. Add more devices using their serial number.
      </p>

      {loading ? <p>Loading...</p> : (
        <>
          {devices.length === 0 ? (
            <p style={{ color: '#9ca3af' }}>No devices registered yet.</p>
          ) : (
            <div style={{ marginBottom: '20px' }}>
              {devices.map((d, i) => (
                <div key={i} style={{
                  display: 'flex', alignItems: 'center', gap: '12px', padding: '12px',
                  background: '#f9fafb', borderRadius: '10px', marginBottom: '8px',
                  border: '1px solid #e5e7eb',
                }}>
                  <span style={{
                    padding: '3px 10px', borderRadius: '6px', fontSize: '11px', fontWeight: 700,
                    ...productColor(d.product),
                  }}>{d.product}</span>
                  <code style={{ fontSize: '14px', fontWeight: 600 }}>{d.serial}</code>
                  {d.claimed_at && (
                    <span style={{ fontSize: '12px', color: '#9ca3af', marginLeft: 'auto' }}>
                      registered {new Date(d.claimed_at).toLocaleDateString()}
                    </span>
                  )}
                </div>
              ))}
            </div>
          )}

          <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
            <input type="text" value={newSerial} onChange={e => setNewSerial(e.target.value)}
              placeholder="Enter device serial number"
              style={{
                flex: 1, padding: '10px 14px', border: '2px solid #e5e7eb',
                borderRadius: '10px', fontSize: '14px',
              }}
              onKeyDown={e => e.key === 'Enter' && addDevice()}
            />
            <button onClick={addDevice} disabled={adding || !newSerial.trim()}
              style={{
                padding: '10px 20px', background: '#10b981', color: '#fff',
                border: 'none', borderRadius: '10px', fontWeight: 600,
                cursor: 'pointer', opacity: adding || !newSerial.trim() ? 0.5 : 1,
              }}>{adding ? 'Adding...' : 'Add Device'}</button>
          </div>
          {devMsg && (
            <p style={{ marginTop: '10px', fontSize: '13px', color: devMsg.type === 'ok' ? '#10b981' : '#ef4444' }}>
              {devMsg.text}
            </p>
          )}
        </>
      )}
    </div>
  );
}


function Profile({ user, onLogout, onUserUpdate }) {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const fromProduct = searchParams.get('from');
  const [section, setSection] = useState('account'); // 'account' | 'password' | 'email' | 'danger'
  const [reportMode, setReportMode] = useState(user?.report_mode || 'beekeeper');

  const [pwForm, setPwForm] = useState({ current_password: '', new_password: '', confirm: '' });
  const [emailForm, setEmailForm] = useState({ password: '', new_email: '' });
  const [msg, setMsg] = useState('');
  const [err, setErr] = useState('');
  const [copying, setCopying] = useState(false);
  const [newApiKey, setNewApiKey] = useState(null);
  const [deletePassword, setDeletePassword] = useState('');
  const [exporting, setExporting] = useState(false);


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

  const handleExportData = async () => {
    setExporting(true);
    try {
      const res = await fetch(`${API_BASE}/api/auth/account/export`, { headers });
      if (!res.ok) {
        const d = await res.json().catch(() => ({}));
        flash(d.detail || 'Failed to export data', true);
        return;
      }
      const data = await res.json();
      const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `gaiaforge-account-data-${new Date().toISOString().slice(0, 10)}.json`;
      a.click();
      URL.revokeObjectURL(url);
    } catch {
      flash('Connection error', true);
    } finally {
      setExporting(false);
    }
  };

  const handleReportModeChange = async (mode) => {
    setReportMode(mode);
    const res = await fetch(`${API_BASE}/api/auth/report-mode`, {
      method: 'POST', headers,
      body: JSON.stringify({ mode }),
    });
    if (res.ok) {
      const saved = JSON.parse(localStorage.getItem('user') || '{}');
      localStorage.setItem('user', JSON.stringify({ ...saved, report_mode: mode }));
      flash(`Report mode set to ${mode === 'beekeeper' ? 'Beekeeper' : 'Researcher'}.`);
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
  const isPro = user?.subscription_tier === 'pro';
  const expiresAt = user?.subscription_expires_at ? new Date(user.subscription_expires_at) : null;
  const isExpired = expiresAt && expiresAt < new Date();
  const daysLeft = expiresAt ? Math.ceil((expiresAt - new Date()) / (1000 * 60 * 60 * 24)) : null;

  return (
    <div className="dashboard-container">
      <aside className="sidebar">
        <div className="sidebar-header">
          <a href="/"><img src="/gaiaforge-logo.png" alt="GaiaForge" className="logo-image" /></a>
        </div>
        <nav className="sidebar-nav">
          {fromProduct === 'orpheus' ? (
            <>
              <Link to="/orpheus" className="nav-item back-link"><span className="nav-icon">&larr;</span> Orpheus Portal</Link>
              <Link to="/orpheus" className="nav-item"><span className="nav-icon">📦</span> USB Updates</Link>
              <Link to="/orpheus/analytics" className="nav-item"><span className="nav-icon">📊</span> Analytics</Link>
            </>
          ) : fromProduct === 'sprigrig' ? (
            <>
              <Link to="/sprigrig" className="nav-item back-link"><span className="nav-icon">&larr;</span> SprigRig Portal</Link>
            </>
          ) : (
            <>
              <Link to="/dashboard" className="nav-item back-link"><span className="nav-icon">&larr;</span> Dashboard</Link>
              <Link to="/analytics" className="nav-item"><span className="nav-icon">🔬</span> Analytics</Link>
              <Link to="/upload" className="nav-item"><span className="nav-icon">⬆️</span> Upload Data</Link>
              <Link to="/devices" className="nav-item"><span className="nav-icon">📟</span> My Hives</Link>
              <Link to="/journal" className="nav-item"><span className="nav-icon">📝</span> Journal</Link>
              <Link to="/alerts" className="nav-item"><span className="nav-icon">🔔</span> Alerts</Link>
            </>
          )}
          <Link to={`/profile?from=${fromProduct || 'hiveguard'}`} className="nav-item active"><span className="nav-icon">👤</span> Profile</Link>
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
              { key: 'devices', icon: '📟', label: 'My Devices' },
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
              <>
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
                  <div style={{ marginTop: '8px', display: 'flex', alignItems: 'center', gap: '12px', flexWrap: 'wrap' }}>
                    <span style={{
                      padding: '6px 16px', borderRadius: '20px', fontWeight: 700,
                      fontSize: '14px', background: tier.bg, color: tier.color,
                    }}>{tier.label}</span>
                    {isPro && expiresAt && (
                      <span style={{ fontSize: '13px', color: isExpired ? '#dc2626' : daysLeft <= 14 ? '#f59e0b' : '#10b981', fontWeight: 600 }}>
                        {isExpired ? 'Expired' : `${daysLeft} days remaining`}
                        {' · '}{expiresAt.toLocaleDateString()}
                      </span>
                    )}
                    {isPro && !expiresAt && (
                      <span style={{ fontSize: '13px', color: '#10b981', fontWeight: 600 }}>Active</span>
                    )}
                  </div>
                </div>
              </div>

              {(user?.is_admin || user?.products?.includes('hiveguard')) && (
              <>
              {/* AI Report Mode — HiveGuard-only: colony reports & apiary framing don't apply to other products */}
              <div className="device-selector" style={{ marginTop: '16px' }}>
                <h3>AI Report Style</h3>
                <p style={{ color: '#6b7280', fontSize: '14px', marginBottom: '16px' }}>
                  Choose how the AI colony report is written. You can change this any time.
                </p>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  {[
                    { mode: 'beekeeper', icon: '🐝', title: 'Beekeeper', desc: 'Plain English, real-world analogies, clear actions. Designed for the apiary.' },
                    { mode: 'researcher', icon: '🔬', title: 'Researcher', desc: 'Raw metric values, spectral feature names, technical interpretation.' },
                  ].map(({ mode, icon, title, desc }) => (
                    <button key={mode} onClick={() => handleReportModeChange(mode)} style={{
                      padding: '16px', borderRadius: '12px', textAlign: 'left', cursor: 'pointer',
                      border: `2px solid ${reportMode === mode ? '#f59e0b' : '#e5e7eb'}`,
                      background: reportMode === mode ? '#fef3c7' : '#f9fafb',
                      transition: 'all 0.15s',
                    }}>
                      <div style={{ fontSize: '24px', marginBottom: '8px' }}>{icon}</div>
                      <div style={{ fontWeight: 700, fontSize: '15px', color: '#1f2937', marginBottom: '4px' }}>{title}</div>
                      <div style={{ fontSize: '13px', color: '#6b7280', lineHeight: '1.4' }}>{desc}</div>
                      {reportMode === mode && (
                        <div style={{ marginTop: '8px', fontSize: '12px', fontWeight: 700, color: '#92400e' }}>✓ Active</div>
                      )}
                    </button>
                  ))}
                </div>
              </div>

              {/* Upgrade / Plan Info */}
              {(!isPro || isExpired) && (
                <div className="device-selector" style={{ marginTop: '16px', border: '2px solid #f59e0b' }}>
                  <h3 style={{ color: '#92400e' }}>Upgrade to Pro</h3>
                  <p style={{ color: '#6b7280', fontSize: '14px', marginBottom: '20px' }}>
                    Unlock AI-powered colony reports, advanced analytics, and priority support.
                  </p>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '14px', marginBottom: '20px' }}>
                    {[
                      { icon: '🤖', title: 'AI Colony Reports', text: 'Claude analyzes your sensor data and writes a detailed health assessment with specific findings, concerns, and actionable recommendations tailored to your hive.' },
                      { icon: '🔬', title: 'Researcher Mode', text: 'Full access to every spectral feature your device records — centroid, harmonicity, spectral flux, kurtosis, mel-band energy distribution, temporal energy tracking, and more. Export all 37 data columns as CSV.' },
                      { icon: '🐝', title: 'Behavioral Scores', text: 'Track foraging intensity, robbing risk, winter cluster health, and absconding probability over time with dedicated charts and trend analysis.' },
                      { icon: '🌧️', title: 'Weather Detection', text: 'Automatic weather event tagging separates rain and wind noise from real colony sounds, so your health scores and AI reports reflect actual bee behavior — not the weather.' },
                      { icon: '📡', title: 'Data Quality Tools', text: 'Monitor signal quality, ambient noise levels, and classification confidence to know exactly how reliable each reading is.' },
                      { icon: '🔔', title: 'Alerts & Unlimited Hives', text: 'Set custom alert rules with email notifications, and monitor as many hives as you need with no data storage limits.' },
                    ].map((f, i) => (
                      <div key={i} style={{ display: 'flex', gap: '12px', alignItems: 'flex-start', fontSize: '14px', color: '#374151' }}>
                        <span style={{ fontSize: '22px', flexShrink: 0 }}>{f.icon}</span>
                        <div>
                          <div style={{ fontWeight: 700, marginBottom: '2px' }}>{f.title}</div>
                          <div style={{ color: '#6b7280', fontSize: '13px', lineHeight: '1.5' }}>{f.text}</div>
                        </div>
                      </div>
                    ))}
                  </div>
                  <div style={{ display: 'flex', gap: '12px', alignItems: 'center', flexWrap: 'wrap' }}>
                    <div>
                      <span style={{ fontSize: '28px', fontWeight: 800, color: '#1f2937' }}>$9</span>
                      <span style={{ color: '#6b7280', fontSize: '14px' }}>/month</span>
                    </div>
                    <div style={{ color: '#6b7280', fontSize: '14px' }}>or</div>
                    <div>
                      <span style={{ fontSize: '28px', fontWeight: 800, color: '#1f2937' }}>$79</span>
                      <span style={{ color: '#6b7280', fontSize: '14px' }}>/year</span>
                      <span style={{
                        marginLeft: '8px', fontSize: '12px', background: '#d1fae5', color: '#065f46',
                        padding: '2px 8px', borderRadius: '10px', fontWeight: 700,
                      }}>Save 27%</span>
                    </div>
                  </div>
                  <div style={{ marginTop: '20px', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    <a href="mailto:hello@gaiaforge.tech?subject=HiveGuard%20Pro%20Subscription&body=I%27d%20like%20to%20upgrade%20my%20account%20(%7Byour-email%7D)%20to%20Pro."
                      style={{
                        display: 'inline-block', padding: '12px 24px', background: '#f59e0b', color: '#fff',
                        textDecoration: 'none', borderRadius: '10px', fontWeight: 700, fontSize: '15px',
                      }}>
                      Upgrade Now
                    </a>
                    <span style={{ fontSize: '13px', color: '#9ca3af', alignSelf: 'center' }}>
                      We'll activate your Pro access within 24 hours.
                    </span>
                  </div>
                </div>
              )}
              </>
              )}
              </>
            )}

            {section === 'devices' && (
              <DevicesSection user={user} />
            )}

            {section === 'password' && (
              <div className="device-selector">
                <h3>Change Password</h3>
                <form onSubmit={handlePasswordChange}>
                  {['current_password', 'new_password', 'confirm'].map((field, i) => (
                    <div key={field} className="form-group" style={{ marginBottom: '16px' }}>
                      <label>{['Current Password', 'New Password', 'Confirm New Password'][i]}</label>
                      <input type="password" value={pwForm[field]}
                        autoComplete={field === 'current_password' ? 'current-password' : 'new-password'}
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
                    <input type="email" value={emailForm.new_email} autoComplete="off"
                      onChange={e => setEmailForm({ ...emailForm, new_email: e.target.value })}
                      style={{ padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%' }} />
                  </div>
                  <div className="form-group" style={{ marginBottom: '20px' }}>
                    <label>Confirm with Password</label>
                    <input type="password" value={emailForm.password} autoComplete="new-password"
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
                  Use this key to authenticate your device sync client.
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

            {/* AudioRation removed — calibration is done via BLE in the mobile app */}
            {false && (() => {
              const selectedHive = null;
              const speciesName = selectedHive?.bee_species?.replace(/_/g, ' ') || 'Western honeybee';
              const isAfricanized = selectedHive?.bee_species === 'apis_mellifera_africanized';
              const isStingless = selectedHive?.bee_species === 'meliponini';

              const PHASES = {
                quiet: {
                  step: 1, phaseKey: 'quiet',
                  title: 'Step 1 of 3 — Absolute Quiet Scan',
                  scanning: 'Scanning mic noise floor',
                  instructions: [
                    'Take the device out of the hive and bring it indoors or to a very quiet location',
                    'Place it face-down on a soft surface — no vibrations, fans, or machinery nearby',
                    'Step out of the room and stay quiet for the full scan duration',
                    'This measures the mic\'s own electronic noise floor, independent of location',
                    'Do not power down the device during the scan',
                  ],
                  instColor: '#f5f3ff', instBorder: '#ddd6fe', instText: '#3730a3', instLabel: '#4f46e5',
                  btnLabel: 'Start Quiet Scan',
                  btnColor: '#6366f1',
                },
                empty_hive: {
                  step: 2, phaseKey: 'empty',
                  title: 'Step 2 of 3 — Empty Hive Scan',
                  scanning: 'Scanning empty hive ambient',
                  instructions: [
                    'Place the device inside the same type of hive body this colony will live in',
                    'The hive should be empty — no bees, no frames if possible, just the box',
                    'Set it up in the exact outdoor location where the colony will be kept',
                    'Close the hive and step well away — this captures location wind, resonance, and ambient sound',
                    'Do not power down the device during the scan',
                  ],
                  instColor: '#eff6ff', instBorder: '#bfdbfe', instText: '#1e40af', instLabel: '#1d4ed8',
                  btnLabel: 'Start Empty Hive Scan',
                  btnColor: '#3b82f6',
                },
                healthy_colony: {
                  step: 3, phaseKey: 'healthy',
                  title: 'Step 3 of 3 — Healthy Colony Profile',
                  scanning: 'Recording healthy colony profile',
                  instructions: [
                    `Place the device inside the hive in its normal monitoring position with the colony present`,
                    'This colony must be confirmed healthy — queen present, normal foraging, no signs of stress or disease',
                    'Close the hive and step away',
                    'Make no artificial sounds or vibrations during the scan',
                    'Do not power down the device during the scan',
                  ],
                  instColor: '#f0fdf4', instBorder: '#bbf7d0', instText: '#14532d', instLabel: '#15803d',
                  btnLabel: 'Start Healthy Colony Scan',
                  btnColor: '#10b981',
                },
              };

              // Which step config to show in idle/transition states
              const activeConfig = calPhase === 'done_quiet' ? PHASES.empty_hive
                : calPhase === 'done_empty' ? PHASES.healthy_colony
                : calPhase.startsWith('empty') ? PHASES.empty_hive
                : calPhase.startsWith('healthy') ? PHASES.healthy_colony
                : PHASES.quiet;

              const isRunning = RUNNING_PHASES.includes(calPhase);
              const isSaving  = SAVING_PHASES.includes(calPhase);
              const isIdle    = calPhase === 'idle' || calPhase === 'done_quiet' || calPhase === 'done_empty';
              const progress  = ((calDuration * 60 - calSecondsLeft) / (calDuration * 60)) * 100;

              const stepsDone = {
                quiet: ['done_quiet','done_empty','healthy_idle','healthy_running','healthy_saving','done'].includes(calPhase),
                empty_hive: ['done_empty','healthy_idle','healthy_running','healthy_saving','done'].includes(calPhase),
                healthy_colony: calPhase === 'done',
              };

              return (
              <div className="device-selector">
                <h3>Audio Calibration</h3>
                <p style={{ color: '#6b7280', fontSize: '14px', marginBottom: '16px', lineHeight: '1.6' }}>
                  Three-point calibration teaches the system your device's true noise floor, your hive's acoustic fingerprint, and what a healthy colony sounds like. All three baselines are used to interpret every future reading.
                </p>

                {/* 3-step indicator */}
                <div style={{ display: 'flex', gap: '6px', marginBottom: '20px' }}>
                  {[
                    { key: 'quiet', label: 'Quiet', color: '#6366f1' },
                    { key: 'empty_hive', label: 'Empty Hive', color: '#3b82f6' },
                    { key: 'healthy_colony', label: 'Healthy Colony', color: '#10b981' },
                  ].map(({ key, label, color }) => {
                    const done = stepsDone[key];
                    return (
                      <div key={key} style={{ flex: 1, textAlign: 'center', padding: '8px 4px', borderRadius: '8px',
                        background: done ? '#d1fae5' : '#f3f4f6', border: `1px solid ${done ? '#6ee7b7' : '#e5e7eb'}` }}>
                        <div style={{ fontWeight: 700, fontSize: '12px', color: done ? '#065f46' : '#6b7280' }}>
                          {done ? '✓ ' : ''}{label}
                        </div>
                        {done && <div style={{ fontSize: '10px', color: '#10b981', fontWeight: 600 }}>STORED</div>}
                      </div>
                    );
                  })}
                </div>

                {/* Idle setup panel */}
                {isIdle && (
                  <>
                    <div style={{ fontWeight: 700, fontSize: '15px', color: '#1f2937', marginBottom: '12px' }}>{activeConfig.title}</div>

                    <div style={{ background: activeConfig.instColor, border: `1px solid ${activeConfig.instBorder}`, borderRadius: '10px', padding: '16px', marginBottom: '16px' }}>
                      <div style={{ fontWeight: 700, color: activeConfig.instLabel, marginBottom: '10px', fontSize: '14px' }}>Before you start:</div>
                      <ol style={{ margin: 0, paddingLeft: '20px', fontSize: '14px', color: activeConfig.instText, lineHeight: '2' }}>
                        {activeConfig.instructions.map((inst, i) => <li key={i}>{inst}</li>)}
                      </ol>
                    </div>

                    {(isAfricanized || isStingless) && (
                      <div style={{ background: '#fef2f2', border: '1px solid #fca5a5', borderRadius: '8px', padding: '10px 14px', marginBottom: '16px', fontSize: '13px', color: '#dc2626' }}>
                        {isAfricanized
                          ? 'Africanised bees: 30 min strongly recommended — their elevated baseline activity requires more samples for an accurate healthy profile.'
                          : 'Stingless bees: acoustic profile differs significantly from Apis. 30 min recommended. Note that Apis-derived bee state classifications do not apply.'}
                      </div>
                    )}

                    {calPhase === 'idle' && (
                      <div className="form-group" style={{ marginBottom: '16px' }}>
                        <label style={{ fontWeight: 600, display: 'block', marginBottom: '6px' }}>Select Hive</label>
                        {calHives.length === 0 ? (
                          <p style={{ color: '#9ca3af', fontSize: '14px' }}>No hives found. Add a hive first.</p>
                        ) : (
                          <>
                            <select value={calHiveId} onChange={e => setCalHiveId(e.target.value)} style={{
                              padding: '10px 12px', border: '2px solid #e5e7eb', borderRadius: '10px',
                              width: '100%', fontSize: '14px', background: '#fff', marginBottom: '8px',
                            }}>
                              {calHives.map(h => (
                                <option key={h.id} value={h.id}>
                                  {h.name}{h.location ? ` — ${h.location}` : ''}
                                  {h.calibrated_at ? ` (calibrated ${new Date(h.calibrated_at).toLocaleDateString()})` : ' (not calibrated)'}
                                </option>
                              ))}
                            </select>
                            {selectedHive && (
                              <div style={{ fontSize: '13px', color: '#6b7280', padding: '8px 12px', background: '#f9fafb', borderRadius: '8px' }}>
                                Species: <strong style={{ color: '#1f2937' }}>{speciesName}</strong>
                              </div>
                            )}
                          </>
                        )}
                      </div>
                    )}

                    <div className="form-group" style={{ marginBottom: '24px' }}>
                      <label style={{ fontWeight: 600, display: 'block', marginBottom: '8px' }}>Scan Duration</label>
                      <div style={{ display: 'flex', gap: '10px' }}>
                        {[
                          { mins: 10, label: '10 min', sub: 'Quick' },
                          { mins: 20, label: '20 min', sub: 'Balanced' },
                          { mins: 30, label: '30 min', sub: 'Best accuracy' },
                        ].map(({ mins, label, sub }) => (
                          <button key={mins} onClick={() => setCalDuration(mins)} style={{
                            flex: 1, padding: '12px 8px', borderRadius: '10px', cursor: 'pointer',
                            border: `2px solid ${calDuration === mins ? activeConfig.btnColor : '#e5e7eb'}`,
                            background: calDuration === mins ? activeConfig.instColor : '#f9fafb',
                            textAlign: 'center',
                          }}>
                            <div style={{ fontWeight: 700, fontSize: '15px', color: '#1f2937' }}>{label}</div>
                            <div style={{ fontSize: '11px', color: '#6b7280', marginTop: '2px' }}>{sub}</div>
                          </button>
                        ))}
                      </div>
                    </div>

                    <button onClick={() => startPhase(activeConfig.phaseKey)}
                      disabled={!calHiveId || calHives.length === 0}
                      style={{
                        width: '100%', padding: '14px', border: 'none', borderRadius: '10px',
                        background: calHiveId ? activeConfig.btnColor : '#e5e7eb',
                        color: calHiveId ? '#fff' : '#9ca3af',
                        fontWeight: 700, fontSize: '16px', cursor: calHiveId ? 'pointer' : 'not-allowed',
                      }}>{activeConfig.btnLabel}</button>

                    {(calPhase === 'done_quiet' || calPhase === 'done_empty') && (
                      <button onClick={() => { setCalPhase('idle'); setCalResult(null); fetchCalHives(); }} style={{
                        width: '100%', marginTop: '10px', padding: '12px', background: 'transparent',
                        color: '#6b7280', border: '1px solid #e5e7eb', borderRadius: '10px',
                        fontWeight: 600, fontSize: '14px', cursor: 'pointer',
                      }}>Finish later — progress saved</button>
                    )}
                  </>
                )}

                {/* Running / saving */}
                {(isRunning || isSaving) && (
                  <div style={{ textAlign: 'center', padding: '10px 0' }}>
                    <div style={{ fontSize: '13px', fontWeight: 700, color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '8px' }}>
                      Step {activeConfig.step} of 3
                    </div>
                    <div style={{ fontSize: '18px', fontWeight: 700, color: '#1f2937', marginBottom: '16px' }}>
                      {isSaving ? 'Storing profile...' : activeConfig.scanning + ', please wait'}
                    </div>

                    <div style={{
                      fontSize: '80px', fontWeight: 800, fontFamily: 'monospace',
                      color: calSecondsLeft < 60 ? '#f59e0b' : activeConfig.btnColor,
                      lineHeight: 1, marginBottom: '6px',
                    }}>
                      {isSaving ? '...' : formatCountdown(calSecondsLeft)}
                    </div>
                    <div style={{ color: '#9ca3af', fontSize: '13px', marginBottom: '24px' }}>
                      {isSaving ? '' : 'remaining'}
                    </div>

                    <div style={{ background: '#e5e7eb', borderRadius: '8px', height: '6px', marginBottom: '20px' }}>
                      <div style={{
                        background: activeConfig.btnColor, borderRadius: '8px', height: '6px',
                        width: `${isSaving ? 100 : progress}%`, transition: 'width 1s linear',
                      }} />
                    </div>

                    <div style={{
                      background: '#fef3c7', border: '1px solid #fcd34d',
                      borderRadius: '10px', padding: '14px 16px', marginBottom: '16px', textAlign: 'left',
                    }}>
                      <div style={{ fontWeight: 700, color: '#92400e', fontSize: '14px', marginBottom: '4px' }}>
                        Please maintain silence
                      </div>
                      <div style={{ fontSize: '13px', color: '#78350f', lineHeight: '1.6' }}>
                        Do not power down the device. No machinery, mowing, loud voices, or vibrations near the device while scanning.
                      </div>
                    </div>

                    {isRunning && (
                      <button onClick={cancelCalibration} style={{
                        padding: '10px 24px', background: '#f3f4f6', color: '#6b7280',
                        border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 600, fontSize: '13px',
                      }}>Cancel</button>
                    )}
                  </div>
                )}

                {/* Done — all three phases complete */}
                {calPhase === 'done' && calResult && (
                  <div style={{ textAlign: 'center', padding: '10px 0' }}>
                    <div style={{ fontSize: '52px', marginBottom: '8px' }}>✓</div>
                    <div style={{ fontWeight: 800, fontSize: '20px', color: '#065f46', marginBottom: '4px' }}>
                      Calibration Complete
                    </div>
                    <div style={{ color: '#6b7280', fontSize: '14px', marginBottom: '20px' }}>
                      All three profiles stored for <strong>{selectedHive?.name || 'this hive'}</strong>
                    </div>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '20px', textAlign: 'left' }}>
                      {[
                        { label: 'Colony Avg Level', value: `${calResult.sound_level_db} dB` },
                        { label: 'Readings Used', value: calResult.readings_used },
                        { label: 'SNR Headroom', value: calResult.snr_headroom_db != null ? `${calResult.snr_headroom_db} dB` : 'Calculated after step 1' },
                        { label: 'Species', value: speciesName },
                      ].map(({ label, value }) => (
                        <div key={label} style={{ background: '#f9fafb', borderRadius: '8px', padding: '12px', border: '1px solid #e5e7eb' }}>
                          <div style={{ fontSize: '11px', color: '#9ca3af', fontWeight: 600, textTransform: 'uppercase', marginBottom: '4px' }}>{label}</div>
                          <div style={{ fontWeight: 700, color: '#1f2937', fontSize: '13px' }}>{value}</div>
                        </div>
                      ))}
                    </div>
                    <p style={{ fontSize: '13px', color: '#6b7280', marginBottom: '20px', lineHeight: '1.6' }}>
                      The AI will now interpret all readings relative to this hive's three-point calibration — isolating true bee signal from device and location noise.
                    </p>
                    <button onClick={() => { setCalPhase('idle'); setCalResult(null); fetchCalHives(); }} style={{
                      padding: '12px 28px', background: '#f59e0b', color: '#fff',
                      border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 700,
                    }}>Calibrate Another Hive</button>
                  </div>
                )}

                {calPhase === 'error' && (
                  <div style={{ textAlign: 'center', padding: '10px 0' }}>
                    <div style={{ fontSize: '40px', marginBottom: '12px' }}>⚠️</div>
                    <div style={{ fontWeight: 700, fontSize: '16px', color: '#dc2626', marginBottom: '8px' }}>Scan Failed</div>
                    <div style={{ color: '#6b7280', fontSize: '14px', marginBottom: '24px', lineHeight: '1.6' }}>{calError}</div>
                    <button onClick={() => setCalPhase('idle')} style={{
                      padding: '10px 24px', background: '#f3f4f6', color: '#374151',
                      border: 'none', borderRadius: '8px', cursor: 'pointer', fontWeight: 600,
                    }}>Try Again</button>
                  </div>
                )}
              </div>
              );
            })()}

            {section === 'danger' && (
              <div className="device-selector" style={{ border: '2px solid #fca5a5' }}>
                <h3 style={{ color: '#dc2626' }}>Danger Zone</h3>
                <p style={{ color: '#374151', fontSize: '14px', marginBottom: '20px' }}>
                  Permanently delete your account, including all hives, devices, and sensor readings.
                  This action cannot be undone.
                </p>
                <div style={{ marginBottom: '24px', paddingBottom: '20px', borderBottom: '1px solid #fca5a5' }}>
                  <h4 style={{ margin: '0 0 8px' }}>Download your data first</h4>
                  <p style={{ color: '#374151', fontSize: '14px', marginBottom: '12px' }}>
                    Get a copy of your hives, devices, and readings before you delete your account.
                  </p>
                  <button type="button" onClick={handleExportData} disabled={exporting} style={{
                    padding: '12px 24px', background: '#fff', color: '#374151',
                    border: '2px solid #d1d5db', borderRadius: '10px', fontWeight: 700, cursor: 'pointer',
                  }}>{exporting ? 'Preparing download…' : 'Download My Data'}</button>
                </div>
                <form onSubmit={handleDeleteAccount}>
                  <div className="form-group" style={{ marginBottom: '16px' }}>
                    <label>Confirm your password</label>
                    <input type="password" value={deletePassword} autoComplete="off"
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
