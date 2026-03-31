import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import './Auth.css';

const API_BASE = window.location.origin;

const deviceTypes = [
  { id: 'orpheus', name: 'Orpheus', image: '/images/Orpheus.png', desc: 'Audio playback for wildlife research' },
  { id: 'hiveguard', name: 'HiveGuard', image: '/images/hiveguard_logo.png', desc: 'Bioacoustic beehive monitor' },
  { id: 'sprigrig', name: 'SprigRig', image: '/images/SprigRig.png', desc: 'Controlled environment agriculture' },
];

function Register({ onRegister }) {
  const [step, setStep] = useState(1); // 1: select device, 2: serial + account details
  const [selectedDevice, setSelectedDevice] = useState(null);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
    deviceSerial: '',
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleDeviceSelect = (deviceId) => {
    setSelectedDevice(deviceId);
    setError('');
    setStep(2);
  };

  const handleBack = () => {
    setStep(1);
    setError('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (!formData.deviceSerial.trim()) {
      setError('Please enter your device serial number');
      return;
    }
    if (!formData.name || !formData.email || !formData.password || !formData.confirmPassword) {
      setError('Please fill in all fields');
      return;
    }
    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      return;
    }
    if (formData.password.length < 8) {
      setError('Password must be at least 8 characters');
      return;
    }

    setLoading(true);
    try {
      const res = await fetch(`${API_BASE}/api/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: formData.email,
          password: formData.password,
          name: formData.name,
          device_serial: formData.deviceSerial.trim(),
          device_type: selectedDevice,
        }),
      });

      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.detail || 'Registration failed');
      }

      const data = await res.json();
      const userData = {
        email: formData.email,
        name: formData.name,
        token: data.access_token,
        api_key: data.api_key,
        subscription_tier: data.subscription_tier || 'free',
        is_admin: data.is_admin || false,
        products: data.products || [],
      };
      onRegister(userData);
      navigate('/products');
    } catch (err) {
      setError(err.message || 'Registration failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-container">
      <div className="auth-background">
        <div className="auth-blob blob-1"></div>
        <div className="auth-blob blob-2"></div>
        <div className="auth-blob blob-3"></div>
      </div>

      <div className="auth-card" style={step === 1 ? { maxWidth: '650px' } : {}}>
        <div className="auth-header">
          <div className="logo">
            <span className="logo-gaia">GAIA</span>
            <span className="logo-forge">FORGE</span>
          </div>
          {step === 1 ? (
            <>
              <h1>Register Your Device</h1>
              <p>Which GaiaForge device do you own?</p>
            </>
          ) : (
            <>
              <h1>Create Account</h1>
              <p>Register your {deviceTypes.find(d => d.id === selectedDevice)?.name} device</p>
            </>
          )}
        </div>

        {step === 1 && (
          <>
            <div className="device-select-grid">
              {deviceTypes.map((device) => (
                <button
                  key={device.id}
                  className="device-select-card"
                  onClick={() => handleDeviceSelect(device.id)}
                >
                  <img src={device.image} alt={device.name} className="device-select-img" />
                  <h3>{device.name}</h3>
                  <p>{device.desc}</p>
                </button>
              ))}
            </div>
            <div className="auth-footer">
              <p>
                Already have an account? <Link to="/login">Sign in</Link>
              </p>
            </div>
          </>
        )}

        {step === 2 && (
          <>
            <form onSubmit={handleSubmit} className="auth-form">
              {error && <div className="error-message">{error}</div>}

              <div className="form-group">
                <label htmlFor="deviceSerial">Device Serial Number</label>
                <input type="text" id="deviceSerial" name="deviceSerial"
                  value={formData.deviceSerial} onChange={handleChange}
                  placeholder="Enter the serial number from your device"
                  required disabled={loading}
                  style={{ fontFamily: 'monospace', letterSpacing: '1px' }}
                />
                <small style={{ color: '#9ca3af', fontSize: '12px', marginTop: '4px', display: 'block' }}>
                  Found on the device label or in the mobile app under Settings
                </small>
              </div>

              <div className="form-group">
                <label htmlFor="name">Full Name</label>
                <input type="text" id="name" name="name" value={formData.name}
                  onChange={handleChange} placeholder="Your name" required disabled={loading} />
              </div>

              <div className="form-group">
                <label htmlFor="email">Email Address</label>
                <input type="email" id="email" name="email" value={formData.email}
                  onChange={handleChange} placeholder="you@example.com" required disabled={loading} />
              </div>

              <div className="form-group">
                <label htmlFor="password">Password</label>
                <input type="password" id="password" name="password" value={formData.password}
                  onChange={handleChange} placeholder="--------" required disabled={loading} />
              </div>

              <div className="form-group">
                <label htmlFor="confirmPassword">Confirm Password</label>
                <input type="password" id="confirmPassword" name="confirmPassword"
                  value={formData.confirmPassword} onChange={handleChange}
                  placeholder="--------" required disabled={loading} />
              </div>

              <button type="submit" className="btn-primary" disabled={loading}>
                {loading ? 'Creating account...' : 'Create Account'}
              </button>
            </form>

            <div className="auth-footer">
              <p>
                <button onClick={handleBack} className="back-link-btn">
                  &larr; Choose a different device
                </button>
              </p>
              <p>
                Already have an account? <Link to="/login">Sign in</Link>
              </p>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

export default Register;
