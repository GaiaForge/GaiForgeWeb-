import React, { useState, useEffect, useMemo, useRef } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  LineChart, Line, AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
  ComposedChart, Brush, ReferenceLine
} from 'recharts';
import './Dashboard.css';
import './Analytics.css';

const API_BASE = window.location.origin;

const COLORS = {
  temperature: '#ef4444',
  humidity: '#3b82f6',
  pressure: '#8b5cf6',
  sound: '#f59e0b',
  frequency: '#10b981',
  weight: '#6366f1',
  battery: '#22c55e',
  confidence: '#ec4899',
  weather: '#06b6d4',
  foraging: '#84cc16',
  robbing: '#dc2626',
  winter: '#0ea5e9',
};

// Inline info tooltip component
function InfoTip({ text }) {
  const [show, setShow] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    if (!show) return;
    const handler = (e) => { if (ref.current && !ref.current.contains(e.target)) setShow(false); };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [show]);

  return (
    <span ref={ref} style={{ position: 'relative', display: 'inline-block', marginLeft: '6px' }}>
      <button
        onClick={() => setShow(!show)}
        style={{
          width: '16px', height: '16px', borderRadius: '50%', background: '#e5e7eb',
          border: 'none', cursor: 'pointer', fontSize: '10px', fontWeight: '700',
          color: '#6b7280', lineHeight: '16px', padding: 0, verticalAlign: 'middle',
        }}
        title="What is this?"
      >i</button>
      {show && (
        <div style={{
          position: 'absolute', left: '50%', transform: 'translateX(-50%)', bottom: '24px',
          background: '#1f2937', color: '#f9fafb', padding: '10px 14px', borderRadius: '10px',
          fontSize: '13px', lineHeight: '1.5', width: '240px', zIndex: 100,
          boxShadow: '0 8px 24px rgba(0,0,0,0.3)',
        }}>
          {text}
          <div style={{
            position: 'absolute', bottom: '-6px', left: '50%', transform: 'translateX(-50%)',
            width: '12px', height: '12px', background: '#1f2937',
            clipPath: 'polygon(0 0, 100% 0, 50% 100%)',
          }} />
        </div>
      )}
    </span>
  );
}

const BEE_STATE_COLORS = {
  'queen_present': '#f59e0b',
  'normal': '#10b981',
  'stressed': '#ef4444',
  'pre_swarm': '#f97316',
  'swarm': '#dc2626',
  'quiet': '#6b7280',
  'unknown': '#9ca3af',
  'no_signal': '#d1d5db',
};

const BEE_STATE_NAMES = {
  0: 'Unknown', 1: 'Quiet', 2: 'Normal', 3: 'Active',
  4: 'Queen Present', 5: 'Pre-Swarm', 6: 'Defensive',
  7: 'Stressed', 8: 'Queen Missing',
};

