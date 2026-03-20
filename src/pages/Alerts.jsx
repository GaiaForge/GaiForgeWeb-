import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Dashboard.css';

const API_BASE = window.location.origin;

const METRICS = [
  { value: 'temperature', label: 'Temperature (°C)' },
  { value: 'humidity', label: 'Humidity (%)' },
  { value: 'pressure', label: 'Pressure (hPa)' },
  { value: 'sound_level', label: 'Sound Level (dB)' },
  { value: 'bee_state', label: 'Bee State' },
  { value: 'weight_kg', label: 'Weight (kg)' },
  { value: 'battery_voltage', label: 'Battery Voltage (V)' },
];

const OP_LABEL = { gt: 'rises above', lt: 'drops below' };

function Alerts({ user, onLogout }) {
  const navigate = useNavigate();
  const [thresholds, setThresholds] = useState([]);
  const [events, setEvents] = useState([]);
  const [hives, setHives] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);
  const [tab, setTab] = useState('rules'); // 'rules' | 'history'
  const [form, setForm] = useState({
    hive_id: '', metric: 'temperature', operator: 'gt',
    threshold: '', label: '', email_notify: true, cooldown_hours: 4,
  });
  const [formError, setFormError] = useState('');

  const headers = {
    'Authorization': `Bearer ${user?.token}`,
    'Content-Type': 'application/json',
  };

  useEffect(() => {
    Promise.all([fetchThresholds(), fetchEvents(), fetchHives()])
      .finally(() => setLoading(false));
  }, []);

  const fetchThresholds = async () => {
    const res = await fetch(`${API_BASE}/api/alerts`, { headers });
    if (res.ok) setThresholds(await res.json());
  };

  const fetchEvents = async () => {
    const res = await fetch(`${API_BASE}/api/alerts/events?limit=50`, { headers });
    if (res.ok) setEvents(await res.json());
  };

  const fetchHives = async () => {
    const res = await fetch(`${API_BASE}/api/hives`, { headers });
    if (res.ok) setHives(await res.json());
  };

  const handleAddRule = async (e) => {
    e.preventDefault();
    setFormError('');
    if (!form.threshold) { setFormError('Threshold value is required'); return; }
    const body = {
      metric: form.metric,
      operator: form.operator,
      threshold: parseFloat(form.threshold),
      label: form.label || null,
      hive_id: form.hive_id ? parseInt(form.hive_id) : null,
      email_notify: form.email_notify,
      cooldown_hours: parseInt(form.cooldown_hours) || 4,
    };
    const res = await fetch(`${API_BASE}/api/alerts`, {
      method: 'POST', headers, body: JSON.stringify(body),
    });
    if (res.ok) {
      setShowAdd(false);
      setForm({ hive_id: '', metric: 'temperature', operator: 'gt', threshold: '', label: '', email_notify: true, cooldown_hours: 4 });
      fetchThresholds();
    } else {
      const d = await res.json().catch(() => ({}));
      setFormError(d.detail || 'Failed to create rule');
    }
  };

  const toggleActive = async (t) => {
    await fetch(`${API_BASE}/api/alerts/${t.id}`, {
      method: 'PATCH', headers,
      body: JSON.stringify({ is_active: !t.is_active }),
    });
    fetchThresholds();
  };

  const deleteRule = async (id) => {
    if (!window.confirm('Delete this alert rule?')) return;
    await fetch(`${API_BASE}/api/alerts/${id}`, { method: 'DELETE', headers });
    fetchThresholds();
  };

  const handleLogout = () => { onLogout(); navigate('/login'); };

  const hiveName = (id) => {
    if (!id) return 'All Hives';
    const h = hives.find(h => h.id === id);
    return h ? h.name : `Hive ${id}`;
  };

  const metricLabel = (m) => METRICS.find(x => x.value === m)?.label || m;

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
          <Link to="/alerts" className="nav-item active"><span className="nav-icon">🔔</span> Alerts</Link>
          <Link to="/profile" className="nav-item"><span className="nav-icon">👤</span> Profile</Link>
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
            <h1>Alert Rules</h1>
            <p>Get notified when hive metrics cross your thresholds</p>
          </div>
          <button onClick={() => setShowAdd(!showAdd)} style={{
            padding: '10px 20px', background: '#f59e0b', color: '#fff',
            border: 'none', borderRadius: '10px', fontWeight: 600, cursor: 'pointer',
          }}>+ Add Rule</button>
        </header>

        {showAdd && (
          <div className="device-selector" style={{ marginBottom: '24px' }}>
            <h3>New Alert Rule</h3>
            {formError && <div style={{
              background: '#fef2f2', color: '#dc2626', padding: '10px 14px',
              borderRadius: '8px', marginBottom: '12px', fontSize: '14px',
            }}>{formError}</div>}
            <form onSubmit={handleAddRule}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '14px' }}>
                <div className="form-group">
                  <label>Hive</label>
                  <select value={form.hive_id} onChange={e => setForm({ ...form, hive_id: e.target.value })}
                    style={{ padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%' }}>
                    <option value="">All Hives</option>
                    {hives.map(h => <option key={h.id} value={h.id}>{h.name}</option>)}
                  </select>
                </div>
                <div className="form-group">
                  <label>Metric</label>
                  <select value={form.metric} onChange={e => setForm({ ...form, metric: e.target.value })}
                    style={{ padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%' }}>
                    {METRICS.map(m => <option key={m.value} value={m.value}>{m.label}</option>)}
                  </select>
                </div>
                <div className="form-group">
                  <label>Condition</label>
                  <select value={form.operator} onChange={e => setForm({ ...form, operator: e.target.value })}
                    style={{ padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%' }}>
                    <option value="gt">Rises above (&gt;)</option>
                    <option value="lt">Drops below (&lt;)</option>
                  </select>
                </div>
                <div className="form-group">
                  <label>Threshold Value</label>
                  <input type="number" step="any" value={form.threshold}
                    onChange={e => setForm({ ...form, threshold: e.target.value })}
                    placeholder="e.g. 35"
                    style={{ padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%' }} />
                </div>
                <div className="form-group">
                  <label>Label (optional)</label>
                  <input type="text" value={form.label}
                    onChange={e => setForm({ ...form, label: e.target.value })}
                    placeholder="e.g. Overheating warning"
                    style={{ padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%' }} />
                </div>
                <div className="form-group">
                  <label>Cooldown (hours)</label>
                  <input type="number" min="1" value={form.cooldown_hours}
                    onChange={e => setForm({ ...form, cooldown_hours: e.target.value })}
                    style={{ padding: '12px', border: '2px solid #e5e7eb', borderRadius: '10px', width: '100%' }} />
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '16px' }}>
                <input type="checkbox" id="email_notify" checked={form.email_notify}
                  onChange={e => setForm({ ...form, email_notify: e.target.checked })} />
                <label htmlFor="email_notify" style={{ fontWeight: 500 }}>Send email notification to {user?.email}</label>
              </div>
              <button type="submit" style={{
                padding: '12px 24px', background: '#10b981', color: '#fff',
                border: 'none', borderRadius: '10px', fontWeight: 600, cursor: 'pointer',
              }}>Create Rule</button>
            </form>
          </div>
        )}

        {/* Tabs */}
        <div style={{ display: 'flex', gap: '0', marginBottom: '20px', borderBottom: '2px solid #e5e7eb' }}>
          {['rules', 'history'].map(t => (
            <button key={t} onClick={() => setTab(t)} style={{
              padding: '10px 20px', background: 'none', border: 'none',
              borderBottom: tab === t ? '3px solid #f59e0b' : '3px solid transparent',
              marginBottom: '-2px', cursor: 'pointer', fontWeight: tab === t ? 700 : 500,
              color: tab === t ? '#92400e' : '#6b7280', fontSize: '14px', textTransform: 'capitalize',
            }}>{t === 'rules' ? `Rules (${thresholds.length})` : `History (${events.length})`}</button>
          ))}
        </div>

        {loading ? (
          <div className="loading-state">Loading...</div>
        ) : tab === 'rules' ? (
          thresholds.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">🔔</div>
              <h2>No alert rules</h2>
              <p>Add a rule to get notified when hive conditions change.</p>
            </div>
          ) : (
            <div className="uploads-table">
              {thresholds.map(t => (
                <div key={t.id} className="upload-row" style={{ opacity: t.is_active ? 1 : 0.5 }}>
                  <div className="upload-info">
                    <div className="upload-icon">{t.is_active ? '🔔' : '🔕'}</div>
                    <div>
                      <div className="upload-name">
                        {t.label || `${metricLabel(t.metric)} ${OP_LABEL[t.operator]} ${t.threshold}`}
                      </div>
                      <div className="upload-meta">
                        {hiveName(t.hive_id)} · {metricLabel(t.metric)} {OP_LABEL[t.operator]} {t.threshold}
                        {' · '}{t.cooldown_hours}h cooldown
                        {t.last_triggered && ` · Last fired: ${new Date(t.last_triggered).toLocaleDateString()}`}
                      </div>
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                    <span style={{
                      padding: '4px 10px', borderRadius: '10px', fontSize: '12px', fontWeight: 600,
                      background: t.email_notify ? '#dbeafe' : '#f3f4f6',
                      color: t.email_notify ? '#1e40af' : '#6b7280',
                    }}>{t.email_notify ? '✉ Email on' : 'No email'}</span>
                    <button onClick={() => toggleActive(t)} style={{
                      padding: '6px 12px', fontSize: '13px', fontWeight: 600, cursor: 'pointer',
                      background: t.is_active ? '#fef3c7' : '#d1fae5',
                      color: t.is_active ? '#92400e' : '#065f46',
                      border: 'none', borderRadius: '8px',
                    }}>{t.is_active ? 'Disable' : 'Enable'}</button>
                    <button onClick={() => deleteRule(t.id)} style={{
                      padding: '6px 12px', fontSize: '13px', fontWeight: 600, cursor: 'pointer',
                      background: '#fef2f2', color: '#dc2626', border: 'none', borderRadius: '8px',
                    }}>Delete</button>
                  </div>
                </div>
              ))}
            </div>
          )
        ) : (
          events.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">📋</div>
              <h2>No alert history</h2>
              <p>Alert events will appear here when rules are triggered.</p>
            </div>
          ) : (
            <div className="uploads-table">
              {events.map(ev => (
                <div key={ev.id} className="upload-row">
                  <div className="upload-info">
                    <div className="upload-icon">⚠️</div>
                    <div>
                      <div className="upload-name">
                        {metricLabel(ev.metric)} = {ev.value.toFixed(2)} — {hiveName(ev.hive_id)}
                      </div>
                      <div className="upload-meta">
                        {new Date(ev.triggered_at).toLocaleString()}
                        {' · '}{ev.email_sent ? '✉ Email sent' : 'No email'}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )
        )}
      </main>
    </div>
  );
}

export default Alerts;
