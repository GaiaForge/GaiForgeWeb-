import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Dashboard.css';

const API_BASE = window.location.origin;

function Upload({ user, onLogout }) {
  const [selectedFiles, setSelectedFiles] = useState([]);
  const [hives, setHives] = useState([]);
  const [selectedHive, setSelectedHive] = useState('');
  const [uploading, setUploading] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const headers = {
    'Authorization': `Bearer ${user?.token}`,
  };

  useEffect(() => {
    fetch(`${API_BASE}/api/hives`, {
      headers: { ...headers, 'Content-Type': 'application/json' }
    })
      .then(r => r.ok ? r.json() : [])
      .then(setHives)
      .catch(() => {});
  }, []);

  const handleLogout = () => {
    onLogout();
    navigate('/login');
  };

  const handleFileSelect = (e) => {
    setSelectedFiles(Array.from(e.target.files));
    setResult(null);
    setError('');
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setSelectedFiles(Array.from(e.dataTransfer.files));
    setResult(null);
    setError('');
  };

  const CSV_TO_API = {
    'DateTime': 'timestamp', 'Temp_C': 'temperature',
    'Humidity_%': 'humidity', 'Pressure_hPa': 'pressure',
    'Sound_Hz': 'dominant_freq', 'Sound_Level': 'sound_level',
    'Bee_State': 'bee_state', 'Battery_V': 'battery_voltage',
    'Alerts': 'alert_flags', 'Weight_kg': 'weight_kg',
    'Spec_Centroid': 'spectral_centroid', 'Peak_Avg_Ratio': 'peak_to_avg',
    'Harmonicity': 'harmonicity',
    'Band_0_200': 'band_0_200', 'Band_200_400': 'band_200_400',
    'Band_400_600': 'band_400_600', 'Band_600_800': 'band_600_800',
    'Band_800_1000': 'band_800_1000', 'Band_1000Plus': 'band_1000_plus',
    'Spec_Rolloff': 'spectral_rolloff', 'Spec_Flux': 'spectral_flux',
    'ZCR': 'zero_crossing_rate',
    'Spec_Spread': 'spectral_spread', 'Spec_Skewness': 'spectral_skewness',
    'Spec_Kurtosis': 'spectral_kurtosis',
    'Energy_ST': 'short_term_energy', 'Energy_MT': 'mid_term_energy',
    'Energy_LT': 'long_term_energy', 'Energy_Entropy': 'energy_entropy',
    'Activity_Increase': 'activity_increase',
    'Hour_Sin': 'hour_sin', 'Hour_Cos': 'hour_cos',
    'Day_Sin': 'day_sin', 'Day_Cos': 'day_cos',
    'Ambient_Noise': 'ambient_noise_level', 'Signal_Quality': 'signal_quality',
    'Absconding_Risk': 'absconding_risk',
    'Context_Flags': 'context_flags', 'Confidence': 'confidence',
  };

  const BEE_STATE_MAP = {
    'UNKNOWN': 0, 'QUIET': 1, 'NORMAL': 2, 'ACTIVE': 3,
    'QUEEN_PRESENT': 4, 'PRE_SWARM': 5, 'DEFENSIVE': 6,
    'STRESSED': 7, 'QUEEN_MISSING': 8,
  };

  const parseCSV = (text) => {
    const allLines = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n').trim().split('\n');
    const headerIdx = allLines.findIndex(function(l) { return l.startsWith('DateTime,'); });
    if (headerIdx === -1) return [];
    const lines = allLines.slice(headerIdx);
    if (lines.length < 2) return [];
    const headers = lines[0].split(',').map(function(h) { return h.trim(); });
    return lines.slice(1).map(line => {
      const vals = line.split(',');
      const obj = {};
      headers.forEach(function(h, i) {
        var apiKey = CSV_TO_API[h];
        if (apiKey === undefined || apiKey === null) return;
        var v = (vals[i] || '').trim();
        if (v === '') return;
        if (apiKey === 'bee_state') { obj[apiKey] = BEE_STATE_MAP[v.toUpperCase()] || 0; return; }
        if (apiKey === 'alert_flags') { obj[apiKey] = String(v); return; }
        if (apiKey === 'timestamp') { obj[apiKey] = v.split('/').join('-'); return; }
        obj[apiKey] = isNaN(Number(v)) ? v : Number(v);
      });
      return obj;
    }).filter(obj => obj.timestamp);
  };

  const handleUpload = async () => {
    if (!selectedHive) {
      setError('Please select a hive');
      return;
    }
    if (selectedFiles.length === 0) return;

    setUploading(true);
    setError('');
    setResult(null);

    try {
      let allReadings = [];
      for (const file of selectedFiles) {
        const text = await file.text();
        const readings = parseCSV(text);
        allReadings = allReadings.concat(readings.map(r => ({
          ...r,
          hive_id: Number(selectedHive),
          device_id: 'web-upload-' + selectedHive,
        })));
      }

      if (allReadings.length === 0) {

        setError('No valid readings found in CSV files');
        setUploading(false);
        return;
      }

      // Send in batches of 500
      const batchSize = 500;
      let totalInserted = 0;
      let totalDuplicates = 0;

      for (let i = 0; i < allReadings.length; i += batchSize) {
        const batch = allReadings.slice(i, i + batchSize);
        const res = await fetch(`${API_BASE}/api/hiveguard/sync`, {
          method: 'POST',
          headers: { ...headers, 'Content-Type': 'application/json' },
          body: JSON.stringify({ readings: batch }),
        });

        if (!res.ok) {
          const data = await res.json().catch(() => ({}));
          throw new Error(data.detail || 'Sync failed');
        }

        const data = await res.json();
        totalInserted += data.inserted || 0;
        totalDuplicates += data.duplicates || 0;
      }

      setResult({
        total: allReadings.length,
        inserted: totalInserted,
        duplicates: totalDuplicates,
      });
      setSelectedFiles([]);
    } catch (err) {
      setError(err.message || 'Upload failed');
    } finally {
      setUploading(false);
    }
  };

  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  };

  return (
    <div className="dashboard-container">
      <aside className="sidebar">
        <div className="sidebar-header">
          <a href="/"><img src="/gaiaforge-logo.png" alt="GaiaForge" className="logo-image" /></a>
        </div>
        <nav className="sidebar-nav">
          <a href="/" className="nav-item back-link">
            <span className="nav-icon">←</span> Back to Site
          </a>
          <Link to="/dashboard" className="nav-item">
            <span className="nav-icon">📊</span> Dashboard
          </Link>
          <Link to="/analytics" className="nav-item">
            <span className="nav-icon">🔬</span> Analytics
          </Link>
          <Link to="/upload" className="nav-item active">
            <span className="nav-icon">⬆️</span> Upload Data
          </Link>
          <Link to="/devices" className="nav-item">
            <span className="nav-icon">📟</span> My Hives
          </Link>
          <Link to="/profile" className="nav-item">
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
            <h1>Upload Hive Data</h1>
            <p>Import CSV sensor data from your HiveGuard SD card</p>
          </div>
        </header>

        <div className="upload-container">
          {/* Hive Selection */}
          <div className="device-selector">
            <h3>Select Hive</h3>
            {hives.length === 0 ? (
              <p style={{color: '#6b7280'}}>
                No hives found. <Link to="/devices" style={{color: '#f59e0b'}}>Add a hive first</Link>.
              </p>
            ) : (
              <div className="device-options">
                {hives.map(h => (
                  <label key={h.id} className={`device-option ${selectedHive === String(h.id) ? 'selected' : ''}`}>
                    <input type="radio" name="hive" value={h.id}
                      checked={selectedHive === String(h.id)}
                      onChange={e => setSelectedHive(e.target.value)} />
                    <div className="device-card">
                      <div className="device-icon">🐝</div>
                      <div className="device-name">{h.name}</div>
                      <div className="device-desc">{h.location || 'No location'}</div>
                    </div>
                  </label>
                ))}
              </div>
            )}
          </div>

          {/* Drop Zone */}
          <div className="upload-dropzone" onDrop={handleDrop} onDragOver={e => e.preventDefault()}>
            <div className="dropzone-content">
              <div className="upload-icon">📁</div>
              <h3>Drag and drop CSV files here</h3>
              <p>or click to browse</p>
              <input type="file" multiple onChange={handleFileSelect}
                className="file-input" accept=".csv" />
              <div className="file-types">Supported: CSV files from HiveGuard SD card</div>
            </div>
          </div>

          {error && (
            <div style={{
              background: '#fef2f2', color: '#dc2626', padding: '14px 18px',
              borderRadius: '12px', marginBottom: '20px', border: '1px solid #fecaca'
            }}>{error}</div>
          )}

          {result && (
            <div style={{
              background: '#ecfdf5', color: '#065f46', padding: '18px',
              borderRadius: '12px', marginBottom: '20px', border: '1px solid #a7f3d0'
            }}>
              <strong>Upload complete!</strong><br/>
              {result.inserted} readings imported, {result.duplicates} duplicates skipped
              (out of {result.total} total rows)
            </div>
          )}

          {selectedFiles.length > 0 && (
            <div className="selected-files">
              <h3>Selected Files ({selectedFiles.length})</h3>
              <div className="files-list">
                {selectedFiles.map((file, i) => (
                  <div key={i} className="file-item">
                    <div className="file-icon">📄</div>
                    <div className="file-info">
                      <div className="file-name">{file.name}</div>
                      <div className="file-size">{formatFileSize(file.size)}</div>
                    </div>
                    <button className="remove-file"
                      onClick={() => setSelectedFiles(f => f.filter((_, idx) => idx !== i))}>
                      ✕
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {selectedFiles.length > 0 && !uploading && (
            <button className="btn-upload" onClick={handleUpload}>
              Upload {selectedFiles.length} file{selectedFiles.length > 1 ? 's' : ''} to HiveGuard API
            </button>
          )}

          {uploading && (
            <div className="upload-progress">
              <div className="progress-bar">
                <div className="progress-fill" style={{width: '100%', animation: 'pulse 1.5s infinite'}}></div>
              </div>
              <div className="progress-text">Syncing readings to server...</div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}

export default Upload;
