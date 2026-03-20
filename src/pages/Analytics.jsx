import React, { useState, useEffect, useMemo } from 'react';
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
};

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
          temperature: r.temperature || null,
          humidity: r.humidity || null,
          pressure: r.pressure || null,
          time: new Date(r.timestamp).toLocaleDateString('en-US', {
            month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit'
          }),
        })));
      }
    } catch (err) { console.error(err); }
    finally { setReadingsLoading(false); }
  };

  const generateReport = async () => {
    if (user?.subscription_tier !== 'pro') return;
    setAiLoading(true); setAiReport('');
    try {
      const res = await fetch(`${API_BASE}/api/analysis/hive/${selectedHive}/insights`, { headers });
      if (res.ok) { const data = await res.json(); setAiReport(data.report); }
      else setError('Failed to generate report');
    } catch (err) { setError('Connection error'); }
    finally { setAiLoading(false); }
  };

  const BEE_STATE_NAMES = {
    0: 'Unknown', 1: 'Quiet', 2: 'Normal', 3: 'Active',
    4: 'Queen Present', 5: 'Pre-Swarm', 6: 'Defensive',
    7: 'Stressed', 8: 'Queen Missing',
  };

  const exportCSV = () => {
    if (readings.length === 0) return;
    const columns = [
      { key: 'timestamp', label: 'Date & Time' },
      { key: 'temperature', label: 'Temperature (C)' },
      { key: 'humidity', label: 'Humidity (%)' },
      { key: 'pressure', label: 'Pressure (hPa)' },
      { key: 'sound_level', label: 'Sound Level (dB)' },
      { key: 'dominant_freq', label: 'Dominant Frequency (Hz)' },
      { key: 'bee_state', label: 'Bee State' },
      { key: 'confidence', label: 'Confidence (%)' },
      { key: 'battery_voltage', label: 'Battery (V)' },
      { key: 'weight', label: 'Weight (kg)' },
      { key: 'spectral_centroid', label: 'Spectral Centroid' },
      { key: 'harmonicity', label: 'Harmonicity' },
      { key: 'signal_quality', label: 'Signal Quality (%)' },
      { key: 'absconding_risk', label: 'Absconding Risk (%)' },
    ];
    const header = columns.map(c => c.label).join(',');
    const rows = readings.map(r => columns.map(c => {
      const v = r[c.key];
      if (c.key === 'bee_state') return BEE_STATE_NAMES[v] || v;
      if (c.key === 'timestamp') return new Date(v).toLocaleString();
      if (v == null) return '';
      return typeof v === 'number' ? v.toFixed(2) : v;
    }).join(','));
    const csv = [header, ...rows].join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = `hive_${selectedHive}_readings.csv`; a.click();
    URL.revokeObjectURL(url);
  };

  const stats = useMemo(() => {
    if (readings.length === 0) return null;
    const get = (key) => readings.filter(r => r[key] != null).map(r => r[key]);
    const avg = arr => arr.length ? (arr.reduce((a, b) => a + b, 0) / arr.length).toFixed(1) : '--';
    const mn = arr => arr.length ? Math.min(...arr).toFixed(1) : '--';
    const mx = arr => arr.length ? Math.max(...arr).toFixed(1) : '--';
    const temps = get('temperature'), hums = get('humidity'), sounds = get('sound_level'), weights = get('weight');
    return {
      count: readings.length,
      temp: { avg: avg(temps), min: mn(temps), max: mx(temps) },
      humidity: { avg: avg(hums), min: mn(hums), max: mx(hums) },
      sound: { avg: avg(sounds), min: mn(sounds), max: mx(sounds) },
      weight: weights.length > 1 ? {
        current: weights[weights.length - 1].toFixed(1),
        change: (weights[weights.length - 1] - weights[0]).toFixed(1),
      } : null,
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
            {p.name}: {typeof p.value === 'number' ? p.value.toFixed(1) : p.value}
          </p>
        ))}
      </div>
    );
  };

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
            <p>Sensor data analysis and bioacoustic insights</p>
          </div>
          <div className="header-actions">
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
            {/* Summary Cards */}
            {stats && (
              <div className="stats-grid four-col">
                <div className="stat-card">
                  <div className="stat-icon temp-icon">&#x1F321;&#xFE0F;</div>
                  <div className="stat-content">
                    <div className="stat-value">{stats.temp.avg}&deg;C</div>
                    <div className="stat-label">Avg Temperature</div>
                    <div className="stat-range">{stats.temp.min}&deg; &ndash; {stats.temp.max}&deg;</div>
                  </div>
                </div>
                <div className="stat-card">
                  <div className="stat-icon hum-icon">&#x1F4A7;</div>
                  <div className="stat-content">
                    <div className="stat-value">{stats.humidity.avg}%</div>
                    <div className="stat-label">Avg Humidity</div>
                    <div className="stat-range">{stats.humidity.min}% &ndash; {stats.humidity.max}%</div>
                  </div>
                </div>
                <div className="stat-card">
                  <div className="stat-icon sound-icon">&#x1F50A;</div>
                  <div className="stat-content">
                    <div className="stat-value">{stats.sound.avg} dB</div>
                    <div className="stat-label">Avg Sound Level</div>
                    <div className="stat-range">{stats.sound.min} &ndash; {stats.sound.max} dB</div>
                  </div>
                </div>
                <div className="stat-card">
                  <div className="stat-icon">&#x1F4C8;</div>
                  <div className="stat-content">
                    <div className="stat-value">{stats.count.toLocaleString()}</div>
                    <div className="stat-label">Total Readings</div>
                    <div className="stat-range">{dateRange}-day window</div>
                  </div>
                </div>
              </div>
            )}

            {/* Health + Bee State Row */}
            {overview && (
              <div className="analytics-row">
                <div className="analytics-card health-card">
                  <h3>Colony Health Score</h3>
                  <div className="health-score-display">
                    <div className={`health-circle ${overview.health.category.toLowerCase()}`}>
                      <span className="health-number">{overview.health.score}</span>
                      <span className="health-cat">{overview.health.category}</span>
                    </div>
                    <div className="health-metrics">
                      <div className="health-metric">
                        <span className="metric-label">Queen Presence</span>
                        <div className="metric-bar"><div className="metric-fill queen"
                          style={{width: `${overview.health.queen_presence_pct}%`}}></div></div>
                        <span className="metric-value">{overview.health.queen_presence_pct.toFixed(0)}%</span>
                      </div>
                      <div className="health-metric">
                        <span className="metric-label">Stress Level</span>
                        <div className="metric-bar"><div className="metric-fill stress"
                          style={{width: `${overview.health.stress_pct}%`}}></div></div>
                        <span className="metric-value">{overview.health.stress_pct.toFixed(0)}%</span>
                      </div>
                      <div className="health-metric">
                        <span className="metric-label">Signal Quality</span>
                        <div className="metric-bar"><div className="metric-fill signal"
                          style={{width: `${overview.health.avg_signal_quality}%`}}></div></div>
                        <span className="metric-value">{overview.health.avg_signal_quality.toFixed(0)}%</span>
                      </div>
                    </div>
                  </div>
                </div>
                <div className="analytics-card">
                  <h3>Bee State Distribution</h3>
                  <div className="pie-container">
                    <ResponsiveContainer width="100%" height={220}>
                      <PieChart>
                        <Pie data={beeStatePie} dataKey="value" nameKey="name"
                          cx="50%" cy="50%" outerRadius={80} innerRadius={40} paddingAngle={2}>
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
              </div>
            )}

            {/* Tab Navigation */}
            <div className="chart-tabs">
              {[
                ['environmental', '&#x1F321;&#xFE0F;', 'Environmental'],
                ['acoustic', '&#x1F50A;', 'Acoustic Analysis'],
                ['weight', '&#x2696;&#xFE0F;', 'Weight'],
                ['battery', '&#x1F50B;', 'Battery'],
                ['ai', '&#x1F916;', 'AI Insights'],
              ].map(([key, icon, label]) => (
                <button key={key}
                  className={`chart-tab ${activeTab === key ? 'active' : ''}`}
                  onClick={() => setActiveTab(key)}
                  dangerouslySetInnerHTML={{__html: `${icon} ${label}`}} />
              ))}
            </div>

            {readingsLoading ? (
              <div className="loading-state">Loading chart data...</div>
            ) : (
              <>
                {/* ENVIRONMENTAL */}
                {activeTab === 'environmental' && (
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

                {/* ACOUSTIC */}
                {activeTab === 'acoustic' && (
                  <div className="chart-section">
                    <div className="analytics-card full-width">
                      <h3>Sound Level Over Time</h3>
                      <ResponsiveContainer width="100%" height={300}>
                        <AreaChart data={readings}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{fontSize: 11}} interval="preserveStartEnd" />
                          <YAxis label={{value: 'dB', position: 'insideTopLeft'}} />
                          <Tooltip content={<ChartTooltip />} />
                          <Area type="monotone" dataKey="sound_level" name="Sound Level (dB)"
                            stroke={COLORS.sound} fill={COLORS.sound} fillOpacity={0.15} strokeWidth={2} />
                          <Brush dataKey="time" height={30} stroke="#f59e0b" />
                        </AreaChart>
                      </ResponsiveContainer>
                    </div>

                    <div className="analytics-card full-width">
                      <h3>Dominant Frequency Analysis</h3>
                      <p className="chart-description">
                        Queen piping typically occurs at ~450 Hz. Worker buzzing at 200&ndash;250 Hz.
                        Pre-swarm activity shows elevated frequencies above 300 Hz.
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
                      <p className="chart-description">
                        Confidence scores below 60% indicate uncertain classifications.
                        Alerts are suppressed when confidence is below this threshold.
                      </p>
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

                    {overview?.daily_summaries && (
                      <div className="analytics-card full-width">
                        <h3>Daily Activity &amp; Bee State</h3>
                        <ResponsiveContainer width="100%" height={280}>
                          <BarChart data={overview.daily_summaries}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                            <XAxis dataKey="date" tick={{fontSize: 11}} />
                            <YAxis label={{value: 'Readings', position: 'insideTopLeft'}} />
                            <Tooltip />
                            <Bar dataKey="reading_count" name="Readings" fill="#f59e0b" radius={[4,4,0,0]} />
                          </BarChart>
                        </ResponsiveContainer>
                        <div className="daily-states">
                          {overview.daily_summaries.map((d, i) => (
                            <div key={i} className="daily-state-item">
                              <span className="daily-date">{d.date}</span>
                              <span className={`state-badge ${BEE_STATE_NAMES[d.dominant_state] || d.dominant_state}`}>
                                {(typeof d.dominant_state === 'number' ? (BEE_STATE_NAMES[d.dominant_state] || 'unknown') : String(d.dominant_state)).replace(/_/g, ' ')}
                              </span>
                              <span className="daily-risk">
                                Risk: {d.max_absconding_risk.toFixed(0)}%
                              </span>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {/* WEIGHT */}
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

                {/* BATTERY */}
                {activeTab === 'battery' && (
                  <div className="chart-section">
                    <div className="analytics-card full-width">
                      <h3>Battery Voltage Over Time</h3>
                      <p className="chart-description">
                        Low battery threshold: 3.6V. Critical (LDO dropout): 3.3V.
                        Readings above 4.8V indicate USB power.
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

                {/* AI INSIGHTS */}
                {activeTab === 'ai' && (
                  <div className="chart-section">
                    <div className="analytics-card full-width ai-card">
                      <h3>AI Colony Report</h3>
                      {user?.subscription_tier !== 'pro' ? (
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
              </>
            )}

            {/* Raw Data Table */}
            {readings.length > 0 && activeTab !== 'ai' && (
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
                        <th>Temp (&deg;C)</th>
                        <th>Humidity (%)</th>
                        <th>Pressure (hPa)</th>
                        <th>Sound (dB)</th>
                        <th>Freq (Hz)</th>
                        <th>Bee State</th>
                        <th>Confidence</th>
                        <th>Battery (V)</th>
                        <th>Weight (kg)</th>
                      </tr>
                    </thead>
                    <tbody>
                      {readings.slice(-50).reverse().map((r, i) => (
                        <tr key={i}>
                          <td className="td-timestamp">{new Date(r.timestamp).toLocaleString()}</td>
                          <td>{r.temperature?.toFixed(1) ?? '\u2014'}</td>
                          <td>{r.humidity?.toFixed(1) ?? '\u2014'}</td>
                          <td>{r.pressure?.toFixed(1) ?? '\u2014'}</td>
                          <td>{r.sound_level?.toFixed(1) ?? '\u2014'}</td>
                          <td>{r.dominant_freq?.toFixed(0) ?? '\u2014'}</td>
                          <td><span className={`state-badge ${BEE_STATE_NAMES[r.bee_state] || r.bee_state}`}>
                            {(typeof r.bee_state === 'number' ? (BEE_STATE_NAMES[r.bee_state] || 'unknown') : String(r.bee_state || '')).replace(/_/g, ' ') ?? '\u2014'}</span></td>
                          <td>{r.confidence?.toFixed(0) ?? '\u2014'}%</td>
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
      </main>
    </div>
  );
}

export default Analytics;