function Analytics({ user, onLogout }) {
  const navigate = useNavigate();
  const [hives, setHives] = useState([]);
  const [selectedHive, setSelectedHive] = useState('');
  const [overview, setOverview] = useState(null);
  const [readings, setReadings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [readingsLoading, setReadingsLoading] = useState(false);
  const [aiReport, setAiReport] = useState('');
  const [aiLoading, setAiLoading] = useState(false);
  const [dateRange, setDateRange] = useState(30);
  const [activeTab, setActiveTab] = useState('environmental');
  const [error, setError] = useState('');
  const isPro = user?.subscription_tier === 'pro' || user?.is_admin;
  const [viewMode, setViewMode] = useState(isPro ? (user?.report_mode || 'beekeeper') : 'beekeeper');

  const headers = {
    'Authorization': `Bearer ${user?.token}`,
    'Content-Type': 'application/json',
  };

  useEffect(() => { fetchHives(); }, []);

  useEffect(() => {
    if (selectedHive) { fetchOverview(); fetchReadings(); }
  }, [selectedHive, dateRange]);

  const fetchHives = async () => {
    try {
      const res = await fetch(`${API_BASE}/api/hives`, { headers });
      if (res.ok) {
        const data = await res.json();
        setHives(data);
        if (data.length > 0) setSelectedHive(String(data[0].id));
      }
    } catch (err) { console.error(err); }
    finally { setLoading(false); }
  };

  const fetchOverview = async () => {
    try {
      const res = await fetch(`${API_BASE}/api/analysis/hive/${selectedHive}/overview`, { headers });
      if (res.ok) setOverview(await res.json());
    } catch (err) { console.error(err); }
  };

  const fetchReadings = async () => {
    setReadingsLoading(true);
    try {
      const res = await fetch(
        `${API_BASE}/api/analysis/hive/${selectedHive}/readings?days=${dateRange}`, { headers }
      );
      if (res.ok) {
        const data = await res.json();
        setReadings(data.map(r => ({
          ...r,
          time: new Date(r.timestamp).toLocaleDateString('en-US', {
            month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
          }),
          temperature:    (r.temperature    && r.temperature    !== 0) ? r.temperature    : undefined,
          humidity:       (r.humidity       && r.humidity       !== 0) ? r.humidity       : undefined,
          pressure:       (r.pressure       && r.pressure       !== 0) ? r.pressure       : undefined,
          battery_voltage:(r.battery_voltage && r.battery_voltage !== 0) ? r.battery_voltage : undefined,
          weight:         (r.weight         && r.weight         !== 0) ? r.weight         : undefined,
        })));
      }
    } catch (err) { console.error(err); }
    finally { setReadingsLoading(false); }
  };

  const generateReport = async () => {
    if (user?.subscription_tier !== 'pro' && !user?.is_admin) return;
    setAiLoading(true); setAiReport('');
    try {
      const res = await fetch(`${API_BASE}/api/analysis/hive/${selectedHive}/insights`, { headers });
      if (res.ok) { const data = await res.json(); setAiReport(data.report); }
      else setError('Failed to generate report');
    } catch (err) { setError('Connection error'); }
    finally { setAiLoading(false); }
  };

  // ===== FULL CSV EXPORT (Researcher mode exports ALL columns) =====
  const exportCSV = () => {
    if (readings.length === 0) return;
    const columns = (viewMode === 'researcher' && isPro) ? [
      { key: 'timestamp', label: 'Date & Time' },
      { key: 'temperature', label: 'Temperature (C)' },
      { key: 'humidity', label: 'Humidity (%)' },
      { key: 'pressure', label: 'Pressure (hPa)' },
      { key: 'sound_level', label: 'Sound Level' },
      { key: 'dominant_freq', label: 'Dominant Frequency (Hz)' },
      { key: 'bee_state', label: 'Bee State' },
      { key: 'confidence', label: 'Confidence (%)' },
      { key: 'battery_voltage', label: 'Battery (V)' },
      { key: 'weight', label: 'Weight (kg)' },
      { key: 'spectral_centroid', label: 'Spectral Centroid' },
      { key: 'peak_to_avg', label: 'Peak to Avg Ratio' },
      { key: 'harmonicity', label: 'Harmonicity' },
      { key: 'band_0_200', label: 'Band 0-200 Hz' },
      { key: 'band_200_400', label: 'Band 200-400 Hz' },
      { key: 'band_400_600', label: 'Band 400-600 Hz' },
      { key: 'band_600_800', label: 'Band 600-800 Hz' },
      { key: 'band_800_1000', label: 'Band 800-1000 Hz' },
      { key: 'band_1000_plus', label: 'Band 1000+ Hz' },
      { key: 'spectral_rolloff', label: 'Spectral Rolloff' },
      { key: 'spectral_flux', label: 'Spectral Flux' },
      { key: 'zero_crossing_rate', label: 'Zero Crossing Rate' },
      { key: 'spectral_spread', label: 'Spectral Spread' },
      { key: 'spectral_skewness', label: 'Spectral Skewness' },
      { key: 'spectral_kurtosis', label: 'Spectral Kurtosis' },
      { key: 'short_term_energy', label: 'Short Term Energy' },
      { key: 'mid_term_energy', label: 'Mid Term Energy' },
      { key: 'long_term_energy', label: 'Long Term Energy' },
      { key: 'energy_entropy', label: 'Energy Entropy' },
      { key: 'activity_increase', label: 'Activity Increase' },
      { key: 'ambient_noise_level', label: 'Ambient Noise Level' },
      { key: 'signal_quality', label: 'Signal Quality' },
      { key: 'absconding_risk', label: 'Absconding Risk' },
      { key: 'foraging_score', label: 'Foraging Score' },
      { key: 'robbing_risk', label: 'Robbing Risk' },
      { key: 'winter_cluster', label: 'Winter Cluster' },
      { key: 'weather_confidence', label: 'Weather Confidence' },
    ] : [
      { key: 'timestamp', label: 'Date & Time' },
      { key: 'temperature', label: 'Temperature (C)' },
      { key: 'humidity', label: 'Humidity (%)' },
      { key: 'sound_level', label: 'Sound Level' },
      { key: 'bee_state', label: 'Bee State' },
      { key: 'confidence', label: 'Confidence (%)' },
      { key: 'battery_voltage', label: 'Battery (V)' },
      { key: 'weight', label: 'Weight (kg)' },
    ];
    const header = columns.map(c => c.label).join(',');
    const rows = readings.map(r => columns.map(c => {
      const v = r[c.key];
      if (c.key === 'bee_state') return BEE_STATE_NAMES[v] || v;
      if (c.key === 'timestamp') return new Date(v).toLocaleString();
      if (v == null) return '';
      return typeof v === 'number' ? v.toFixed(4) : v;
    }).join(','));
    const csv = [header, ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = `hive_${selectedHive}_${viewMode}_readings.csv`; a.click();
    URL.revokeObjectURL(url);
  };

  // ===== COMPUTED STATS =====
  const stats = useMemo(() => {
    if (readings.length === 0) return null;
    const get = (key) => readings.filter(r => r[key] != null && r[key] !== 0).map(r => r[key]);
    const avg = arr => arr.length ? (arr.reduce((a, b) => a + b, 0) / arr.length).toFixed(1) : '--';
    const mn = arr => arr.length ? Math.min(...arr).toFixed(1) : '--';
    const mx = arr => arr.length ? Math.max(...arr).toFixed(1) : '--';
    const temps = get('temperature'), hums = get('humidity'), sounds = get('sound_level'), weights = get('weight');
    const weatherConf = get('weather_confidence');
    const weatherAffected = readings.filter(r => r.weather_confidence != null && r.weather_confidence < 50).length;
    return {
      count: readings.length,
      temp: { avg: avg(temps), min: mn(temps), max: mx(temps) },
      humidity: { avg: avg(hums), min: mn(hums), max: mx(hums) },
      sound: { avg: avg(sounds), min: mn(sounds), max: mx(sounds) },
      weight: weights.length > 1 ? {
        current: weights[weights.length - 1].toFixed(1),
        change: (weights[weights.length - 1] - weights[0]).toFixed(1),
      } : null,
      weatherAffectedPct: readings.length > 0 ? ((weatherAffected / readings.length) * 100).toFixed(0) : '0',
      avgWeatherConf: avg(weatherConf),
    };
  }, [readings]);

  const beeStatePie = useMemo(() => {
    if (!overview?.bee_states) return [];
    return overview.bee_states.map(s => ({
      name: (typeof s.state === 'number' ? (BEE_STATE_NAMES[s.state] || 'unknown') : String(s.state)).replace(/_/g, ' '), value: s.count, percentage: s.percentage,
    }));
  }, [overview]);

  const formatMarkdown = (text) => {
    if (!text) return '';
    return text
      .replace(/### (.*)/g, '<h3>$1</h3>')
      .replace(/## (.*)/g, '<h2>$1</h2>')
      .replace(/# (.*)/g, '<h1>$1</h1>')
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.*?)\*/g, '<em>$1</em>')
      .replace(/^- (.*)/gm, '<li>$1</li>')
      .replace(/(<li>.*<\/li>)/s, '<ul>$1</ul>')
      .replace(/\n\n/g, '<br/><br/>');
  };

  const handleLogout = () => { onLogout(); navigate('/login'); };

  const ChartTooltip = ({ active, payload, label }) => {
    if (!active || !payload?.length) return null;
    return (
      <div className="chart-tooltip">
        <p className="tooltip-label">{label}</p>
        {payload.map((p, i) => (
          <p key={i} style={{ color: p.color }}>
            {p.name}: {typeof p.value === 'number' ? p.value.toFixed(2) : p.value}
          </p>
        ))}
      </div>
    );
  };

  // ===== HEALTH SUMMARY (for Beekeeper mode) =====
  const healthSummary = useMemo(() => {
    if (!overview?.health) return null;
    const score = overview.health.score;
    let emoji, message, color;
    if (score >= 80) {
      emoji = '\uD83D\uDC1D'; message = 'Your colony is thriving!'; color = '#10b981';
    } else if (score >= 60) {
      emoji = '\uD83D\uDC4D'; message = 'Colony is doing well, minor items to watch.'; color = '#f59e0b';
    } else if (score >= 40) {
      emoji = '\u26A0\uFE0F'; message = 'Some concerns detected. Consider an inspection.'; color = '#f97316';
    } else {
      emoji = '\uD83D\uDEA8'; message = 'Urgent attention needed!'; color = '#ef4444';
    }
    return { emoji, message, color, score };
  }, [overview]);

  // ===== BEEKEEPER TABS =====
  const freeBeekeeperTabs = [
    ['overview', '\uD83D\uDC1D', 'Colony Status'],
    ['environment', '\uD83C\uDF21\uFE0F', 'Environment'],
    ['weight', '\u2696\uFE0F', 'Weight'],
  ];
  const proBeekeeperTabs = [
    ['overview', '\uD83D\uDC1D', 'Colony Status'],
    ['environment', '\uD83C\uDF21\uFE0F', 'Environment'],
    ['weight', '\u2696\uFE0F', 'Weight'],
    ['ai', '\uD83E\uDD16', 'AI Report'],
  ];
  const beekeeperTabs = isPro ? proBeekeeperTabs : freeBeekeeperTabs;

  // ===== RESEARCHER TABS =====
  const researcherTabs = [
    ['environmental', '\uD83C\uDF21\uFE0F', 'Environmental'],
    ['acoustic', '\uD83D\uDD0A', 'Acoustic'],
    ['spectral', '\uD83D\uDCCA', 'Spectral Features'],
    ['behavioral', '\uD83D\uDC1D', 'Behavioral Scores'],
    ['weather', '\uD83C\uDF27\uFE0F', 'Weather Gate'],
    ['weight', '\u2696\uFE0F', 'Weight'],
    ['battery', '\uD83D\uDD0B', 'Battery'],
    ['quality', '\uD83D\uDCE1', 'Data Quality'],
    ['ai', '\uD83E\uDD16', 'AI Insights'],
  ];

  // Reset tab when switching modes
  useEffect(() => {
    if (viewMode === 'beekeeper') setActiveTab('overview');
    else setActiveTab('environmental');
  }, [viewMode]);

  return (
    <div className="dashboard-container">
      <aside className="sidebar">
        <div className="sidebar-header">
          <a href="/"><img src="/gaiaforge-logo.png" alt="GaiaForge" className="logo-image" /></a>
        </div>
        <nav className="sidebar-nav">
          <a href="/" className="nav-item back-link">
            <span className="nav-icon">&#8592;</span> Back to Site
          </a>
          <Link to="/dashboard" className="nav-item">
            <span className="nav-icon">&#x1F4CA;</span> Dashboard
          </Link>
          <Link to="/analytics" className="nav-item active">
            <span className="nav-icon">&#x1F52C;</span> Analytics
          </Link>
          <Link to="/upload" className="nav-item">
            <span className="nav-icon">&#x2B06;&#xFE0F;</span> Upload Data
          </Link>
          <Link to="/devices" className="nav-item">
            <span className="nav-icon">&#x1F4DF;</span> My Hives
          </Link>
          <Link to="/alerts" className="nav-item">
            <span className="nav-icon">&#x1F514;</span> Alerts
          </Link>
          <Link to="/profile" className="nav-item">
            <span className="nav-icon">&#x1F464;</span> Profile
          </Link>
          {user?.is_admin && <Link to="/admin" className="nav-item">
            <span className="nav-icon">&#x2699;&#xFE0F;</span> Admin
          </Link>}
        </nav>
        <div className="sidebar-footer">
          <button onClick={handleLogout} className="logout-btn">
            <span className="nav-icon">&#x1F6AA;</span> Logout
          </button>
        </div>
      </aside>

      <main className="main-content">
        <header className="content-header">
          <div>
            <h1>Colony Analytics</h1>
            <p>{viewMode === 'beekeeper' ? 'How are your bees doing?' : 'Full sensor data analysis and bioacoustic research tools'}</p>
          </div>
          <div className="header-actions">
            {/* Mode Toggle */}
            <div style={{
              display: 'flex', background: '#f3f4f6', borderRadius: '8px', padding: '2px',
              border: '1px solid #e5e7eb', position: 'relative',
            }}>
              <button
                onClick={() => setViewMode('beekeeper')}
                style={{
                  padding: '6px 14px', borderRadius: '6px', border: 'none', cursor: 'pointer',
                  fontSize: '13px', fontWeight: 600,
                  background: viewMode === 'beekeeper' ? '#f59e0b' : 'transparent',
                  color: viewMode === 'beekeeper' ? '#fff' : '#6b7280',
                }}
              >Beekeeper</button>
              <button
                onClick={() => {
                  if (isPro) { setViewMode('researcher'); }
                  else { setError('Researcher mode requires a Pro subscription. Upgrade in your Profile to unlock full analytics.'); }
                }}
                style={{
                  padding: '6px 14px', borderRadius: '6px', border: 'none', cursor: 'pointer',
                  fontSize: '13px', fontWeight: 600,
                  background: viewMode === 'researcher' ? '#8b5cf6' : 'transparent',
                  color: viewMode === 'researcher' ? '#fff' : isPro ? '#6b7280' : '#d1d5db',
                }}
              >Researcher {!isPro && '\uD83D\uDD12'}</button>
            </div>
            <select value={dateRange} onChange={e => setDateRange(Number(e.target.value))}
              className="range-select">
              <option value={7}>Last 7 days</option>
              <option value={14}>Last 14 days</option>
              <option value={30}>Last 30 days</option>
              <option value={90}>Last 90 days</option>
              <option value={365}>Last year</option>
            </select>
            <button onClick={exportCSV} className="btn-export" disabled={readings.length === 0}>
              Export CSV
            </button>
          </div>
        </header>

        {hives.length > 1 && (
          <div className="hive-selector">
            {hives.map(h => (
              <button key={h.id}
                className={`hive-tab ${selectedHive === String(h.id) ? 'active' : ''}`}
                onClick={() => setSelectedHive(String(h.id))}>
                &#x1F41D; {h.name}
              </button>
            ))}
          </div>
        )}

        {loading ? (
          <div className="loading-state">Loading analytics...</div>
        ) : readings.length === 0 && !readingsLoading ? (
          <div className="empty-state">
            <div className="empty-icon">&#x1F4CA;</div>
            <h2>No data yet</h2>
            <p>Upload sensor readings from your HiveGuard device to see analytics.</p>
            <Link to="/upload" className="btn-primary-link">Upload Data</Link>
          </div>
        ) : (
          <>
            {/* ============================================================
                TAB NAVIGATION
                ============================================================ */}
            <div className="chart-tabs">
              {(viewMode === 'beekeeper' ? beekeeperTabs : researcherTabs).map(([key, icon, label]) => (
                <button key={key}
                  className={`chart-tab ${activeTab === key ? 'active' : ''}`}
                  onClick={() => setActiveTab(key)}>
                  {icon} {label}
                </button>
              ))}
            </div>

            {readingsLoading ? (
              <div className="loading-state">Loading chart data...</div>
            ) : (
              <>
                {/* ============================================================
                    BEEKEEPER: COLONY STATUS (simple health overview)
                    ============================================================ */}
                {activeTab === 'overview' && viewMode === 'beekeeper' && (
                  <div className="chart-section">
                    {/* Big health card */}
                    {healthSummary && (
                      <div className="analytics-card full-width" style={{textAlign: 'center', padding: '40px 24px'}}>
                        <div style={{fontSize: '64px', marginBottom: '12px'}}>{healthSummary.emoji}</div>
                        <div style={{
                          fontSize: '72px', fontWeight: '800', color: healthSummary.color,
                          lineHeight: 1, marginBottom: '8px',
                        }}>{healthSummary.score}</div>
                        <div style={{fontSize: '18px', fontWeight: '600', color: '#1f2937', marginBottom: '4px'}}>
                          Health Score
                        </div>
                        <div style={{fontSize: '16px', color: '#6b7280'}}>{healthSummary.message}</div>
                      </div>
                    )}

                    {/* Simple stat cards */}
                    {stats && (
                      <div className="stats-grid four-col">
                        <div className="stat-card">
                          <div className="stat-icon temp-icon">&#x1F321;&#xFE0F;</div>
                          <div className="stat-content">
                            <div className="stat-value">{stats.temp.avg}&deg;C</div>
                            <div className="stat-label">Hive Temperature</div>
                          </div>
                        </div>
                        <div className="stat-card">
                          <div className="stat-icon hum-icon">&#x1F4A7;</div>
                          <div className="stat-content">
                            <div className="stat-value">{stats.humidity.avg}%</div>
                            <div className="stat-label">Humidity</div>
                          </div>
                        </div>
                        <div className="stat-card">
                          <div className="stat-icon">&#x1F451;</div>
                          <div className="stat-content">
                            <div className="stat-value">{overview?.health?.queen_presence_pct?.toFixed(0) ?? '--'}%</div>
                            <div className="stat-label">Queen Detected</div>
                          </div>
                        </div>
                        <div className="stat-card">
                          <div className="stat-icon">&#x1F50B;</div>
                          <div className="stat-content">
                            <div className="stat-value">
                              {readings.length > 0 && readings[readings.length - 1].battery_voltage
                                ? readings[readings.length - 1].battery_voltage.toFixed(1) + 'V'
                                : '--'}
                            </div>
                            <div className="stat-label">Battery</div>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Bee state pie */}
                    {beeStatePie.length > 0 && (
                      <div className="analytics-card full-width">
                        <h3>What are your bees doing?</h3>
                        <div className="pie-container">
                          <ResponsiveContainer width="100%" height={260}>
                            <PieChart>
                              <Pie data={beeStatePie} dataKey="value" nameKey="name"
                                cx="50%" cy="50%" outerRadius={100} innerRadius={50} paddingAngle={2}>
                                {beeStatePie.map((entry, i) => (
                                  <Cell key={i} fill={Object.values(BEE_STATE_COLORS)[i % Object.values(BEE_STATE_COLORS).length]} />
                                ))}
                              </Pie>
                              <Tooltip formatter={(value, name) => [`${value} readings`, name]} />
                              <Legend />
                            </PieChart>
                          </ResponsiveContainer>
                        </div>
                      </div>
                    )}

                    {/* Weather note for beekeepers */}
                    {stats && Number(stats.weatherAffectedPct) > 5 && (
                      <div className="analytics-card full-width" style={{
                        background: '#f0f9ff', border: '1px solid #bae6fd',
                      }}>
                        <h3 style={{color: '#0369a1'}}>&#x1F327;&#xFE0F; Weather Note</h3>
                        <p style={{color: '#0c4a6e', margin: 0}}>
                          About {stats.weatherAffectedPct}% of readings in this period were affected by weather
                          (rain, wind). These readings have been flagged and won't affect your health score.
                        </p>
                      </div>
                    )}

                    {/* Behavioral summary */}
                    {overview?.behavioral_scores && (
                      <div className="stats-grid four-col">
                        <div className="stat-card">
                          <div className="stat-icon">&#x1F338;</div>
                          <div className="stat-content">
                            <div className="stat-value" style={{color: overview.behavioral_scores.avg_foraging_score >= 50 ? '#16a34a' : '#6b7280'}}>
                              {overview.behavioral_scores.avg_foraging_score ?? '--'}
                            </div>
                            <div className="stat-label">Foraging Activity</div>
                          </div>
                        </div>
                        <div className="stat-card">
                          <div className="stat-icon">&#x2694;&#xFE0F;</div>
                          <div className="stat-content">
                            <div className="stat-value" style={{color: overview.behavioral_scores.max_robbing_risk_pct > 50 ? '#dc2626' : '#16a34a'}}>
                              {overview.behavioral_scores.max_robbing_risk_pct ?? '--'}%
                            </div>
                            <div className="stat-label">Robbing Risk</div>
                          </div>
                        </div>
                        {stats?.weight && (
                          <div className="stat-card">
                            <div className="stat-icon">&#x2696;&#xFE0F;</div>
                            <div className="stat-content">
                              <div className="stat-value">{stats.weight.current} kg</div>
                              <div className="stat-label">Hive Weight</div>
                            </div>
                          </div>
                        )}
                        <div className="stat-card">
                          <div className="stat-icon">&#x1F4CA;</div>
                          <div className="stat-content">
                            <div className="stat-value">{stats?.count?.toLocaleString()}</div>
                            <div className="stat-label">Readings ({dateRange}d)</div>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Gentle upgrade nudge for free users */}
                    {!isPro && (
                      <div className="analytics-card full-width" style={{
                        background: '#f9fafb', border: '1px solid #e5e7eb',
                        padding: '20px 24px',
                      }}>
                        <div style={{display: 'flex', alignItems: 'center', gap: '12px'}}>
                          <span style={{fontSize: '24px'}}>&#x1F52C;</span>
                          <div style={{flex: 1}}>
                            <div style={{fontWeight: 600, color: '#374151', fontSize: '14px'}}>
                              Go deeper with Pro
                            </div>
                            <div style={{color: '#6b7280', fontSize: '13px', marginTop: '2px'}}>
                              AI colony reports, spectral analysis, weather detection, behavioral tracking, and full data export.
                            </div>
                          </div>
                          <Link to="/profile" style={{
                            padding: '8px 16px', background: '#f59e0b',
                            color: '#fff', borderRadius: '8px', fontWeight: 600, textDecoration: 'none',
                            fontSize: '13px', whiteSpace: 'nowrap',
                          }}>Learn more</Link>
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {/* ============================================================
                    BEEKEEPER: ENVIRONMENT (simple temp/humidity)
                    ============================================================ */}
                {activeTab === 'environment' && viewMode === 'beekeeper' && (
                  <div className="chart-section">
                    <div className="analytics-card full-width">
                      <h3>Temperature &amp; Humidity</h3>
                      <p className="chart-description">
                        Ideal hive temperature: 33&ndash;36&deg;C (brood area). Humidity: 40&ndash;60%.
                      </p>
                      <ResponsiveContainer width="100%" height={350}>
                        <ComposedChart data={readings}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis yAxisId="temp" orientation="left" domain={['auto','auto']}
                            label={{value: '\u00B0C', position: 'insideTopLeft'}} />
                          <YAxis yAxisId="hum" orientation="right" domain={[0,100]}
                            label={{value: '%RH', position: 'insideTopRight'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <Legend />
                          <Line yAxisId="temp" type="monotone" dataKey="temperature"
                            name="Temperature (\u00B0C)" stroke={COLORS.temperature} dot={false} strokeWidth={2} />
                          <Line yAxisId="hum" type="monotone" dataKey="humidity"
                            name="Humidity (%)" stroke={COLORS.humidity} dot={false} strokeWidth={2} />
                          <Brush dataKey="time" height={30} stroke="#f59e0b" />
                        </ComposedChart>
                      </ResponsiveContainer>
                    </div>
                  </div>
                )}

                {/* ============================================================
                    RESEARCHER: ENVIRONMENTAL
                    ============================================================ */}
                {activeTab === 'environmental' && viewMode === 'researcher' && (
                  <div className="chart-section">
                    <div className="analytics-card full-width">
                      <h3>Temperature &amp; Humidity Over Time</h3>
                      <ResponsiveContainer width="100%" height={350}>
                        <ComposedChart data={readings}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis yAxisId="temp" orientation="left" domain={['auto','auto']}
                            label={{value: '\u00B0C', position: 'insideTopLeft'}} />
                          <YAxis yAxisId="hum" orientation="right" domain={[0,100]}
                            label={{value: '%RH', position: 'insideTopRight'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <Legend />
                          <Line yAxisId="temp" type="monotone" dataKey="temperature"
                            name="Temperature (\u00B0C)" stroke={COLORS.temperature} dot={false} strokeWidth={2} />
                          <Line yAxisId="hum" type="monotone" dataKey="humidity"
                            name="Humidity (%)" stroke={COLORS.humidity} dot={false} strokeWidth={2} />
                          <Brush dataKey="time" height={30} stroke="#f59e0b" />
                        </ComposedChart>
                      </ResponsiveContainer>
                    </div>

                    {readings.some(r => r.pressure != null) && (
                      <div className="analytics-card full-width">
                        <h3>Barometric Pressure</h3>
                        <ResponsiveContainer width="100%" height={250}>
                          <AreaChart data={readings}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                            <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                            <YAxis domain={['auto','auto']}
                              label={{value: 'hPa', position: 'insideTopLeft'}} />
                            <Tooltip content={<ChartTooltip />} />
                            <Area type="monotone" dataKey="pressure" name="Pressure (hPa)"
                              stroke={COLORS.pressure} fill={COLORS.pressure} fillOpacity={0.1} />
                          </AreaChart>
                        </ResponsiveContainer>
                      </div>
                    )}
                  </div>
                )}

                {/* ============================================================
                    RESEARCHER: ACOUSTIC
                    ============================================================ */}
                {activeTab === 'acoustic' && viewMode === 'researcher' && (
                  <div className="chart-section">
                    <div className="analytics-card full-width">
                      <h3>Sound Level Over Time</h3>
                      <ResponsiveContainer width="100%" height={300}>
                        <AreaChart data={readings}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis label={{value: 'Level', position: 'insideTopLeft'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <Area type="monotone" dataKey="sound_level" name="Sound Level"
                            stroke={COLORS.sound} fill={COLORS.sound} fillOpacity={0.15} strokeWidth={2} />
                          <Brush dataKey="time" height={30} stroke="#f59e0b" />
                        </AreaChart>
                      </ResponsiveContainer>
                    </div>

                    <div className="analytics-card full-width">
                      <h3>Dominant Frequency Analysis</h3>
                      <p className="chart-description">
                        Queen piping: ~450 Hz. Worker buzzing: 200&ndash;250 Hz. Pre-swarm: elevated above 300 Hz.
                      </p>
                      <ResponsiveContainer width="100%" height={300}>
                        <ComposedChart data={readings}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis label={{value: 'Hz', position: 'insideTopLeft'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <ReferenceLine y={450} stroke="#f59e0b" strokeDasharray="5 5"
                            label={{value: "Queen (~450 Hz)", position: "right", fill: "#f59e0b", fontSize: 11}} />
                          <ReferenceLine y={225} stroke="#10b981" strokeDasharray="5 5"
                            label={{value: "Worker (~225 Hz)", position: "right", fill: "#10b981", fontSize: 11}} />
                          <Line type="monotone" dataKey="dominant_freq" name="Dominant Freq (Hz)"
                            stroke={COLORS.frequency} dot={false} strokeWidth={2} />
                          <Brush dataKey="time" height={30} stroke="#f59e0b" />
                        </ComposedChart>
                      </ResponsiveContainer>
                    </div>

                    <div className="analytics-card full-width">
                      <h3>Classification Confidence</h3>
                      <ResponsiveContainer width="100%" height={250}>
                        <AreaChart data={readings}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis domain={[0, 100]} label={{value: '%', position: 'insideTopLeft'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <ReferenceLine y={60} stroke="#ef4444" strokeDasharray="3 3"
                            label={{value: "Alert Threshold", position: "right", fill: "#ef4444", fontSize: 11}} />
                          <Area type="monotone" dataKey="confidence" name="Confidence (%)"
                            stroke={COLORS.confidence} fill={COLORS.confidence} fillOpacity={0.15} strokeWidth={2} />
                        </AreaChart>
                      </ResponsiveContainer>
                    </div>
                  </div>
                )}

                {/* ============================================================
                    RESEARCHER: SPECTRAL FEATURES (all features)
                    ============================================================ */}
                {activeTab === 'spectral' && viewMode === 'researcher' && (
                  <div className="chart-section">
                    <div className="analytics-card full-width">
                      <h3>
                        Spectral Centroid &amp; Harmonicity
                        <InfoTip text="Centroid is the pitch center of the hive sound. Harmonicity measures how tonal vs. noisy — queen piping scores 0.7+, weather noise scores below 0.15." />
                      </h3>
                      <ResponsiveContainer width="100%" height={320}>
                        <ComposedChart data={readings}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis yAxisId="cent" orientation="left" domain={['auto','auto']}
                            label={{value: 'Hz', position: 'insideTopLeft'}} />
                          <YAxis yAxisId="harm" orientation="right" domain={[0,1]}
                            label={{value: 'Harmonicity', position: 'insideTopRight'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <Legend />
                          <Line yAxisId="cent" type="monotone" dataKey="spectral_centroid"
                            name="Spectral Centroid (Hz)" stroke="#8b5cf6" dot={false} strokeWidth={2} />
                          <Line yAxisId="harm" type="monotone" dataKey="harmonicity"
                            name="Harmonicity" stroke="#10b981" dot={false} strokeWidth={2} />
                          <Brush dataKey="time" height={30} stroke="#f59e0b" />
                        </ComposedChart>
                      </ResponsiveContainer>
                    </div>

                    <div className="analytics-card full-width">
                      <h3>
                        Mel-Band Energy Distribution
                        <InfoTip text="6 mel-spaced frequency bands. Healthy colonies concentrate energy in 200-600 Hz. Flat distribution across all bands indicates broadband noise (rain, wind)." />
                      </h3>
                      <ResponsiveContainer width="100%" height={320}>
                        <AreaChart data={readings}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis label={{value: 'Energy', position: 'insideTopLeft'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <Legend />
                          <Area type="monotone" dataKey="band_0_200" name="0-200 Hz" stackId="1"
                            stroke="#6366f1" fill="#6366f1" fillOpacity={0.6} />
                          <Area type="monotone" dataKey="band_200_400" name="200-400 Hz" stackId="1"
                            stroke="#f59e0b" fill="#f59e0b" fillOpacity={0.6} />
                          <Area type="monotone" dataKey="band_400_600" name="400-600 Hz" stackId="1"
                            stroke="#10b981" fill="#10b981" fillOpacity={0.6} />
                          <Area type="monotone" dataKey="band_600_800" name="600-800 Hz" stackId="1"
                            stroke="#ef4444" fill="#ef4444" fillOpacity={0.6} />
                          <Area type="monotone" dataKey="band_800_1000" name="800-1000 Hz" stackId="1"
                            stroke="#8b5cf6" fill="#8b5cf6" fillOpacity={0.6} />
                          <Area type="monotone" dataKey="band_1000_plus" name="1000+ Hz" stackId="1"
                            stroke="#6b7280" fill="#6b7280" fillOpacity={0.6} />
                        </AreaChart>
                      </ResponsiveContainer>
                    </div>

                    <div className="analytics-row">
                      <div className="analytics-card">
                        <h3>Spectral Shape</h3>
                        <ResponsiveContainer width="100%" height={250}>
                          <LineChart data={readings}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                            <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                            <YAxis />
                            <Tooltip content={<ChartTooltip />} />
                            <Legend />
                            <Line type="monotone" dataKey="spectral_rolloff" name="Rolloff (Hz)" stroke="#8b5cf6" dot={false} />
                            <Line type="monotone" dataKey="spectral_flux" name="Spectral Flux" stroke="#06b6d4" dot={false} />
                            <Line type="monotone" dataKey="zero_crossing_rate" name="ZCR" stroke="#ef4444" dot={false} />
                            <Line type="monotone" dataKey="peak_to_avg" name="Peak-to-Avg" stroke="#f59e0b" dot={false} />
                          </LineChart>
                        </ResponsiveContainer>
                      </div>

                      <div className="analytics-card">
                        <h3>Spectral Distribution</h3>
                        <ResponsiveContainer width="100%" height={250}>
                          <LineChart data={readings}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                            <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                            <YAxis />
                            <Tooltip content={<ChartTooltip />} />
                            <Legend />
                            <Line type="monotone" dataKey="spectral_spread" name="Spread" stroke="#10b981" dot={false} />
                            <Line type="monotone" dataKey="spectral_skewness" name="Skewness" stroke="#f97316" dot={false} />
                            <Line type="monotone" dataKey="spectral_kurtosis" name="Kurtosis" stroke="#ec4899" dot={false} />
                          </LineChart>
                        </ResponsiveContainer>
                      </div>
                    </div>

                    <div className="analytics-card full-width">
                      <h3>Temporal Energy (Short / Mid / Long Term)</h3>
                      <ResponsiveContainer width="100%" height={280}>
                        <ComposedChart data={readings}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis yAxisId="energy" orientation="left" />
                          <YAxis yAxisId="ratio" orientation="right"
                            label={{value: 'Ratio', position: 'insideTopRight'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <Legend />
                          <Line yAxisId="energy" type="monotone" dataKey="short_term_energy"
                            name="Short-Term" stroke="#10b981" dot={false} />
                          <Line yAxisId="energy" type="monotone" dataKey="mid_term_energy"
                            name="Mid-Term" stroke="#3b82f6" dot={false} />
                          <Line yAxisId="energy" type="monotone" dataKey="long_term_energy"
                            name="Long-Term" stroke="#8b5cf6" dot={false} />
                          <Line yAxisId="ratio" type="monotone" dataKey="activity_increase"
                            name="Activity Increase" stroke="#f59e0b" dot={false} strokeWidth={2} />
                          <Line yAxisId="energy" type="monotone" dataKey="energy_entropy"
                            name="Energy Entropy" stroke="#ef4444" dot={false} strokeDasharray="5 5" />
                        </ComposedChart>
                      </ResponsiveContainer>
                    </div>

                    {/* All spectral stats */}
                    <div className="analytics-card full-width">
                      <h3>Spectral Statistics Summary</h3>
                      <div style={{display:'grid', gridTemplateColumns:'repeat(auto-fill, minmax(180px,1fr))', gap:'12px', padding:'8px 0'}}>
                        {[
                          {key:'spectral_centroid', label:'Centroid', unit:'Hz'},
                          {key:'harmonicity', label:'Harmonicity', unit:''},
                          {key:'spectral_spread', label:'Spread', unit:'Hz'},
                          {key:'spectral_skewness', label:'Skewness', unit:''},
                          {key:'spectral_kurtosis', label:'Kurtosis', unit:''},
                          {key:'spectral_rolloff', label:'Rolloff', unit:'Hz'},
                          {key:'spectral_flux', label:'Flux', unit:''},
                          {key:'zero_crossing_rate', label:'ZCR', unit:''},
                          {key:'peak_to_avg', label:'Peak/Avg', unit:''},
                          {key:'energy_entropy', label:'Entropy', unit:''},
                          {key:'short_term_energy', label:'ST Energy', unit:''},
                          {key:'mid_term_energy', label:'MT Energy', unit:''},
                          {key:'long_term_energy', label:'LT Energy', unit:''},
                          {key:'activity_increase', label:'Activity Inc.', unit:'x'},
                        ].map(({key, label, unit}) => {
                          const vals = readings.filter(r => r[key] != null).map(r => r[key]);
                          const avg = vals.length ? (vals.reduce((a,b) => a+b, 0)/vals.length).toFixed(3) : '--';
                          const latest = vals.length ? vals[vals.length-1].toFixed(3) : '--';
                          const min = vals.length ? Math.min(...vals).toFixed(3) : '--';
                          const max = vals.length ? Math.max(...vals).toFixed(3) : '--';
                          return (
                            <div key={key} style={{
                              background:'#f9fafb', borderRadius:'8px', padding:'12px',
                              border:'1px solid #e5e7eb', fontSize: '13px',
                            }}>
                              <div style={{fontWeight:700, marginBottom:'4px'}}>{label}</div>
                              <div style={{fontSize:'18px', fontWeight:'800', color:'#1f2937'}}>{latest}{unit}</div>
                              <div style={{color:'#6b7280', marginTop:'2px'}}>
                                avg {avg} | min {min} | max {max}
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  </div>
                )}

                {/* ============================================================
                    RESEARCHER: BEHAVIORAL SCORES
                    ============================================================ */}
                {activeTab === 'behavioral' && viewMode === 'researcher' && (
                  <div className="chart-section">
                    <div className="analytics-card full-width">
                      <h3>
                        Foraging Score
                        <InfoTip text="0-100 intensity of foraging activity. Based on mel band 0 (worker flight buzz at 200-250 Hz) scaled by time of day. Only active during daylight hours (6am-7pm)." />
                      </h3>
                      <ResponsiveContainer width="100%" height={280}>
                        <AreaChart data={readings}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis domain={[0, 100]} label={{value: 'Score', position: 'insideTopLeft'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <Area type="monotone" dataKey="foraging_score" name="Foraging Score"
                            stroke={COLORS.foraging} fill={COLORS.foraging} fillOpacity={0.2} strokeWidth={2} />
                          <Brush dataKey="time" height={30} stroke="#f59e0b" />
                        </AreaChart>
                      </ResponsiveContainer>
                    </div>

                    <div className="analytics-card full-width">
                      <h3>
                        Robbing Risk
                        <InfoTip text="0-100 probability of active robbing attack. Based on spectral flux spikes, elevated mid-high band energy, and low harmonicity (chaotic mob sound). Active during afternoon foraging hours." />
                      </h3>
                      <ResponsiveContainer width="100%" height={280}>
                        <AreaChart data={readings}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis domain={[0, 100]} label={{value: '%', position: 'insideTopLeft'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <ReferenceLine y={50} stroke="#ef4444" strokeDasharray="3 3"
                            label={{value: "High Risk", position: "right", fill: "#ef4444", fontSize: 11}} />
                          <Area type="monotone" dataKey="robbing_risk" name="Robbing Risk (%)"
                            stroke={COLORS.robbing} fill={COLORS.robbing} fillOpacity={0.15} strokeWidth={2} />
                        </AreaChart>
                      </ResponsiveContainer>
                    </div>

                    <div className="analytics-row">
                      <div className="analytics-card">
                        <h3>
                          Winter Cluster Health
                          <InfoTip text="0-100 health score for winter cluster. Only active when hive temp < 15C. Based on band 0 dominance (thermal regulation hum), spectral stability, and sound level in the 15-45 range." />
                        </h3>
                        <ResponsiveContainer width="100%" height={250}>
                          <AreaChart data={readings}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                            <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                            <YAxis domain={[0, 100]} />
                            <Tooltip content={<ChartTooltip />} />
                            <Area type="monotone" dataKey="winter_cluster" name="Winter Cluster"
                              stroke={COLORS.winter} fill={COLORS.winter} fillOpacity={0.2} strokeWidth={2} />
                          </AreaChart>
                        </ResponsiveContainer>
                      </div>

                      <div className="analytics-card">
                        <h3>Absconding Risk</h3>
                        <ResponsiveContainer width="100%" height={250}>
                          <AreaChart data={readings}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                            <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                            <YAxis domain={[0, 100]} />
                            <Tooltip content={<ChartTooltip />} />
                            <ReferenceLine y={30} stroke="#f97316" strokeDasharray="3 3"
                              label={{value: "Inspect", position: "right", fill: "#f97316", fontSize: 11}} />
                            <Area type="monotone" dataKey="absconding_risk" name="Absconding Risk (%)"
                              stroke="#ef4444" fill="#ef4444" fillOpacity={0.15} strokeWidth={2} />
                          </AreaChart>
                        </ResponsiveContainer>
                      </div>
                    </div>
                  </div>
                )}

                {/* ============================================================
                    RESEARCHER: WEATHER GATE
                    ============================================================ */}
                {activeTab === 'weather' && viewMode === 'researcher' && (
                  <div className="chart-section">
                    <div className="analytics-card full-width" style={{
                      background: '#f0f9ff', border: '1px solid #bae6fd',
                    }}>
                      <h3 style={{color: '#0369a1'}}>Weather Confidence Overview</h3>
                      <p style={{color: '#0c4a6e', margin: 0}}>
                        Weather confidence (0-100) indicates how likely the audio data is free from weather
                        contamination. Readings below 50 are flagged as weather-affected. Currently <strong>{stats?.weatherAffectedPct ?? 0}%</strong> of
                        readings are flagged. Avg confidence: <strong>{stats?.avgWeatherConf ?? '--'}</strong>.
                      </p>
                    </div>

                    <div className="analytics-card full-width">
                      <h3>
                        Weather Confidence Over Time
                        <InfoTip text="100 = clean audio (no weather). 0 = likely rain/wind contamination. Combines audio features (harmonicity, ZCR, band flatness) with environmental sensors (humidity >85%, falling pressure). Readings below 50 are excluded from health scoring." />
                      </h3>
                      <ResponsiveContainer width="100%" height={300}>
                        <ComposedChart data={readings}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis yAxisId="conf" domain={[0, 100]}
                            label={{value: '%', position: 'insideTopLeft'}} />
                          <YAxis yAxisId="hum" orientation="right" domain={[0, 100]}
                            label={{value: '%RH', position: 'insideTopRight'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <Legend />
                          <ReferenceLine yAxisId="conf" y={50} stroke="#ef4444" strokeDasharray="3 3"
                            label={{value: "Weather Threshold", position: "right", fill: "#ef4444", fontSize: 11}} />
                          <Area yAxisId="conf" type="monotone" dataKey="weather_confidence"
                            name="Weather Confidence (%)" stroke={COLORS.weather} fill={COLORS.weather}
                            fillOpacity={0.15} strokeWidth={2} />
                          <Line yAxisId="hum" type="monotone" dataKey="humidity"
                            name="Humidity (%)" stroke={COLORS.humidity} dot={false} strokeWidth={1}
                            strokeDasharray="3 3" />
                          <Brush dataKey="time" height={30} stroke="#f59e0b" />
                        </ComposedChart>
                      </ResponsiveContainer>
                    </div>

                    <div className="analytics-card full-width">
                      <h3>Weather Indicators: Harmonicity vs ZCR vs Pressure</h3>
                      <p className="chart-description">
                        Low harmonicity + high ZCR + falling pressure = weather event.
                        Bees: harmonicity &gt; 0.3, ZCR &lt; 0.25. Rain: harmonicity &lt; 0.1, ZCR &gt; 0.35.
                      </p>
                      <ResponsiveContainer width="100%" height={300}>
                        <ComposedChart data={readings}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis yAxisId="feat" domain={[0, 1]}
                            label={{value: 'Value', position: 'insideTopLeft'}} />
                          <YAxis yAxisId="press" orientation="right" domain={['auto', 'auto']}
                            label={{value: 'hPa', position: 'insideTopRight'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <Legend />
                          <Line yAxisId="feat" type="monotone" dataKey="harmonicity"
                            name="Harmonicity" stroke="#10b981" dot={false} strokeWidth={2} />
                          <Line yAxisId="feat" type="monotone" dataKey="zero_crossing_rate"
                            name="ZCR" stroke="#ef4444" dot={false} strokeWidth={2} />
                          <Line yAxisId="press" type="monotone" dataKey="pressure"
                            name="Pressure (hPa)" stroke={COLORS.pressure} dot={false} strokeWidth={1}
                            strokeDasharray="3 3" />
                        </ComposedChart>
                      </ResponsiveContainer>
                    </div>
                  </div>
                )}

                {/* ============================================================
                    SHARED: WEIGHT
                    ============================================================ */}
                {activeTab === 'weight' && (
                  <div className="chart-section">
                    {readings.some(r => r.weight != null) ? (
                      <>
                        <div className="analytics-card full-width">
                          <h3>Hive Weight Trend</h3>
                          <p className="chart-description">
                            Weight changes indicate nectar flow, consumption, or swarming events.
                            Sudden drops (&gt;1 kg) may indicate swarming.
                          </p>
                          <ResponsiveContainer width="100%" height={350}>
                            <AreaChart data={readings.filter(r => r.weight != null)}>
                              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                              <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                              <YAxis domain={['auto','auto']}
                                label={{value: 'kg', position: 'insideTopLeft'}} />
                              <Tooltip content={<ChartTooltip />} />
                              <Area type="monotone" dataKey="weight" name="Weight (kg)"
                                stroke={COLORS.weight} fill={COLORS.weight} fillOpacity={0.15} strokeWidth={2} />
                              <Brush dataKey="time" height={30} stroke="#f59e0b" />
                            </AreaChart>
                          </ResponsiveContainer>
                        </div>
                        {stats?.weight && (
                          <div className="analytics-row">
                            <div className="analytics-card">
                              <h3>Current Weight</h3>
                              <div className="big-number">{stats.weight.current} kg</div>
                            </div>
                            <div className="analytics-card">
                              <h3>Weight Change ({dateRange}d)</h3>
                              <div className={`big-number ${Number(stats.weight.change) >= 0 ? 'positive' : 'negative'}`}>
                                {Number(stats.weight.change) >= 0 ? '+' : ''}{stats.weight.change} kg
                              </div>
                            </div>
                          </div>
                        )}
                      </>
                    ) : (
                      <div className="analytics-card full-width">
                        <div className="empty-chart">
                          <h3>No Weight Data</h3>
                          <p>Connect an HX711 load cell to your HiveGuard device to track hive weight.</p>
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {/* ============================================================
                    RESEARCHER: BATTERY
                    ============================================================ */}
                {activeTab === 'battery' && viewMode === 'researcher' && (
                  <div className="chart-section">
                    <div className="analytics-card full-width">
                      <h3>Battery Voltage Over Time</h3>
                      <p className="chart-description">
                        Low battery: 3.6V. Critical (LDO dropout): 3.3V. Above 4.8V = USB power.
                      </p>
                      <ResponsiveContainer width="100%" height={300}>
                        <LineChart data={readings.filter(r => r.battery_voltage != null)}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis domain={['auto','auto']}
                            label={{value: 'V', position: 'insideTopLeft'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <ReferenceLine y={3.6} stroke="#f59e0b" strokeDasharray="5 5"
                            label={{value: "Low", position: "right", fill: "#f59e0b", fontSize: 11}} />
                          <ReferenceLine y={3.3} stroke="#ef4444" strokeDasharray="5 5"
                            label={{value: "Critical", position: "right", fill: "#ef4444", fontSize: 11}} />
                          <Line type="monotone" dataKey="battery_voltage" name="Battery (V)"
                            stroke={COLORS.battery} dot={false} strokeWidth={2} />
                        </LineChart>
                      </ResponsiveContainer>
                    </div>
                  </div>
                )}

                {/* ============================================================
                    RESEARCHER: DATA QUALITY
                    ============================================================ */}
                {activeTab === 'quality' && viewMode === 'researcher' && (
                  <div className="chart-section">
                    <div className="analytics-card full-width">
                      <h3>Signal Quality &amp; Ambient Noise</h3>
                      <ResponsiveContainer width="100%" height={300}>
                        <ComposedChart data={readings}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis yAxisId="qual" domain={[0, 100]}
                            label={{value: '%', position: 'insideTopLeft'}} />
                          <YAxis yAxisId="noise" orientation="right"
                            label={{value: 'Noise', position: 'insideTopRight'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <Legend />
                          <Line yAxisId="qual" type="monotone" dataKey="signal_quality"
                            name="Signal Quality (%)" stroke="#10b981" dot={false} strokeWidth={2} />
                          <Line yAxisId="qual" type="monotone" dataKey="weather_confidence"
                            name="Weather Confidence (%)" stroke={COLORS.weather} dot={false} strokeWidth={2} />
                          <Line yAxisId="noise" type="monotone" dataKey="ambient_noise_level"
                            name="Ambient Noise" stroke="#6b7280" dot={false} strokeWidth={1} />
                          <Brush dataKey="time" height={30} stroke="#f59e0b" />
                        </ComposedChart>
                      </ResponsiveContainer>
                    </div>
                  </div>
                )}

                {/* ============================================================
                    SHARED: AI INSIGHTS
                    ============================================================ */}
                {activeTab === 'ai' && (
                  <div className="chart-section">
                    <div className="analytics-card full-width ai-card">
                      <h3>AI Colony Report</h3>
                      {user?.subscription_tier !== 'pro' && !user?.is_admin ? (
                        <div className="pro-upgrade">
                          <h4>Pro Feature</h4>
                          <p>AI-powered colony analysis generates detailed reports with health assessments,
                             actionable recommendations, and trend analysis tailored to your hive data.</p>
                          <p className="pro-cta">Upgrade to Pro to unlock AI insights.</p>
                        </div>
                      ) : (
                        <>
                          <p className="chart-description">
                            Claude AI analyzes your sensor readings and generates a comprehensive colony health
                            report with findings, concerns, and recommendations.
                            {viewMode === 'researcher' && ' In researcher mode, the report includes spectral feature analysis, weather event correlation, and data quality assessment.'}
                          </p>
                          <button onClick={generateReport}
                            disabled={aiLoading || readings.length === 0}
                            className="btn-generate">
                            {aiLoading ? 'Analyzing colony data...' : 'Generate Colony Report'}
                          </button>
                          {aiLoading && (
                            <div className="ai-loading">
                              <div className="ai-spinner"></div>
                              <p>Claude is analyzing {readings.length} readings across {dateRange} days...</p>
                            </div>
                          )}
                          {aiReport && (
                            <div className="ai-report"
                              dangerouslySetInnerHTML={{__html: formatMarkdown(aiReport)}} />
                          )}
                        </>
                      )}
                    </div>
                  </div>
                )}

                {/* ============================================================
                    RAW DATA TABLE (Researcher only)
                    ============================================================ */}
                {viewMode === 'researcher' && readings.length > 0 && activeTab !== 'ai' && (
                  <div className="analytics-card full-width">
                    <div className="table-header">
                      <h3>Raw Readings</h3>
                      <span className="reading-count">Showing last 50 of {readings.length}</span>
                    </div>
                    <div className="table-scroll">
                      <table className="data-table">
                        <thead>
                          <tr>
                            <th>Timestamp</th>
                            <th>Temp</th>
                            <th>Hum</th>
                            <th>Press</th>
                            <th>Sound</th>
                            <th>Freq</th>
                            <th>State</th>
                            <th>Conf</th>
                            <th>Harm</th>
                            <th>Forage</th>
                            <th>Rob</th>
                            <th>Weather</th>
                            <th>Battery</th>
                            <th>Weight</th>
                          </tr>
                        </thead>
                        <tbody>
                          {readings.slice(-50).reverse().map((r, i) => (
                            <tr key={i} style={r.weather_confidence != null && r.weather_confidence < 50 ? {background: '#fef3c7'} : {}}>
                              <td className="td-timestamp">{new Date(r.timestamp).toLocaleString()}</td>
                              <td>{r.temperature?.toFixed(1) ?? '\u2014'}</td>
                              <td>{r.humidity?.toFixed(1) ?? '\u2014'}</td>
                              <td>{r.pressure?.toFixed(0) ?? '\u2014'}</td>
                              <td>{r.sound_level?.toFixed(1) ?? '\u2014'}</td>
                              <td>{r.dominant_freq?.toFixed(0) ?? '\u2014'}</td>
                              <td><span className={`state-badge ${BEE_STATE_NAMES[r.bee_state] || r.bee_state}`}>
                                {(typeof r.bee_state === 'number' ? (BEE_STATE_NAMES[r.bee_state] || 'unknown') : String(r.bee_state || '')).replace(/_/g, ' ')}</span></td>
                              <td>{r.confidence?.toFixed(0) ?? '\u2014'}%</td>
                              <td>{r.harmonicity?.toFixed(2) ?? '\u2014'}</td>
                              <td>{r.foraging_score ?? '\u2014'}</td>
                              <td>{r.robbing_risk ?? '\u2014'}</td>
                              <td style={{color: r.weather_confidence != null && r.weather_confidence < 50 ? '#dc2626' : '#16a34a'}}>
                                {r.weather_confidence ?? '\u2014'}
                              </td>
                              <td>{r.battery_voltage?.toFixed(2) ?? '\u2014'}</td>
                              <td>{r.weight?.toFixed(1) ?? '\u2014'}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                )}
              </>
            )}
          </>
        )}
      </main>
    </div>
  );
}

export default Analytics;
