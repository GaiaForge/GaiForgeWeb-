import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Register from './pages/Register';
import ProductSelector from './pages/ProductSelector';
import Dashboard from './pages/Dashboard';
import Analytics from './pages/Analytics';
import Upload from './pages/Upload';
import Devices from './pages/Devices';
import Profile from './pages/Profile';
import Admin from './pages/Admin';
import Alerts from './pages/Alerts';
import Journal from './pages/Journal';
import OrpheusDashboard from './pages/OrpheusDashboard';
import OrpheusAnalytics from './pages/OrpheusAnalytics';
import OrpheusJournal from './pages/OrpheusJournal';
import SprigRigDashboard from './pages/SprigRigDashboard';
import ForgotPassword from './pages/ForgotPassword';
import ResetPassword from './pages/ResetPassword';
import ForceChangePassword from './pages/ForceChangePassword';
import './App.css';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [user, setUser] = useState(null);

  const handleLogin = (userData) => {
    setIsAuthenticated(true);
    setUser(userData);
    localStorage.setItem('user', JSON.stringify(userData));
  };

  const updateUser = (patch) => {
    setUser(prev => {
      const updated = { ...prev, ...patch };
      localStorage.setItem('user', JSON.stringify(updated));
      return updated;
    });
  };

  // Gate authenticated routes behind login, then behind a forced password change if flagged
  const protect = (element) => {
    if (!isAuthenticated) return <Navigate to="/login" />;
    if (user?.must_change_password) return <Navigate to="/force-password-change" />;
    return element;
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
                const updated = { ...parsed, name: profile.name || parsed.name, subscription_tier: profile.subscription_tier, subscription_expires_at: profile.subscription_expires_at || null, is_admin: profile.is_admin || false, report_mode: profile.report_mode || 'beekeeper', products: profile.products || [], must_change_password: profile.must_change_password || false };
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
            isAuthenticated ? <Navigate to="/products" /> : <Login onLogin={handleLogin} />
          } />
          <Route path="/register" element={
            isAuthenticated ? <Navigate to="/products" /> : <Register onRegister={handleLogin} />
          } />
          <Route path="/forgot-password" element={<ForgotPassword />} />
          <Route path="/reset-password" element={<ResetPassword />} />
          <Route path="/force-password-change" element={
            isAuthenticated ? <ForceChangePassword user={user} onPasswordChanged={() => updateUser({ must_change_password: false })} onLogout={handleLogout} /> : <Navigate to="/login" />
          } />
          <Route path="/products" element={protect(<ProductSelector user={user} onLogout={handleLogout} />)} />
          {/* HiveGuard routes */}
          <Route path="/dashboard" element={protect(<Dashboard user={user} onLogout={handleLogout} />)} />
          <Route path="/analytics" element={protect(<Analytics user={user} onLogout={handleLogout} />)} />
          <Route path="/upload" element={protect(<Upload user={user} onLogout={handleLogout} />)} />
          <Route path="/devices" element={protect(<Devices user={user} onLogout={handleLogout} />)} />
          <Route path="/journal" element={protect(<Journal user={user} onLogout={handleLogout} />)} />
          <Route path="/alerts" element={protect(<Alerts user={user} onLogout={handleLogout} />)} />
          {/* Orpheus routes */}
          <Route path="/orpheus" element={protect(<OrpheusDashboard user={user} onLogout={handleLogout} />)} />
          <Route path="/orpheus/analytics" element={protect(<OrpheusAnalytics user={user} onLogout={handleLogout} />)} />
          <Route path="/orpheus/journal" element={protect(<OrpheusJournal user={user} onLogout={handleLogout} />)} />
          {/* SprigRig routes */}
          <Route path="/sprigrig" element={protect(<SprigRigDashboard user={user} onLogout={handleLogout} />)} />
          {/* Shared routes */}
          <Route path="/profile" element={protect(<Profile user={user} onLogout={handleLogout} />)} />
          <Route path="/admin" element={protect(<Admin user={user} onLogout={handleLogout} />)} />
          <Route path="/" element={<Navigate to="/login" />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
