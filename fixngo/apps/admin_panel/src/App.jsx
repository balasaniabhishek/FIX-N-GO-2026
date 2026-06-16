import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import Technicians from './pages/Technicians';
import Withdrawals from './pages/Withdrawals';
import './index.css';
import api from './api';

function Orders() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState(null);

  useEffect(() => {
    api.get('/admin/orders')
      .then(res => {
        const data = res.data;
        if (Array.isArray(data)) {
          setOrders(data);
        } else {
          setOrders(data.orders || data.data || []);
        }
      })
      .catch(err => console.error(err))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <h1 style={{ marginBottom: '2rem' }}>Orders Management</h1>
      <div className="glass-panel table-container">
        <table>
          <thead>
            <tr>
              <th>Order ID</th>
              <th>Status</th>
              <th>Service</th>
              <th>Date</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan="5" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>Loading orders...</td></tr>
            ) : orders.length === 0 ? (
              <tr><td colSpan="5" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No orders found.</td></tr>
            ) : (
              orders.map(order => (
                <React.Fragment key={order._id || Math.random()}>
                  <tr>
                    <td style={{ fontFamily: 'monospace' }}>{order._id?.toString().substring(0,8) || 'N/A'}...</td>
                    <td>
                      <span className={`badge badge-${order.status === 'completed' ? 'success' : order.status === 'pending' ? 'warning' : 'info'}`}>
                        {order.status}
                      </span>
                    </td>
                    <td>{order.serviceType || 'Repair'}</td>
                    <td>{new Date(order.createdAt).toLocaleDateString()}</td>
                    <td>
                      <button className="btn btn-outline" style={{ padding: '0.25rem 0.5rem', fontSize: '0.75rem' }} onClick={() => setExpanded(expanded === order._id ? null : order._id)}>
                        {expanded === order._id ? 'Hide' : 'Details'}
                      </button>
                    </td>
                  </tr>
                  {expanded === order._id && (
                    <tr style={{ backgroundColor: 'rgba(255,255,255,0.02)' }}>
                      <td colSpan="5" style={{ padding: '1rem' }}>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', color: 'var(--text-secondary)' }}>
                          <div><strong>Location:</strong> {order.location?.address || 'N/A'}</div>
                          <div><strong>Est. Price:</strong> ${order.estimatedPrice || '0'}</div>
                          <div><strong>Technician:</strong> {order.technician_id || 'Unassigned'}</div>
                          <div><strong>Description:</strong> {order.description || 'None'}</div>
                        </div>
                      </td>
                    </tr>
                  )}
                </React.Fragment>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function Users() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/admin/users')
      .then(res => {
        const data = res.data;
        if (Array.isArray(data)) {
          setUsers(data);
        } else {
          setUsers(data.users || data.data || []);
        }
      })
      .catch(err => console.error(err))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <h1 style={{ marginBottom: '2rem' }}>Users & Technicians</h1>
      <div className="glass-panel table-container">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Role</th>
              <th>Email</th>
              <th>Joined</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan="4" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>Loading users...</td></tr>
            ) : users.length === 0 ? (
              <tr><td colSpan="4" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No users found.</td></tr>
            ) : (
              users.map(user => (
                <tr key={user._id}>
                  <td>{user.name || 'N/A'}</td>
                  <td>
                    <span className={`badge badge-${user.role === 'admin' ? 'danger' : user.role === 'technician' ? 'info' : 'success'}`}>
                      {user.role}
                    </span>
                  </td>
                  <td>{user.email}</td>
                  <td>{new Date(user.createdAt).toLocaleDateString()}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(!!localStorage.getItem('adminToken'));

  if (!isAuthenticated) {
    return <Login setAuth={setIsAuthenticated} />;
  }

  return (
    <Router>
      <div className="app-container">
        <Sidebar />
        <main className="main-content">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/orders" element={<Orders />} />
            <Route path="/users" element={<Users />} />
            <Route path="/technicians" element={<Technicians />} />
            <Route path="/withdrawals" element={<Withdrawals />} />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;
