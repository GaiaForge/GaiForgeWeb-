import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Dashboard.css';

const API_BASE = window.location.origin;

const CATEGORIES = [
  { key: 'inspection', label: 'Inspection', icon: '🔍', color: '#3b82f6' },
  { key: 'treatment', label: 'Treatment', icon: '💊', color: '#8b5cf6' },
  { key: 'feeding', label: 'Feeding', icon: '🍯', color: '#f59e0b' },
  { key: 'observation', label: 'Observation', icon: '👁️', color: '#10b981' },
  { key: 'event', label: 'Event', icon: '📌', color: '#06b6d4' },
  { key: 'concern', label: 'Concern', icon: '⚠️', color: '#ef4444' },
];

function Journal({ user, onLogout }) {
  const navigate = useNavigate();
  const [hives, setHives] = useState([]);
  const [selectedHive, setSelectedHive] = useState('');
  const [entries, setEntries] = useState([]);
  const [loading, setLoading] = useState(false);
  const [filterCat, setFilterCat] = useState('');

  // New entry form
  const [showForm, setShowForm] = useState(false);
  const [formCat, setFormCat] = useState('observation');
  const [formNote, setFormNote] = useState('');
  const [formWeather, setFormWeather] = useState('');
  const [saving, setSaving] = useState(false);

  // Edit
  const [editId, setEditId] = useState(null);
  const [editNote, setEditNote] = useState('');
  const [editCat, setEditCat] = useState('');

  const headers = {
    'Authorization': `Bearer ${user?.token}`,
    'Content-Type': 'application/json',
  };

  useEffect(() => {
    fetch(`${API_BASE}/api/hives`, { headers })
      .then(r => r.ok ? r.json() : [])
      .then(data => {
        setHives(data);
        if (data.length > 0 && !selectedHive) setSelectedHive(String(data[0].id));
      });
  }, []);

  useEffect(() => {
    if (selectedHive) fetchEntries();
  }, [selectedHive, filterCat]);

  const fetchEntries = async () => {
    setLoading(true);
    const params = new URLSearchParams();
    if (filterCat) params.set('category', filterCat);
    try {
      const res = await fetch(`${API_BASE}/api/journal/${selectedHive}?${params}`, { headers });
      if (res.ok) setEntries(await res.json());
    } catch {} finally { setLoading(false); }
  };

  const createEntry = async () => {
    if (!formNote.trim()) return;
    setSaving(true);
    try {
      const res = await fetch(`${API_BASE}/api/journal`, {
        method: 'POST', headers,
        body: JSON.stringify({
          hive_id: Number(selectedHive),
          category: formCat,
          note: formNote,
          weather_note: formWeather || null,
        }),
      });
      if (res.ok) {
        setFormNote('');
        setFormWeather('');
        setShowForm(false);
        fetchEntries();
      }
    } catch {} finally { setSaving(false); }
  };

  const saveEdit = async (id) => {
    try {
      const res = await fetch(`${API_BASE}/api/journal/${id}`, {
        method: 'PUT', headers,
        body: JSON.stringify({ note: editNote, category: editCat }),
      });
      if (res.ok) { setEditId(null); fetchEntries(); }
    } catch {}
  };

  const deleteEntry = async (id) => {
    if (!window.confirm('Delete this journal entry?')) return;
    try {
      const res = await fetch(`${API_BASE}/api/journal/${id}`, { method: 'DELETE', headers });
      if (res.ok) fetchEntries();
    } catch {}
  };

  const getCat = (key) => CATEGORIES.find(c => c.key === key) || CATEGORIES[3];
  const handleLogout = () => { onLogout(); navigate('/login'); };

  return (
    <div className="dashboard-container">
      <aside className="sidebar">
        <div className="sidebar-header">
          <a href="/"><img src="/gaiaforge-logo.png" alt="GaiaForge" className="logo-image" /></a>
        </div>
        <nav className="sidebar-nav">
          <a href="/" className="nav-item back-link"><span className="nav-icon">&#8592;</span> Back to Site</a>
          <Link to="/dashboard" className="nav-item"><span className="nav-icon">&#128202;</span> Dashboard</Link>
          <Link to="/analytics" className="nav-item"><span className="nav-icon">&#128300;</span> Analytics</Link>
          <Link to="/upload" className="nav-item"><span className="nav-icon">&#11014;&#65039;</span> Upload Data</Link>
          <Link to="/devices" className="nav-item"><span className="nav-icon">&#128223;</span> My Hives</Link>
          <Link to="/journal" className="nav-item active"><span className="nav-icon">&#128221;</span> Journal</Link>
          <Link to="/alerts" className="nav-item"><span className="nav-icon">&#128276;</span> Alerts</Link>
          <Link to="/profile" className="nav-item"><span className="nav-icon">&#128100;</span> Profile</Link>
          {user?.is_admin && <Link to="/admin" className="nav-item"><span className="nav-icon">&#9881;&#65039;</span> Admin</Link>}
        </nav>
        <div className="sidebar-footer">
          <button onClick={handleLogout} className="logout-btn"><span className="nav-icon">&#128682;</span> Logout</button>
        </div>
      </aside>

      <main className="main-content">
        <header className="content-header">
          <div>
            <h1>Hive Journal</h1>
            <p>Inspection notes, treatments, and observations</p>
          </div>
          <button onClick={() => setShowForm(!showForm)} style={{
            padding: '10px 20px', background: '#f59e0b', color: '#fff',
            border: 'none', borderRadius: '10px', fontWeight: 600, cursor: 'pointer', fontSize: '14px',
          }}>
            {showForm ? 'Cancel' : '+ New Entry'}
          </button>
        </header>

        {/* Hive selector + category filter */}
        <div style={{display:'flex', gap:'12px', marginBottom:'20px', flexWrap:'wrap'}}>
          <select value={selectedHive} onChange={e => setSelectedHive(e.target.value)}
            style={{padding:'10px 14px', border:'2px solid #e5e7eb', borderRadius:'10px', fontSize:'14px', background:'#fff'}}>
            {hives.map(h => <option key={h.id} value={h.id}>{h.name}</option>)}
          </select>
          <select value={filterCat} onChange={e => setFilterCat(e.target.value)}
            style={{padding:'10px 14px', border:'2px solid #e5e7eb', borderRadius:'10px', fontSize:'14px', background:'#fff'}}>
            <option value="">All categories</option>
            {CATEGORIES.map(c => <option key={c.key} value={c.key}>{c.icon} {c.label}</option>)}
          </select>
        </div>

        {/* New entry form */}
        {showForm && (
          <div style={{
            background:'#fff', border:'2px solid #f59e0b', borderRadius:'16px',
            padding:'24px', marginBottom:'24px',
          }}>
            <h3 style={{margin:'0 0 16px', color:'#1f2937'}}>New Journal Entry</h3>
            <div style={{display:'flex', gap:'8px', flexWrap:'wrap', marginBottom:'16px'}}>
              {CATEGORIES.map(c => (
                <button key={c.key} onClick={() => setFormCat(c.key)}
                  style={{
                    padding:'6px 14px', borderRadius:'20px', border:'2px solid',
                    borderColor: formCat === c.key ? c.color : '#e5e7eb',
                    background: formCat === c.key ? c.color + '18' : '#fff',
                    color: formCat === c.key ? c.color : '#6b7280',
                    fontWeight: formCat === c.key ? 700 : 400,
                    cursor:'pointer', fontSize:'13px',
                  }}>
                  {c.icon} {c.label}
                </button>
              ))}
            </div>
            <textarea value={formNote} onChange={e => setFormNote(e.target.value)}
              placeholder="What did you observe? What action did you take?"
              rows={4}
              style={{
                width:'100%', padding:'12px', border:'2px solid #e5e7eb', borderRadius:'10px',
                fontSize:'14px', resize:'vertical', marginBottom:'12px', fontFamily:'inherit',
              }}
            />
            <input value={formWeather} onChange={e => setFormWeather(e.target.value)}
              placeholder="Weather conditions (optional)"
              style={{
                width:'100%', padding:'10px 12px', border:'2px solid #e5e7eb', borderRadius:'10px',
                fontSize:'14px', marginBottom:'16px',
              }}
            />
            <button onClick={createEntry} disabled={saving || !formNote.trim()}
              style={{
                padding:'10px 24px', background:'#f59e0b', color:'#fff',
                border:'none', borderRadius:'10px', fontWeight:600, cursor:'pointer',
                opacity: saving || !formNote.trim() ? 0.5 : 1,
              }}>
              {saving ? 'Saving...' : 'Save Entry'}
            </button>
          </div>
        )}

        {/* Timeline */}
        {loading ? (
          <div className="loading-state">Loading journal...</div>
        ) : entries.length === 0 ? (
          <div style={{textAlign:'center', padding:'60px 24px', color:'#6b7280'}}>
            <div style={{fontSize:'48px', marginBottom:'16px'}}>&#128221;</div>
            <h3 style={{color:'#374151'}}>No journal entries yet</h3>
            <p>Start documenting your hive inspections and observations.</p>
          </div>
        ) : (
          <div style={{position:'relative', paddingLeft:'32px'}}>
            {/* Timeline line */}
            <div style={{
              position:'absolute', left:'15px', top:'0', bottom:'0',
              width:'2px', background:'#e5e7eb',
            }} />

            {entries.map(entry => {
              const cat = getCat(entry.category);
              const isEditing = editId === entry.id;
              return (
                <div key={entry.id} style={{position:'relative', marginBottom:'20px'}}>
                  {/* Timeline dot */}
                  <div style={{
                    position:'absolute', left:'-25px', top:'6px',
                    width:'12px', height:'12px', borderRadius:'50%',
                    background: cat.color, border:'2px solid #fff',
                    boxShadow:'0 0 0 2px ' + cat.color + '40',
                  }} />

                  <div style={{
                    background:'#fff', borderRadius:'12px', padding:'16px 20px',
                    boxShadow:'0 1px 3px rgba(0,0,0,0.08)', border:'1px solid #f3f4f6',
                  }}>
                    <div style={{display:'flex', justifyContent:'space-between', alignItems:'flex-start', marginBottom:'8px'}}>
                      <div style={{display:'flex', alignItems:'center', gap:'8px'}}>
                        <span style={{
                          padding:'3px 10px', borderRadius:'12px', fontSize:'12px', fontWeight:600,
                          background: cat.color + '18', color: cat.color,
                        }}>
                          {cat.icon} {cat.label}
                        </span>
                        <span style={{fontSize:'12px', color:'#9ca3af'}}>
                          {new Date(entry.timestamp).toLocaleString()}
                        </span>
                        <span style={{fontSize:'11px', color:'#d1d5db'}}>
                          by {entry.author_name}
                        </span>
                      </div>
                      <div style={{display:'flex', gap:'6px'}}>
                        <button onClick={() => { setEditId(entry.id); setEditNote(entry.note); setEditCat(entry.category); }}
                          style={{background:'none', border:'none', cursor:'pointer', fontSize:'14px', color:'#6b7280'}}>&#9998;</button>
                        <button onClick={() => deleteEntry(entry.id)}
                          style={{background:'none', border:'none', cursor:'pointer', fontSize:'14px', color:'#ef4444'}}>&#128465;</button>
                      </div>
                    </div>

                    {isEditing ? (
                      <div>
                        <div style={{display:'flex', gap:'6px', marginBottom:'8px', flexWrap:'wrap'}}>
                          {CATEGORIES.map(c => (
                            <button key={c.key} onClick={() => setEditCat(c.key)}
                              style={{
                                padding:'3px 10px', borderRadius:'12px', fontSize:'11px', border:'1px solid',
                                borderColor: editCat === c.key ? c.color : '#e5e7eb',
                                background: editCat === c.key ? c.color + '18' : '#fff',
                                color: editCat === c.key ? c.color : '#9ca3af',
                                cursor:'pointer',
                              }}>
                              {c.icon} {c.label}
                            </button>
                          ))}
                        </div>
                        <textarea value={editNote} onChange={e => setEditNote(e.target.value)}
                          rows={3} style={{width:'100%', padding:'10px', border:'2px solid #e5e7eb', borderRadius:'8px', fontSize:'14px', marginBottom:'8px', fontFamily:'inherit'}} />
                        <div style={{display:'flex', gap:'8px'}}>
                          <button onClick={() => saveEdit(entry.id)}
                            style={{padding:'6px 16px', background:'#10b981', color:'#fff', border:'none', borderRadius:'8px', fontWeight:600, cursor:'pointer', fontSize:'13px'}}>Save</button>
                          <button onClick={() => setEditId(null)}
                            style={{padding:'6px 16px', background:'#e5e7eb', color:'#374151', border:'none', borderRadius:'8px', cursor:'pointer', fontSize:'13px'}}>Cancel</button>
                        </div>
                      </div>
                    ) : (
                      <p style={{margin:0, color:'#374151', fontSize:'14px', lineHeight:'1.6', whiteSpace:'pre-wrap'}}>
                        {entry.note}
                      </p>
                    )}

                    {entry.weather_note && (
                      <div style={{marginTop:'8px', fontSize:'12px', color:'#6b7280'}}>
                        &#9729;&#65039; {entry.weather_note}
                      </div>
                    )}
                    {(entry.temperature || entry.humidity) && (
                      <div style={{marginTop:'4px', fontSize:'12px', color:'#9ca3af'}}>
                        {entry.temperature && `${entry.temperature.toFixed(1)}°C`}
                        {entry.temperature && entry.humidity && ' · '}
                        {entry.humidity && `${entry.humidity.toFixed(0)}% RH`}
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </main>
    </div>
  );
}

export default Journal;
