import React, { useState, useEffect, useMemo } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import './OrpheusMap.css';

const API_BASE = window.location.origin;

// OpenTopoMap: free, CC BY-SA, volunteer-run. Attribution is a licence
// condition, not decoration - keep it visible. Max zoom 17 by the provider.
// If traffic ever outgrows the public server, swap this one URL for a
// paid host or a tile cache; nothing else changes.
const TILE_URL = 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
const TILE_ATTRIBUTION =
  'Map data: &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, ' +
  'SRTM | Map style: &copy; <a href="https://opentopomap.org">OpenTopoMap</a> (CC-BY-SA)';
const MAX_ZOOM = 17;

// Freshness is the health signal. Nothing moves to the cloud unless someone
// visits the unit with the phone app, so "synced 40 days ago" says more than
// any reading does.
const FRESHNESS = [
  { key: 'fresh', label: 'Synced within 7 days', maxDays: 7, color: '#16a34a' },
  { key: 'aging', label: 'Synced 8–30 days ago', maxDays: 30, color: '#d97706' },
  { key: 'stale', label: 'Not synced for over 30 days', maxDays: Infinity, color: '#dc2626' },
];
const NEVER = { key: 'never', label: 'Never synced', color: '#6b7280' };

function daysSince(ts) {
  if (!ts) return null;
  const ms = Date.now() - new Date(ts).getTime();
  return Math.max(0, Math.floor(ms / 86400000));
}

function freshnessOf(device) {
  const d = daysSince(device.last_sync);
  if (d === null) return NEVER;
  return FRESHNESS.find(f => d <= f.maxDays) || NEVER;
}

function formatDate(ts) {
  if (!ts) return 'never';
  return new Date(ts).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
}

function relativeSync(ts) {
  const d = daysSince(ts);
  if (d === null) return 'never synced';
  if (d === 0) return 'synced today';
  if (d === 1) return 'synced yesterday';
  return `synced ${d} days ago`;
}

// A plain coloured dot instead of Leaflet's default image marker: the image
// path breaks under bundlers, and a colour-coded dot carries the freshness
// signal at a glance.
function pinIcon(color) {
  return L.divIcon({
    className: 'orpheus-pin-wrap',
    html: `<span class="orpheus-pin" style="background:${color}"></span>`,
    iconSize: [18, 18],
    iconAnchor: [9, 9],
    popupAnchor: [0, -10],
  });
}

// Fit the view to every placed unit once they are known. One unit: zoom in
// to site scale; several: frame them all with a little breathing room.
function FitToDevices({ points }) {
  const map = useMap();
  useEffect(() => {
    if (points.length === 0) return;
    if (points.length === 1) {
      map.setView(points[0], 14);
    } else {
      map.fitBounds(L.latLngBounds(points), { padding: [40, 40], maxZoom: 14 });
    }
  }, [map, points]);
  return null;
}

