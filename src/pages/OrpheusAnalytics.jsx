import React, { useState, useEffect, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  LineChart, Line, AreaChart, Area, BarChart, Bar,
  ComposedChart, ResponsiveContainer, CartesianGrid,
  XAxis, YAxis, Tooltip, Legend, Brush,
} from 'recharts';

const API_BASE = window.location.origin;

const COLORS = {
  temperature: '#ef4444',
  humidity: '#3b82f6',
  pressure: '#8b5cf6',
  voltage: '#f59e0b',
  percentage: '#22c55e',
  solar: '#f97316',
  playback: '#10b981',
  volume: '#6366f1',
};

function OrpheusAnalytics({ user, onLogout }) {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('overview');
  const [devices, setDevices] = useState([]);
  const [selectedDevice, setSelectedDevice] = useState(null);
  const [overview, setOverview] = useState(null);
  const [readings, setReadings] = useState([]);
  const [battery, setBattery] = useState([]);
  const [playback, setPlayback] = useState([]);
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState(7);

  const headers = {
    'Authorization': `Bearer ${user?.token}`,
    'Content-Type': 'application/json',
  };

  const handleLogout = () => { onLogout(); navigate('/login'); };

  const formatTime = (ts) => {
    if (!ts) return '';
    const d = new Date(ts);
    return d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short' }) + ' ' +
      d.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
  };

  const formatDate = (ts) => {
    if (!ts) return '';
    return new Date(ts).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
  };

  const fetchDevices = useCallback(async () => {
    try {
      const res = await fetch(`${API_BASE}/api/orpheus/devices`, { headers });
      if (res.ok) {
        const data = await res.json();
        setDevices(data);
        if (data.length > 0 && !selectedDevice) {
          setSelectedDevice(data[0].id);
        }
      }
    } catch (err) {
      console.error('Failed to fetch devices:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchOverview = useCallback(async (deviceId) => {
    try {
      const res = await fetch(`${API_BASE}/api/orpheus/devices/${deviceId}/overview`, { headers });
      if (res.ok) setOverview(await res.json());
    } catch (err) {
      console.error('Failed to fetch overview:', err);
    }
  }, []);

  const fetchReadings = useCallback(async (deviceId, days) => {
    try {
      const res = await fetch(`${API_BASE}/api/orpheus/devices/${deviceId}/readings?days=${days}`, { headers });
      if (res.ok) {
        const data = await res.json();
        setReadings(data.map(r => ({
          ...r,
          time: formatTime(r.timestamp),
        })));
      }
    } catch (err) {
      console.error('Failed to fetch readings:', err);
    }
  }, []);

  const fetchBattery = useCallback(async (deviceId, days) => {
    try {
      const res = await fetch(`${API_BASE}/api/orpheus/devices/${deviceId}/battery?days=${days}`, { headers });
      if (res.ok) {
        const data = await res.json();
        setBattery(data.map(b => ({
          ...b,
          time: formatTime(b.timestamp),
        })));
      }
    } catch (err) {
      console.error('Failed to fetch battery:', err);
    }
  }, []);

  const fetchPlayback = useCallback(async (deviceId, days) => {
    try {
      const res = await fetch(`${API_BASE}/api/orpheus/devices/${deviceId}/playback?days=${days}`, { headers });
      if (res.ok) {
        const data = await res.json();
        setPlayback(data.map(p => ({
          ...p,
          time: formatTime(p.start_time),
          date: formatDate(p.start_time),
        })));
      }
    } catch (err) {
      console.error('Failed to fetch playback:', err);
    }
  }, []);

  const fetchEvents = useCallback(async (deviceId, days) => {
    try {
      const res = await fetch(`${API_BASE}/api/orpheus/devices/${deviceId}/events?days=${days}`, { headers });
      if (res.ok) setEvents(await res.json());
    } catch (err) {
      console.error('Failed to fetch events:', err);
    }
  }, []);

  useEffect(() => { fetchDevices(); }, [fetchDevices]);

  useEffect(() => {
    if (!selectedDevice) return;
    fetchOverview(selectedDevice);
    fetchReadings(selectedDevice, dateRange);
    fetchBattery(selectedDevice, dateRange);
    fetchPlayback(selectedDevice, dateRange);
    fetchEvents(selectedDevice, dateRange);
  }, [selectedDevice, dateRange]);

  const handleExportCSV = () => {
    if (activeTab === 'environment' && readings.length > 0) {
      const header = 'Timestamp,Temperature (C),Humidity (%),Pressure (hPa)\n';
      const rows = readings.map(r =>
        `${r.timestamp},${r.temperature ?? ''},${r.humidity ?? ''},${r.pressure ?? ''}`
      ).join('\n');
      downloadCSV(header + rows, 'orpheus_environmental.csv');
    } else if (activeTab === 'battery' && battery.length > 0) {
      const header = 'Timestamp,Voltage (V),Percentage (%),Charging State,Solar Power (W),Solar Yield (kWh)\n';
      const rows = battery.map(b =>
        `${b.timestamp},${b.voltage ?? ''},${b.percentage ?? ''},${b.charging_state ?? ''},${b.power_output ?? ''},${b.yield_day ?? ''}`
      ).join('\n');
      downloadCSV(header + rows, 'orpheus_battery.csv');
    } else if (activeTab === 'playback' && playback.length > 0) {
      const header = 'Start Time,End Time,Duration (s),Mode,Track,Category,Volume (%),Location\n';
      const rows = playback.map(p =>
        `${p.start_time ?? ''},${p.end_time ?? ''},${p.duration_seconds ?? ''},${p.playback_mode},${p.track_name},${p.category ?? ''},${p.volume_percent ?? ''},${p.location_name ?? ''}`
      ).join('\n');
      downloadCSV(header + rows, 'orpheus_playback.csv');
    }
  };

  const downloadCSV = (content, filename) => {
    const blob = new Blob([content], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = filename; a.click();
    URL.revokeObjectURL(url);
  };

  const currentDevice = devices.find(d => d.id === selectedDevice);

  // Aggregate playback by day for bar chart
  const playbackByDay = playback.reduce((acc, p) => {
    const day = p.date;
    if (!day) return acc;
    if (!acc[day]) acc[day] = { date: day, count: 0, hours: 0 };
    acc[day].count += 1;
    acc[day].hours += (p.duration_seconds || 0) / 3600;
    return acc;
  }, {});
  const playbackDayData = Object.values(playbackByDay).map(d => ({
    ...d, hours: Math.round(d.hours * 10) / 10,
  }));

  // Aggregate playback by mode for breakdown
  const playbackByMode = playback.reduce((acc, p) => {
    if (!acc[p.playback_mode]) acc[p.playback_mode] = 0;
    acc[p.playback_mode] += 1;
    return acc;
  }, {});

  const CustomTooltip = ({ active, payload, label }) => {
    if (!active || !payload?.length) return null;
    return (
      <div style={{ background: '#fff', border: '1px solid #e5e7eb', borderRadius: 8, padding: '10px 14px', boxShadow: '0 2px 8px rgba(0,0,0,0.08)' }}>
        <div style={{ fontSize: 12, color: '#6b7280', marginBottom: 6 }}>{label}</div>
        {payload.map((p, i) => (
          <div key={i} style={{ fontSize: 13, color: p.color, marginBottom: 2 }}>
            {p.name}: <strong>{typeof p.value === 'number' ? p.value.toFixed(1) : p.value}</strong>
          </div>
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
          <Link to="/orpheus" className="nav-item back-link">
            <span className="nav-icon">&larr;</span> Orpheus Portal
          </Link>
          <button className={`nav-item nav-btn ${activeTab === 'overview' ? 'active' : ''}`}
            onClick={() => setActiveTab('overview')}>
            <span className="nav-icon">📊</span> Overview
          </button>
          <button className={`nav-item nav-btn ${activeTab === 'environment' ? 'active' : ''}`}
            onClick={() => setActiveTab('environment')}>
            <span className="nav-icon">🌡️</span> Environment
          </button>
          <button className={`nav-item nav-btn ${activeTab === 'battery' ? 'active' : ''}`}
            onClick={() => setActiveTab('battery')}>
            <span className="nav-icon">🔋</span> Battery &amp; Solar
          </button>
          <button className={`nav-item nav-btn ${activeTab === 'playback' ? 'active' : ''}`}
            onClick={() => setActiveTab('playback')}>
            <span className="nav-icon">🔊</span> Playback
          </button>
          <button className={`nav-item nav-btn ${activeTab === 'events' ? 'active' : ''}`}
            onClick={() => setActiveTab('events')}>
            <span className="nav-icon">📋</span> System Log
          </button>
          <Link to="/orpheus/journal" className="nav-item">
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
            <h1>Orpheus Analytics</h1>
            <p>Environmental data, battery status, and playback history</p>
          </div>
          <div className="user-avatar">
            {user?.name?.charAt(0).toUpperCase() || 'U'}
          </div>
        </header>

        {loading ? (
          <div className="loading-state">Loading devices...</div>
        ) : devices.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">📡</div>
            <h2>No Orpheus devices found</h2>
            <p>Sync data from the Orpheus mobile app to see it here. Devices are auto-registered on first sync.</p>
          </div>
        ) : (
          <>
            {/* Device selector + date range */}
            <div style={{ display: 'flex', gap: 16, marginBottom: 24, flexWrap: 'wrap', alignItems: 'center' }}>
              {devices.length > 1 && (
                <div className="hive-selector">
                  {devices.map(d => (
                    <button key={d.id}
                      className={`chart-tab ${selectedDevice === d.id ? 'active' : ''}`}
                      onClick={() => setSelectedDevice(d.id)}>
                      {d.name || d.serial}
                    </button>
                  ))}
                </div>
              )}
              {devices.length === 1 && (
                <div style={{ fontSize: 14, color: '#6b7280' }}>
                  Device: <strong>{currentDevice?.name || currentDevice?.serial}</strong>
                  {currentDevice?.last_sync && (
                    <span> &middot; Last sync: {formatDate(currentDevice.last_sync)}</span>
                  )}
                </div>
              )}
              <div style={{ marginLeft: 'auto', display: 'flex', gap: 8, alignItems: 'center' }}>
                <select value={dateRange} onChange={e => setDateRange(Number(e.target.value))}
                  style={{ padding: '6px 12px', borderRadius: 6, border: '1px solid #d1d5db', fontSize: 13 }}>
                  <option value={7}>Last 7 days</option>
                  <option value={14}>Last 14 days</option>
                  <option value={30}>Last 30 days</option>
                  <option value={90}>Last 90 days</option>
                  <option value={365}>Last year</option>
                </select>
                {['environment', 'battery', 'playback'].includes(activeTab) && (
                  <button onClick={handleExportCSV} className="btn-download"
                    style={{ padding: '6px 16px', fontSize: 13 }}>
                    Export CSV
                  </button>
                )}
              </div>
            </div>

            {/* ==================== OVERVIEW TAB ==================== */}
            {activeTab === 'overview' && overview && (
              <div>
                <div className="stats-grid four-col">
                  <div className="stat-card">
                    <div className="stat-icon">🌡️</div>
                    <div className="stat-content">
                      <div className="stat-value">
                        {overview.latest_environment.temperature != null
                          ? `${overview.latest_environment.temperature.toFixed(1)}°C`
                          : '—'}
                      </div>
                      <div className="stat-label">Temperature</div>
                    </div>
                  </div>
                  <div className="stat-card">
                    <div className="stat-icon">💧</div>
                    <div className="stat-content">
                      <div className="stat-value">
                        {overview.latest_environment.humidity != null
                          ? `${overview.latest_environment.humidity.toFixed(0)}%`
                          : '—'}
                      </div>
                      <div className="stat-label">Humidity</div>
                    </div>
                  </div>
                  <div className="stat-card">
                    <div className="stat-icon">🔋</div>
                    <div className="stat-content">
                      <div className="stat-value">
                        {overview.latest_battery.voltage != null
                          ? `${overview.latest_battery.voltage.toFixed(1)}V`
                          : '—'}
                      </div>
                      <div className="stat-label">
                        Battery{overview.latest_battery.percentage != null
                          ? ` (${overview.latest_battery.percentage.toFixed(0)}%)`
                          : ''}
                      </div>
                    </div>
                  </div>
                  <div className="stat-card">
                    <div className="stat-icon">🔊</div>
                    <div className="stat-content">
                      <div className="stat-value">{overview.stats_30d.playback_hours}h</div>
                      <div className="stat-label">Playback (30d)</div>
                    </div>
                  </div>
                </div>

                <div className="stats-grid" style={{ marginTop: 24 }}>
                  <div className="stat-card">
                    <div className="stat-icon">📈</div>
                    <div className="stat-content">
                      <div className="stat-value">{overview.stats_30d.readings_count.toLocaleString()}</div>
                      <div className="stat-label">Environmental readings (30d)</div>
                    </div>
                  </div>
                  <div className="stat-card">
                    <div className="stat-icon">🎵</div>
                    <div className="stat-content">
                      <div className="stat-value">{overview.stats_30d.playback_count}</div>
                      <div className="stat-label">Playback events (30d)</div>
                    </div>
                  </div>
                  <div className="stat-card">
                    <div className="stat-icon">☀️</div>
                    <div className="stat-content">
                      <div className="stat-value">
                        {overview.latest_battery.power_output != null
                          ? `${overview.latest_battery.power_output.toFixed(1)}W`
                          : '—'}
                      </div>
                      <div className="stat-label">Solar output</div>
                    </div>
                  </div>
                </div>

                {overview.latest_battery.charging_state && (
                  <div className="orpheus-info-banner" style={{ marginTop: 24 }}>
                    <div className="info-icon">⚡</div>
                    <div>
                      <strong>Charging state:</strong> {overview.latest_battery.charging_state}
                      {overview.latest_battery.timestamp && (
                        <span style={{ color: '#6b7280' }}> — as of {formatTime(overview.latest_battery.timestamp)}</span>
                      )}
                    </div>
                  </div>
                )}

                {/* Quick charts */}
                {readings.length > 0 && (
                  <div className="analytics-card full-width" style={{ marginTop: 24 }}>
                    <h3>Temperature &amp; Humidity (last {dateRange} days)</h3>
                    <ResponsiveContainer width="100%" height={280}>
                      <ComposedChart data={readings}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                        <XAxis dataKey="time" tick={{ fontSize: 11 }} interval="preserveStartEnd" />
                        <YAxis yAxisId="temp" label={{ value: '°C', position: 'insideTopLeft', fontSize: 11 }} />
                        <YAxis yAxisId="hum" orientation="right" label={{ value: '%', position: 'insideTopRight', fontSize: 11 }} />
                        <Tooltip content={<CustomTooltip />} />
                        <Legend />
                        <Line yAxisId="temp" type="monotone" dataKey="temperature" name="Temperature (°C)" stroke={COLORS.temperature} dot={false} strokeWidth={2} />
                        <Line yAxisId="hum" type="monotone" dataKey="humidity" name="Humidity (%)" stroke={COLORS.humidity} dot={false} strokeWidth={2} />
                      </ComposedChart>
                    </ResponsiveContainer>
                  </div>
                )}
              </div>
            )}

            {activeTab === 'overview' && !overview && (
              <div className="loading-state">Loading overview...</div>
            )}

            {/* ==================== ENVIRONMENT TAB ==================== */}
            {activeTab === 'environment' && (
              <div>
                {readings.length === 0 ? (
                  <div className="empty-state">
                    <div className="empty-icon">🌡️</div>
                    <h2>No environmental data</h2>
                    <p>Sync data from your device to see temperature, humidity, and pressure charts.</p>
                  </div>
                ) : (
                  <>
                    <div className="analytics-card full-width">
                      <h3>Temperature</h3>
                      <p style={{ color: '#6b7280', fontSize: 13, marginBottom: 12 }}>Ambient temperature recorded by the device sensor.</p>
                      <ResponsiveContainer width="100%" height={300}>
                        <AreaChart data={readings}>
                          <defs>
                            <linearGradient id="tempGrad" x1="0" y1="0" x2="0" y2="1">
                              <stop offset="5%" stopColor={COLORS.temperature} stopOpacity={0.2} />
                              <stop offset="95%" stopColor={COLORS.temperature} stopOpacity={0} />
                            </linearGradient>
                          </defs>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{ fontSize: 11 }} interval="preserveStartEnd" />
                          <YAxis label={{ value: '°C', position: 'insideTopLeft', fontSize: 11 }} />
                          <Tooltip content={<CustomTooltip />} />
                          <Area type="monotone" dataKey="temperature" name="Temperature (°C)" stroke={COLORS.temperature} fill="url(#tempGrad)" strokeWidth={2} />
                          <Brush dataKey="time" height={25} stroke="#d1d5db" />
                        </AreaChart>
                      </ResponsiveContainer>
                    </div>

                    <div className="analytics-card full-width" style={{ marginTop: 24 }}>
                      <h3>Humidity</h3>
                      <ResponsiveContainer width="100%" height={300}>
                        <AreaChart data={readings}>
                          <defs>
                            <linearGradient id="humGrad" x1="0" y1="0" x2="0" y2="1">
                              <stop offset="5%" stopColor={COLORS.humidity} stopOpacity={0.2} />
                              <stop offset="95%" stopColor={COLORS.humidity} stopOpacity={0} />
                            </linearGradient>
                          </defs>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{ fontSize: 11 }} interval="preserveStartEnd" />
                          <YAxis domain={[0, 100]} label={{ value: '%', position: 'insideTopLeft', fontSize: 11 }} />
                          <Tooltip content={<CustomTooltip />} />
                          <Area type="monotone" dataKey="humidity" name="Humidity (%)" stroke={COLORS.humidity} fill="url(#humGrad)" strokeWidth={2} />
                          <Brush dataKey="time" height={25} stroke="#d1d5db" />
                        </AreaChart>
                      </ResponsiveContainer>
                    </div>

                    <div className="analytics-card full-width" style={{ marginTop: 24 }}>
                      <h3>Atmospheric Pressure</h3>
                      <ResponsiveContainer width="100%" height={300}>
                        <AreaChart data={readings}>
                          <defs>
                            <linearGradient id="pressGrad" x1="0" y1="0" x2="0" y2="1">
                              <stop offset="5%" stopColor={COLORS.pressure} stopOpacity={0.2} />
                              <stop offset="95%" stopColor={COLORS.pressure} stopOpacity={0} />
                            </linearGradient>
                          </defs>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{ fontSize: 11 }} interval="preserveStartEnd" />
                          <YAxis domain={['auto', 'auto']} label={{ value: 'hPa', position: 'insideTopLeft', fontSize: 11 }} />
                          <Tooltip content={<CustomTooltip />} />
                          <Area type="monotone" dataKey="pressure" name="Pressure (hPa)" stroke={COLORS.pressure} fill="url(#pressGrad)" strokeWidth={2} />
                          <Brush dataKey="time" height={25} stroke="#d1d5db" />
                        </AreaChart>
                      </ResponsiveContainer>
                    </div>
                  </>
                )}
              </div>
            )}

            {/* ==================== BATTERY TAB ==================== */}
            {activeTab === 'battery' && (
              <div>
                {battery.length === 0 ? (
                  <div className="empty-state">
                    <div className="empty-icon">🔋</div>
                    <h2>No battery data</h2>
                    <p>Battery and solar data will appear here once synced from your device.</p>
                  </div>
                ) : (
                  <>
                    <div className="analytics-card full-width">
                      <h3>Battery Voltage &amp; Charge</h3>
                      <ResponsiveContainer width="100%" height={300}>
                        <ComposedChart data={battery}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{ fontSize: 11 }} interval="preserveStartEnd" />
                          <YAxis yAxisId="v" label={{ value: 'Volts', position: 'insideTopLeft', fontSize: 11 }} />
                          <YAxis yAxisId="pct" orientation="right" domain={[0, 100]} label={{ value: '%', position: 'insideTopRight', fontSize: 11 }} />
                          <Tooltip content={<CustomTooltip />} />
                          <Legend />
                          <Line yAxisId="v" type="monotone" dataKey="voltage" name="Voltage (V)" stroke={COLORS.voltage} dot={false} strokeWidth={2} />
                          <Line yAxisId="pct" type="monotone" dataKey="percentage" name="Charge (%)" stroke={COLORS.percentage} dot={false} strokeWidth={2} />
                          <Brush dataKey="time" height={25} stroke="#d1d5db" />
                        </ComposedChart>
                      </ResponsiveContainer>
                    </div>

                    <div className="analytics-card full-width" style={{ marginTop: 24 }}>
                      <h3>Solar Input</h3>
                      <p style={{ color: '#6b7280', fontSize: 13, marginBottom: 12 }}>Power output (W) and daily yield (kWh) from the solar panel.</p>
                      <ResponsiveContainer width="100%" height={300}>
                        <ComposedChart data={battery}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="time" tick={{ fontSize: 11 }} interval="preserveStartEnd" />
                          <YAxis yAxisId="w" label={{ value: 'Watts', position: 'insideTopLeft', fontSize: 11 }} />
                          <YAxis yAxisId="kwh" orientation="right" label={{ value: 'kWh', position: 'insideTopRight', fontSize: 11 }} />
                          <Tooltip content={<CustomTooltip />} />
                          <Legend />
                          <Area yAxisId="w" type="monotone" dataKey="power_output" name="Solar Power (W)" stroke={COLORS.solar} fill={COLORS.solar} fillOpacity={0.15} strokeWidth={2} />
                          <Line yAxisId="kwh" type="monotone" dataKey="yield_day" name="Daily Yield (kWh)" stroke={COLORS.percentage} dot={false} strokeWidth={2} />
                          <Brush dataKey="time" height={25} stroke="#d1d5db" />
                        </ComposedChart>
                      </ResponsiveContainer>
                    </div>
                  </>
                )}
              </div>
            )}

            {/* ==================== PLAYBACK TAB ==================== */}
            {activeTab === 'playback' && (
              <div>
                {playback.length === 0 ? (
                  <div className="empty-state">
                    <div className="empty-icon">🔊</div>
                    <h2>No playback data</h2>
                    <p>Playback events will appear once synced from your device.</p>
                  </div>
                ) : (
                  <>
                    {/* Summary stats */}
                    <div className="stats-grid four-col" style={{ marginBottom: 24 }}>
                      <div className="stat-card">
                        <div className="stat-icon">🎵</div>
                        <div className="stat-content">
                          <div className="stat-value">{playback.length}</div>
                          <div className="stat-label">Total events</div>
                        </div>
                      </div>
                      <div className="stat-card">
                        <div className="stat-icon">⏱️</div>
                        <div className="stat-content">
                          <div className="stat-value">
                            {(playback.reduce((s, p) => s + (p.duration_seconds || 0), 0) / 3600).toFixed(1)}h
                          </div>
                          <div className="stat-label">Total playback</div>
                        </div>
                      </div>
                      <div className="stat-card">
                        <div className="stat-icon">🎚️</div>
                        <div className="stat-content">
                          <div className="stat-value">
                            {playback.filter(p => p.volume_percent != null).length > 0
                              ? Math.round(playback.filter(p => p.volume_percent != null).reduce((s, p) => s + p.volume_percent, 0) / playback.filter(p => p.volume_percent != null).length) + '%'
                              : '—'}
                          </div>
                          <div className="stat-label">Avg volume</div>
                        </div>
                      </div>
                      <div className="stat-card">
                        <div className="stat-icon">📅</div>
                        <div className="stat-content">
                          <div className="stat-value">{Object.keys(playbackByDay).length}</div>
                          <div className="stat-label">Active days</div>
                        </div>
                      </div>
                    </div>

                    {/* Daily playback bar chart */}
                    <div className="analytics-card full-width">
                      <h3>Daily Playback Hours</h3>
                      <ResponsiveContainer width="100%" height={280}>
                        <BarChart data={playbackDayData}>
                          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                          <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                          <YAxis label={{ value: 'Hours', position: 'insideTopLeft', fontSize: 11 }} />
                          <Tooltip content={<CustomTooltip />} />
                          <Bar dataKey="hours" name="Playback Hours" fill={COLORS.playback} radius={[4, 4, 0, 0]} />
                        </BarChart>
                      </ResponsiveContainer>
                    </div>

                    {/* Mode breakdown */}
                    <div className="analytics-card full-width" style={{ marginTop: 24 }}>
                      <h3>Playback Mode Breakdown</h3>
                      <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap', marginTop: 12 }}>
                        {Object.entries(playbackByMode).map(([mode, count]) => (
                          <div key={mode} className="stat-card" style={{ flex: '1 1 180px' }}>
                            <div className="stat-content">
                              <div className="stat-value">{count}</div>
                              <div className="stat-label">{mode}</div>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Recent playback table */}
                    <div className="analytics-card full-width" style={{ marginTop: 24 }}>
                      <h3>Recent Playback Events</h3>
                      <div style={{ overflowX: 'auto', marginTop: 12 }}>
                        <table className="uploads-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                          <thead>
                            <tr style={{ borderBottom: '2px solid #e5e7eb', textAlign: 'left' }}>
                              <th style={{ padding: '8px 12px', fontSize: 12, color: '#6b7280' }}>Time</th>
                              <th style={{ padding: '8px 12px', fontSize: 12, color: '#6b7280' }}>Track</th>
                              <th style={{ padding: '8px 12px', fontSize: 12, color: '#6b7280' }}>Mode</th>
                              <th style={{ padding: '8px 12px', fontSize: 12, color: '#6b7280' }}>Duration</th>
                              <th style={{ padding: '8px 12px', fontSize: 12, color: '#6b7280' }}>Volume</th>
                            </tr>
                          </thead>
                          <tbody>
                            {playback.slice(-50).reverse().map((p, i) => (
                              <tr key={i} style={{ borderBottom: '1px solid #f3f4f6' }}>
                                <td style={{ padding: '8px 12px', fontSize: 13 }}>{p.time}</td>
                                <td style={{ padding: '8px 12px', fontSize: 13 }}>{p.track_name}</td>
                                <td style={{ padding: '8px 12px', fontSize: 13 }}>
                                  <span className="selector-badge-open" style={{ fontSize: 11, padding: '2px 8px' }}>{p.playback_mode}</span>
                                </td>
                                <td style={{ padding: '8px 12px', fontSize: 13 }}>
                                  {p.duration_seconds != null ? `${Math.floor(p.duration_seconds / 60)}m ${p.duration_seconds % 60}s` : '—'}
                                </td>
                                <td style={{ padding: '8px 12px', fontSize: 13 }}>
                                  {p.volume_percent != null ? `${p.volume_percent}%` : '—'}
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    </div>
                  </>
                )}
              </div>
            )}

            {/* ==================== SYSTEM LOG TAB ==================== */}
            {activeTab === 'events' && (
              <div>
                {events.length === 0 ? (
                  <div className="empty-state">
                    <div className="empty-icon">📋</div>
                    <h2>No system events</h2>
                    <p>System events (wake, sleep, shutdown) will appear once synced.</p>
                  </div>
                ) : (
                  <div className="analytics-card full-width">
                    <h3>System Events ({events.length})</h3>
                    <div style={{ overflowX: 'auto', marginTop: 12 }}>
                      <table className="uploads-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
                        <thead>
                          <tr style={{ borderBottom: '2px solid #e5e7eb', textAlign: 'left' }}>
                            <th style={{ padding: '8px 12px', fontSize: 12, color: '#6b7280' }}>Time</th>
                            <th style={{ padding: '8px 12px', fontSize: 12, color: '#6b7280' }}>Event</th>
                            <th style={{ padding: '8px 12px', fontSize: 12, color: '#6b7280' }}>Description</th>
                          </tr>
                        </thead>
                        <tbody>
                          {events.slice(0, 100).map((e, i) => (
                            <tr key={i} style={{ borderBottom: '1px solid #f3f4f6' }}>
                              <td style={{ padding: '8px 12px', fontSize: 13 }}>{formatTime(e.timestamp)}</td>
                              <td style={{ padding: '8px 12px', fontSize: 13 }}>
                                <span className="selector-badge-open" style={{
                                  fontSize: 11, padding: '2px 8px',
                                  background: e.event_type === 'WAKE' ? '#dcfce7' : e.event_type === 'SLEEP' ? '#dbeafe' : '#fef3c7',
                                  color: e.event_type === 'WAKE' ? '#166534' : e.event_type === 'SLEEP' ? '#1e40af' : '#92400e',
                                }}>
                                  {e.event_type}
                                </span>
                              </td>
                              <td style={{ padding: '8px 12px', fontSize: 13, color: '#6b7280' }}>{e.description || '—'}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                )}
              </div>
            )}
          </>
        )}
      </main>
    </div>
  );
}

export default OrpheusAnalytics;
