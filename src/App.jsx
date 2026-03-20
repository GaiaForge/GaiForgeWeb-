import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import Analytics from './pages/Analytics';
import Upload from './pages/Upload';
import Devices from './pages/Devices';
import Profile from './pages/Profile';
import Admin from './pages/Admin';
import './App.css';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [user, setUser] = useState(null);

  const handleLogin = (userData) => {
    setIsAuthenticated(true);
    setUser(userData);
    localStorage.setItem('user', JSON.stringify(userData));
  };

  const handleLogout = () => {
    setIsAuthenticated(false);
    setUser(null);
    localStorage.removeItem('user');
  };

  // Check for existing session on load — validate token is still good
  React.useEffect(() => {
    const savedUser = localStorage.getItem('user');
    if (savedUser) {
      try {
        const parsed = JSON.parse(savedUser);
        if (parsed.token) {
          // Verify token is still valid and refresh subscription tier
          fetch(`${window.location.origin}/api/auth/me`, {
            headers: { 'Authorization': `Bearer ${parsed.token}` }
          }).then(res => {
            if (res.ok) {
              return res.json().then(profile => {
                const updated = { ...parsed, subscription_tier: profile.subscription_tier, is_admin: profile.is_admin || false };
                setUser(updated);
                setIsAuthenticated(true);
                localStorage.setItem('user', JSON.stringify(updated));
              });
            } else {
              localStorage.removeItem('user');
            }
          }).catch(() => {
            // Network error — allow offline access with cached data
            setUser(parsed);
            setIsAuthenticated(true);
          });
        }
      } catch {
        localStorage.removeItem('user');
      }
    }
  }, []);

  return (
    <Router basename="/portal">
      <div className="App">
        <Routes>
          <Route path="/login" element={
            isAuthenticated ? <Navigate to="/dashboard" /> : <Login onLogin={handleLogin} />
          } />
          <Route path="/register" element={
            isAuthenticated ? <Navigate to="/dashboard" /> : <Register onRegister={handleLogin} />
          } />
          <Route path="/dashboard" element={
            isAuthenticated ? <Dashboard user={user} onLogout={handleLogout} /> : <Navigate to="/login" />
          } />
          <Route path="/analytics" element={
            isAuthenticated ? <Analytics user={user} onLogout={handleLogout} /> : <Navigate to="/login" />
          } />
          <Route path="/upload" element={
            isAuthenticated ? <Upload user={user} onLogout={handleLogout} /> : <Navigate to="/login" />
          } />
          <Route path="/devices" element={
            isAuthenticated ? <Devices user={user} onLogout={handleLogout} /> : <Navigate to="/login" />
          } />
          <Route path="/profile" element={
            isAuthenticated ? <Profile user={user} onLogout={handleLogout} /> : <Navigate to="/login" />
          } />
          <Route path="/admin" element={
            isAuthenticated ? <Admin user={user} onLogout={handleLogout} /> : <Navigate to="/login" />
          } />
          <Route path="/" element={<Navigate to="/login" />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