function OrpheusMap({ user, onLogout }) {
  const navigate = useNavigate();
  const [devices, setDevices] = useState([]);
  const [overviews, setOverviews] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const headers = useMemo(() => ({
    'Authorization': `Bearer ${user?.token}`,
    'Content-Type': 'application/json',
  }), [user?.token]);

  const handleLogout = () => { onLogout(); navigate('/login'); };

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch(`${API_BASE}/api/orpheus/devices`, { headers });
        if (!res.ok) throw new Error(`Device list failed (${res.status})`);
        const list = await res.json();
        if (cancelled) return;
        setDevices(list);
        setLoading(false);

        // Battery per pin comes from each device's overview. A handful of
        // small calls is fine at this fleet size; the pins render first and
        // fill in as the answers arrive.
        const results = await Promise.all(list.map(async d => {
          try {
            const r = await fetch(`${API_BASE}/api/orpheus/devices/${d.id}/overview`, { headers });
            return r.ok ? [d.id, await r.json()] : [d.id, null];
          } catch { return [d.id, null]; }
        }));
        if (!cancelled) setOverviews(Object.fromEntries(results));
      } catch (err) {
        if (!cancelled) { setError(err.message); setLoading(false); }
      }
    })();
    return () => { cancelled = true; };
  }, [headers]);

  const placed = devices.filter(d => d.latitude != null && d.longitude != null
    && !(d.latitude === 0 && d.longitude === 0));
  const unplaced = devices.filter(d => !placed.includes(d));
  const points = useMemo(() => placed.map(d => [d.latitude, d.longitude]), [placed]);

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
          <Link to="/orpheus/map" className="nav-item active">
            <span className="nav-icon">🗺️</span> Map
          </Link>
          <Link to="/orpheus/analytics" className="nav-item">
            <span className="nav-icon">📊</span> Analytics
          </Link>
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
            <h1>Unit Map</h1>
            <p>Where your Orpheus units are and when each was last synced</p>
          </div>
          <div className="user-avatar">
            {user?.name?.charAt(0).toUpperCase() || 'U'}
          </div>
        </header>

        {loading ? (
          <div className="loading-state">Loading units...</div>
        ) : error ? (
          <div className="empty-state">
            <div className="empty-icon">⚠️</div>
            <h2>Could not load your units</h2>
            <p>{error}</p>
          </div>
        ) : devices.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">📡</div>
            <h2>No Orpheus units yet</h2>
            <p>Connect to a unit in the Orpheus app while signed in. It registers itself and syncs on first connect.</p>
          </div>
        ) : (
          <>
            <div className="map-legend">
              {[...FRESHNESS, NEVER].map(f => (
                <span key={f.key} className="map-legend-item">
                  <span className="orpheus-pin orpheus-pin-inline" style={{ background: f.color }} />
                  {f.label}
                </span>
              ))}
              <span className="map-legend-note">
                Data reaches the portal only when a unit is visited with the app, so sync age is the health signal.
              </span>
            </div>

            {placed.length > 0 ? (
              <div className="map-frame">
                <MapContainer center={points[0]} zoom={13} maxZoom={MAX_ZOOM}
                  scrollWheelZoom={true} className="map-canvas">
                  <TileLayer url={TILE_URL} attribution={TILE_ATTRIBUTION} maxZoom={MAX_ZOOM} />
                  <FitToDevices points={points} />
                  {placed.map(d => {
                    const f = freshnessOf(d);
                    const ov = overviews[d.id];
                    const bat = ov?.latest_battery;
                    return (
                      <Marker key={d.id} position={[d.latitude, d.longitude]} icon={pinIcon(f.color)}>
                        <Popup>
                          <div className="pin-popup">
                            <div className="pin-title">{d.name || d.serial}</div>
                            {d.name && <div className="pin-sub">{d.serial}</div>}
                            <div className="pin-row">
                              <span className="pin-chip" style={{ background: f.color }}>{relativeSync(d.last_sync)}</span>
                            </div>
                            <div className="pin-row">
                              Battery: {bat?.percentage != null
                                ? <strong>{Math.round(bat.percentage)}%{bat.voltage != null ? ` · ${bat.voltage.toFixed(2)} V` : ''}</strong>
                                : <span className="pin-muted">{ov === undefined ? 'loading…' : 'no data'}</span>}
                            </div>
                            {ov?.latest_environment?.temperature != null && (
                              <div className="pin-row">
                                Last reading: <strong>{ov.latest_environment.temperature.toFixed(1)}°C</strong>
                                {ov.latest_environment.humidity != null && <> · <strong>{Math.round(ov.latest_environment.humidity)}%</strong> RH</>}
                              </div>
                            )}
                            <div className="pin-row pin-muted">Last sync {formatDate(d.last_sync)}</div>
                            <Link to="/orpheus/analytics" className="pin-link">Open analytics &rarr;</Link>
                          </div>
                        </Popup>
                      </Marker>
                    );
                  })}
                </MapContainer>
              </div>
            ) : (
              <div className="empty-state">
                <div className="empty-icon">📍</div>
                <h2>No unit has a location yet</h2>
                <p>Set each unit's position in the Orpheus app under Settings, either by typing coordinates or with the "use my location" button while standing at the unit. The next sync places it on the map.</p>
              </div>
            )}

            {unplaced.length > 0 && placed.length > 0 && (
              <div className="unplaced">
                <h3>Not on the map</h3>
                <p>These units have synced but have no location set. Set it in the app under Settings and sync again.</p>
                <ul>
                  {unplaced.map(d => {
                    const f = freshnessOf(d);
                    return (
                      <li key={d.id}>
                        <span className="orpheus-pin orpheus-pin-inline" style={{ background: f.color }} />
                        <strong>{d.name || d.serial}</strong>
                        <span className="pin-muted"> · {relativeSync(d.last_sync)}</span>
                      </li>
                    );
                  })}
                </ul>
              </div>
            )}

            <p className="map-privacy">
              Unit positions are visible only to your account. They are never shown on shared or public pages.
            </p>
          </>
        )}
      </main>
    </div>
  );
}

export default OrpheusMap;
