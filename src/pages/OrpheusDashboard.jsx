import React, { useState, useEffect, useRef, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import ProductDocs from '../components/ProductDocs';

const API_BASE = window.location.origin;

function OrpheusDashboard({ user, onLogout }) {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('downloads');
  const [firmwareUpdates, setFirmwareUpdates] = useState([]);
  const [loadingFirmware, setLoadingFirmware] = useState(true);

  // Admin upload state
  const [uploadFile, setUploadFile] = useState(null);
  const [uploadVersion, setUploadVersion] = useState('');
  const [uploadNotes, setUploadNotes] = useState('');
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState('');
  const [uploadSuccess, setUploadSuccess] = useState('');
  const [dragging, setDragging] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  const fileInputRef = useRef(null);

  // Mobile app (APK) state
  const [appReleases, setAppReleases] = useState([]);
  const [loadingApp, setLoadingApp] = useState(true);
  const [appUploadFile, setAppUploadFile] = useState(null);
  const [appUploadVersion, setAppUploadVersion] = useState('');
  const [appUploadNotes, setAppUploadNotes] = useState('');
  const [appUploading, setAppUploading] = useState(false);
  const [appUploadError, setAppUploadError] = useState('');
  const [appUploadSuccess, setAppUploadSuccess] = useState('');
  const [appDragging, setAppDragging] = useState(false);
  const [appDeleteConfirm, setAppDeleteConfirm] = useState(null);
  const appFileInputRef = useRef(null);

  const headers = {
    'Authorization': `Bearer ${user?.token}`,
  };

  const handleLogout = () => {
    onLogout();
    navigate('/login');
  };

  const fetchFirmware = useCallback(async () => {
    try {
      const res = await fetch(`${API_BASE}/downloads/orpheus/manifest.json?t=${Date.now()}`);
      if (res.ok) {
        const data = await res.json();
        setFirmwareUpdates(data.releases || []);
      } else {
        setFirmwareUpdates([]);
      }
    } catch {
      setFirmwareUpdates([]);
    } finally {
      setLoadingFirmware(false);
    }
  }, []);

  const fetchApp = useCallback(async () => {
    try {
      const res = await fetch(`${API_BASE}/downloads/orpheus/app/manifest.json?t=${Date.now()}`);
      if (res.ok) {
        const data = await res.json();
        setAppReleases(data.releases || []);
      } else {
        setAppReleases([]);
      }
    } catch {
      setAppReleases([]);
    } finally {
      setLoadingApp(false);
    }
  }, []);

  useEffect(() => {
    fetchFirmware();
    fetchApp();
  }, [fetchFirmware, fetchApp]);

  // Prevent browser from opening dropped files anywhere on the page
  useEffect(() => {
    const prevent = (e) => { e.preventDefault(); e.stopPropagation(); };
    window.addEventListener('dragover', prevent);
    window.addEventListener('drop', prevent);
    return () => {
      window.removeEventListener('dragover', prevent);
      window.removeEventListener('drop', prevent);
    };
  }, []);

  // Drag and drop handlers
  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setDragging(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setDragging(false);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setDragging(false);
    const file = e.dataTransfer.files[0];
    if (file && file.name.endsWith('.zip')) {
      setUploadFile(file);
      setUploadError('');
    } else {
      setUploadError('Please drop a .zip file');
    }
  };

  const handleFileSelect = (e) => {
    const file = e.target.files[0];
    if (file) {
      setUploadFile(file);
      setUploadError('');
    }
  };

  const handleUpload = async () => {
    if (!uploadFile) {
      setUploadError('Please select a file');
      return;
    }
    if (!uploadVersion.trim()) {
      setUploadError('Please enter a version number');
      return;
    }
    if (!/^\d+\.\d+(\.\d+)?$/.test(uploadVersion.trim())) {
      setUploadError('Version must be in format X.Y or X.Y.Z (e.g. 1.48)');
      return;
    }

    setUploading(true);
    setUploadError('');
    setUploadSuccess('');

    const formData = new FormData();
    formData.append('file', uploadFile);
    formData.append('version', uploadVersion.trim());
    formData.append('notes', uploadNotes.trim());

    try {
      const res = await fetch(`${API_BASE}/api/orpheus/firmware/upload`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${user?.token}` },
        body: formData,
      });

      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.detail || 'Upload failed');
      }

      setUploadSuccess(`v${uploadVersion.trim()} uploaded successfully`);
      setUploadFile(null);
      setUploadVersion('');
      setUploadNotes('');
      if (fileInputRef.current) fileInputRef.current.value = '';
      fetchFirmware();
    } catch (err) {
      setUploadError(err.message || 'Upload failed');
    } finally {
      setUploading(false);
    }
  };

  const handleDelete = async (filename) => {
    try {
      const res = await fetch(`${API_BASE}/api/orpheus/firmware/${encodeURIComponent(filename)}`, {
        method: 'DELETE',
        headers,
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.detail || 'Delete failed');
      }
      setDeleteConfirm(null);
      fetchFirmware();
    } catch (err) {
      setUploadError(err.message || 'Delete failed');
      setDeleteConfirm(null);
    }
  };

  const formatFileSize = (bytes) => {
    if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + ' MB';
    if (bytes >= 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return bytes + ' B';
  };

  // --- Mobile app (APK) admin handlers — mirrors firmware upload above ---
  const handleAppDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setAppDragging(true);
  };

  const handleAppDragLeave = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setAppDragging(false);
  };

  const handleAppDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setAppDragging(false);
    const file = e.dataTransfer.files[0];
    if (file && file.name.endsWith('.apk')) {
      setAppUploadFile(file);
      setAppUploadError('');
    } else {
      setAppUploadError('Please drop an .apk file');
    }
  };

  const handleAppFileSelect = (e) => {
    const file = e.target.files[0];
    if (file) {
      setAppUploadFile(file);
      setAppUploadError('');
    }
  };

  const handleAppUpload = async () => {
    if (!appUploadFile) {
      setAppUploadError('Please select a file');
      return;
    }
    if (!appUploadVersion.trim()) {
      setAppUploadError('Please enter a version number');
      return;
    }
    if (!/^\d+\.\d+(\.\d+)?$/.test(appUploadVersion.trim())) {
      setAppUploadError('Version must be in format X.Y or X.Y.Z (e.g. 1.48)');
      return;
    }

    setAppUploading(true);
    setAppUploadError('');
    setAppUploadSuccess('');

    const formData = new FormData();
    formData.append('file', appUploadFile);
    formData.append('version', appUploadVersion.trim());
    formData.append('notes', appUploadNotes.trim());

    try {
      const res = await fetch(`${API_BASE}/api/orpheus/app/upload`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${user?.token}` },
        body: formData,
      });

      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.detail || 'Upload failed');
      }

      setAppUploadSuccess(`v${appUploadVersion.trim()} uploaded successfully`);
      setAppUploadFile(null);
      setAppUploadVersion('');
      setAppUploadNotes('');
      if (appFileInputRef.current) appFileInputRef.current.value = '';
      fetchApp();
    } catch (err) {
      setAppUploadError(err.message || 'Upload failed');
    } finally {
      setAppUploading(false);
    }
  };

  const handleAppDelete = async (filename) => {
    try {
      const res = await fetch(`${API_BASE}/api/orpheus/app/${encodeURIComponent(filename)}`, {
        method: 'DELETE',
        headers,
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.detail || 'Delete failed');
      }
      setAppDeleteConfirm(null);
      fetchApp();
    } catch (err) {
      setAppUploadError(err.message || 'Delete failed');
      setAppDeleteConfirm(null);
    }
  };

  const latestApp = appReleases[0];
  const mobileApp = {
    android: latestApp
      ? {
          version: latestApp.version,
          href: `/downloads/orpheus/${latestApp.filename}`,
          size: latestApp.size,
        }
      : {
          version: '1.8.8',
          href: '/downloads/Orpheus-v1.8.8.apk',
          size: '57 MB',
        },
    ios: null,
  };

  return (
    <div className="dashboard-container">
      <aside className="sidebar">
        <div className="sidebar-header">
          <a href="/"><img src="/gaiaforge-logo.png" alt="GaiaForge" className="logo-image" /></a>
        </div>
        <nav className="sidebar-nav">
          <Link to="/products" className="nav-item back-link">
            <span className="nav-icon">&larr;</span> All Products
          </Link>
          <button
            className={`nav-item nav-btn ${activeTab === 'downloads' ? 'active' : ''}`}
            onClick={() => setActiveTab('downloads')}
          >
            <span className="nav-icon">📦</span> USB Updates
          </button>
          <button
            className={`nav-item nav-btn ${activeTab === 'docs' ? 'active' : ''}`}
            onClick={() => setActiveTab('docs')}
          >
            <span className="nav-icon">📖</span> Documentation
          </button>
          <button
            className={`nav-item nav-btn ${activeTab === 'app' ? 'active' : ''}`}
            onClick={() => setActiveTab('app')}
          >
            <span className="nav-icon">📱</span> Mobile App
          </button>
          {user?.is_admin && (
            <button
              className={`nav-item nav-btn ${activeTab === 'admin-upload' ? 'active' : ''}`}
              onClick={() => setActiveTab('admin-upload')}
            >
              <span className="nav-icon">⬆️</span> Upload Firmware
            </button>
          )}
          {user?.is_admin && (
            <button
              className={`nav-item nav-btn ${activeTab === 'admin-app' ? 'active' : ''}`}
              onClick={() => setActiveTab('admin-app')}
            >
              <span className="nav-icon">📲</span> Upload App
            </button>
          )}
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
            <h1>Orpheus Portal</h1>
            <p>Manage your Orpheus audio playback devices</p>
          </div>
          <div className="user-avatar">
            {user?.name?.charAt(0).toUpperCase() || 'U'}
          </div>
        </header>

        {/* USB Updates Tab */}
        {activeTab === 'downloads' && (
          <>
            <div className="orpheus-info-banner">
              <div className="info-icon">💡</div>
              <div>
                <strong>How USB updates work:</strong> Download the .zip file below.
                Create a folder called <code style={{background:'#e2e8f0',padding:'2px 6px',borderRadius:'4px'}}>orpheus_update</code> on your USB drive and place the zip inside it.
                Insert the USB into your Orpheus device and use the Settings &gt; Update tab to apply.
                The same firmware works for both Basic and Pro — the variant is set during commissioning.
              </div>
            </div>

            <div className="actions-section">
              <h2>Firmware &amp; Software Updates</h2>
              {loadingFirmware ? (
                <div className="loading-state">Loading available updates...</div>
              ) : firmwareUpdates.length === 0 ? (
                <div className="empty-state">
                  <div className="empty-icon">📦</div>
                  <h2>No updates available yet</h2>
                  <p>Check back soon for firmware and software updates.</p>
                </div>
              ) : (
                <div className="orpheus-downloads-list">
                  {firmwareUpdates.map((update, i) => (
                    <div key={i} className="orpheus-download-row">
                      <div className="orpheus-download-info">
                        <div className="orpheus-download-icon">
                          <span className="variant-badge firmware">v{update.version}</span>
                        </div>
                        <div>
                          <div className="upload-name">
                            {update.filename}
                          </div>
                          <div className="upload-meta">
                            v{update.version} &middot; {update.date} &middot; {update.size}
                          </div>
                          {update.notes && (
                            <div className="release-notes">
                              {update.notes}
                            </div>
                          )}
                        </div>
                      </div>
                      <a
                        href={`/downloads/orpheus/${update.filename}`}
                        className="btn-download"
                        download
                      >
                        Download
                      </a>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </>
        )}

        {/* Admin Upload Tab */}
        {activeTab === 'admin-upload' && user?.is_admin && (
          <div className="actions-section">
            <h2>Upload New Firmware</h2>
            <p style={{ color: '#6b7280', marginBottom: '24px' }}>
              Upload a password-protected .zip containing firmware and application files.
              It will appear in the downloads list for all registered users.
            </p>

            {uploadError && <div className="error-message">{uploadError}</div>}
            {uploadSuccess && (
              <div className="orpheus-info-banner" style={{ background: '#ecfdf5', borderColor: '#a7f3d0', color: '#065f46', marginBottom: '20px' }}>
                <div className="info-icon">✅</div>
                <div><strong>{uploadSuccess}</strong></div>
              </div>
            )}

            {/* Dropzone */}
            <div
              className={`fw-dropzone ${dragging ? 'dragging' : ''} ${uploadFile ? 'has-file' : ''}`}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              onClick={() => fileInputRef.current?.click()}
            >
              <input
                ref={fileInputRef}
                type="file"
                accept=".zip"
                onChange={handleFileSelect}
                style={{ display: 'none' }}
              />
              {uploadFile ? (
                <div className="fw-dropzone-selected">
                  <div className="fw-file-icon">📦</div>
                  <div>
                    <div className="upload-name">{uploadFile.name}</div>
                    <div className="upload-meta">{formatFileSize(uploadFile.size)}</div>
                  </div>
                  <button
                    className="fw-remove-btn"
                    onClick={(e) => {
                      e.stopPropagation();
                      setUploadFile(null);
                      if (fileInputRef.current) fileInputRef.current.value = '';
                    }}
                  >
                    &times;
                  </button>
                </div>
              ) : (
                <>
                  <div className="fw-dropzone-icon">⬆️</div>
                  <h3>Drag &amp; drop a .zip file here</h3>
                  <p>or click to browse</p>
                </>
              )}
            </div>

            {/* Version & Notes */}
            <div className="fw-form">
              <div className="form-group">
                <label htmlFor="fw-version">Version Number</label>
                <input
                  type="text"
                  id="fw-version"
                  value={uploadVersion}
                  onChange={(e) => setUploadVersion(e.target.value)}
                  placeholder="e.g. 1.48"
                  disabled={uploading}
                />
              </div>
              <div className="form-group">
                <label htmlFor="fw-notes">Release Notes (optional)</label>
                <textarea
                  id="fw-notes"
                  value={uploadNotes}
                  onChange={(e) => setUploadNotes(e.target.value)}
                  placeholder="Brief description of changes..."
                  rows={3}
                  disabled={uploading}
                  className="fw-textarea"
                />
              </div>
              <button
                className="btn-upload"
                onClick={handleUpload}
                disabled={uploading || !uploadFile}
              >
                {uploading ? 'Uploading...' : 'Upload Firmware'}
              </button>
            </div>

            {/* Existing releases management */}
            {firmwareUpdates.length > 0 && (
              <div style={{ marginTop: '40px' }}>
                <h2>Manage Releases</h2>
                <div className="orpheus-downloads-list" style={{ marginTop: '16px' }}>
                  {firmwareUpdates.map((update, i) => (
                    <div key={i} className="orpheus-download-row">
                      <div className="orpheus-download-info">
                        <div className="orpheus-download-icon">
                          <span className="variant-badge firmware">v{update.version}</span>
                        </div>
                        <div>
                          <div className="upload-name">{update.filename}</div>
                          <div className="upload-meta">
                            {update.date} &middot; {update.size}
                          </div>
                        </div>
                      </div>
                      {deleteConfirm === update.filename ? (
                        <div style={{ display: 'flex', gap: '8px' }}>
                          <button
                            className="btn-download"
                            style={{ background: 'linear-gradient(135deg, #dc2626, #b91c1c)' }}
                            onClick={() => handleDelete(update.filename)}
                          >
                            Confirm
                          </button>
                          <button
                            className="btn-download"
                            style={{ background: '#6b7280' }}
                            onClick={() => setDeleteConfirm(null)}
                          >
                            Cancel
                          </button>
                        </div>
                      ) : (
                        <button
                          className="btn-download"
                          style={{ background: 'linear-gradient(135deg, #dc2626, #b91c1c)' }}
                          onClick={() => setDeleteConfirm(update.filename)}
                        >
                          Delete
                        </button>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* Admin Upload App Tab */}
        {activeTab === 'admin-app' && user?.is_admin && (
          <div className="actions-section">
            <h2>Upload New Android App</h2>
            <p style={{ color: '#6b7280', marginBottom: '24px' }}>
              Upload the Orpheus Remote .apk. It will replace the current version on the
              Mobile App tab for all registered users.
            </p>

            {appUploadError && <div className="error-message">{appUploadError}</div>}
            {appUploadSuccess && (
              <div className="orpheus-info-banner" style={{ background: '#ecfdf5', borderColor: '#a7f3d0', color: '#065f46', marginBottom: '20px' }}>
                <div className="info-icon">✅</div>
                <div><strong>{appUploadSuccess}</strong></div>
              </div>
            )}

            <div
              className={`fw-dropzone ${appDragging ? 'dragging' : ''} ${appUploadFile ? 'has-file' : ''}`}
              onDragOver={handleAppDragOver}
              onDragLeave={handleAppDragLeave}
              onDrop={handleAppDrop}
              onClick={() => appFileInputRef.current?.click()}
            >
              <input
                ref={appFileInputRef}
                type="file"
                accept=".apk"
                onChange={handleAppFileSelect}
                style={{ display: 'none' }}
              />
              {appUploadFile ? (
                <div className="fw-dropzone-selected">
                  <div className="fw-file-icon">📲</div>
                  <div>
                    <div className="upload-name">{appUploadFile.name}</div>
                    <div className="upload-meta">{formatFileSize(appUploadFile.size)}</div>
                  </div>
                  <button
                    className="fw-remove-btn"
                    onClick={(e) => {
                      e.stopPropagation();
                      setAppUploadFile(null);
                      if (appFileInputRef.current) appFileInputRef.current.value = '';
                    }}
                  >
                    &times;
                  </button>
                </div>
              ) : (
                <>
                  <div className="fw-dropzone-icon">⬆️</div>
                  <h3>Drag &amp; drop an .apk file here</h3>
                  <p>or click to browse</p>
                </>
              )}
            </div>

            <div className="fw-form">
              <div className="form-group">
                <label htmlFor="app-version">Version Number</label>
                <input
                  type="text"
                  id="app-version"
                  value={appUploadVersion}
                  onChange={(e) => setAppUploadVersion(e.target.value)}
                  placeholder="e.g. 1.8.8"
                  disabled={appUploading}
                />
              </div>
              <div className="form-group">
                <label htmlFor="app-notes">Release Notes (optional)</label>
                <textarea
                  id="app-notes"
                  value={appUploadNotes}
                  onChange={(e) => setAppUploadNotes(e.target.value)}
                  placeholder="Brief description of changes..."
                  rows={3}
                  disabled={appUploading}
                  className="fw-textarea"
                />
              </div>
              <button
                className="btn-upload"
                onClick={handleAppUpload}
                disabled={appUploading || !appUploadFile}
              >
                {appUploading ? 'Uploading...' : 'Upload App'}
              </button>
            </div>

            {appReleases.length > 0 && (
              <div style={{ marginTop: '40px' }}>
                <h2>Manage Releases</h2>
                <div className="orpheus-downloads-list" style={{ marginTop: '16px' }}>
                  {appReleases.map((update, i) => (
                    <div key={i} className="orpheus-download-row">
                      <div className="orpheus-download-info">
                        <div className="orpheus-download-icon">
                          <span className="variant-badge firmware">v{update.version}</span>
                        </div>
                        <div>
                          <div className="upload-name">Orpheus Remote.apk</div>
                          <div className="upload-meta">
                            {update.date} &middot; {update.size}
                          </div>
                          {update.notes && <div className="release-notes">{update.notes}</div>}
                        </div>
                      </div>
                      {appDeleteConfirm === update.filename ? (
                        <div style={{ display: 'flex', gap: '8px' }}>
                          <button
                            className="btn-download"
                            style={{ background: 'linear-gradient(135deg, #dc2626, #b91c1c)' }}
                            onClick={() => handleAppDelete(update.filename)}
                          >
                            Confirm
                          </button>
                          <button
                            className="btn-download"
                            style={{ background: '#6b7280' }}
                            onClick={() => setAppDeleteConfirm(null)}
                          >
                            Cancel
                          </button>
                        </div>
                      ) : (
                        <button
                          className="btn-download"
                          style={{ background: 'linear-gradient(135deg, #dc2626, #b91c1c)' }}
                          onClick={() => setAppDeleteConfirm(update.filename)}
                        >
                          Delete
                        </button>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* Documentation Tab */}
        {activeTab === 'docs' && (
          <ProductDocs product="orpheus" />
        )}

        {/* Mobile App Tab */}
        {activeTab === 'app' && (
          <div className="actions-section">
            <h2>Orpheus Mobile App</h2>
            <p style={{ color: '#6b7280', marginBottom: '24px' }}>
              Control your Orpheus device via Bluetooth. Create playlists, set schedules, and monitor device status.
            </p>
            <div className="actions-grid">
              <a
                href={mobileApp.android.href}
                className="action-card"
                download
              >
                <div className="action-icon">🤖</div>
                <h3>Android APK</h3>
                <p>Version {mobileApp.android.version} &middot; {mobileApp.android.size}</p>
                <span className="selector-badge-open" style={{ marginTop: '12px', display: 'inline-block' }}>
                  Download APK
                </span>
              </a>
              <div className="action-card" style={{ opacity: 0.5, cursor: 'default' }}>
                <div className="action-icon">🍎</div>
                <h3>iOS App</h3>
                <p>Coming soon to the App Store.</p>
                <span className="selector-badge-soon" style={{ marginTop: '12px', display: 'inline-block' }}>
                  Coming Soon
                </span>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

export default OrpheusDashboard;
