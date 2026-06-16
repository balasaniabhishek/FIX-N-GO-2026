import React, { useState, useEffect } from 'react';
import { Activity, MapPin, CreditCard, RefreshCw } from 'lucide-react';
import api from '../api';

export default function Monitoring() {
  const [activeTab, setActiveTab] = useState('requests');
  const [activeRequests, setActiveRequests] = useState([]);
  const [techLocations, setTechLocations] = useState([]);
  const [payments, setPayments] = useState({ summary: {}, data: [] });
  const [loading, setLoading] = useState(true);

  const fetchData = async () => {
    setLoading(true);
    try {
      if (activeTab === 'requests') {
        const res = await api.get('/admin/monitoring/active-requests');
        setActiveRequests(res.data.data || []);
      } else if (activeTab === 'locations') {
        const res = await api.get('/admin/monitoring/technician-locations');
        setTechLocations(res.data.data || []);
      } else if (activeTab === 'payments') {
        const res = await api.get('/admin/monitoring/payments');
        setPayments(res.data);
      }
    } catch (err) {
      console.error(err);
    }
    setLoading(false);
  };

  useEffect(() => { fetchData(); }, [activeTab]);

  const statusColor = (status) => {
    const colors = {
      pending: '#f59e0b',
      assigned: '#3b82f6',
      en_route: '#8b5cf6',
      in_progress: '#06b6d4',
      completed: '#10b981',
      cancelled: '#ef4444',
    };
    return colors[status] || '#6b7280';
  };

  const tabs = [
    { id: 'requests', label: 'Active Requests', icon: <Activity size={16} /> },
    { id: 'locations', label: 'Technician Locations', icon: <MapPin size={16} /> },
    { id: 'payments', label: 'Payments & Commissions', icon: <CreditCard size={16} /> },
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h1>Live Monitoring</h1>
        <button className="btn btn-outline" onClick={fetchData} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <RefreshCw size={16} /> Refresh
        </button>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1.5rem' }}>
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            style={{
              padding: '0.6rem 1.2rem',
              borderRadius: '8px',
              border: activeTab === tab.id ? '1px solid var(--accent-primary)' : '1px solid var(--border-color)',
              backgroundColor: activeTab === tab.id ? 'rgba(59,130,246,0.1)' : 'transparent',
              color: activeTab === tab.id ? 'var(--accent-primary)' : 'var(--text-secondary)',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              fontSize: '0.85rem',
              fontWeight: 500,
            }}
          >
            {tab.icon} {tab.label}
          </button>
        ))}
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '3rem', color: 'var(--text-muted)' }}>Loading...</div>
      ) : (
        <>
          {/* Active Requests Tab */}
          {activeTab === 'requests' && (
            <div className="glass-panel table-container">
              <div style={{ marginBottom: '1rem', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                {activeRequests.length} active request(s)
              </div>
              <table>
                <thead>
                  <tr>
                    <th>Status</th>
                    <th>Device</th>
                    <th>Customer</th>
                    <th>Technician</th>
                    <th>Location</th>
                    <th>Created</th>
                  </tr>
                </thead>
                <tbody>
                  {activeRequests.length === 0 ? (
                    <tr><td colSpan="6" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No active requests</td></tr>
                  ) : (
                    activeRequests.map(req => (
                      <tr key={req._id}>
                        <td>
                          <span style={{
                            padding: '0.2rem 0.6rem',
                            borderRadius: '12px',
                            fontSize: '0.75rem',
                            fontWeight: 600,
                            backgroundColor: `${statusColor(req.status)}22`,
                            color: statusColor(req.status),
                          }}>
                            {req.status.replace('_', ' ')}
                          </span>
                        </td>
                        <td>{req.brand} {req.model}</td>
                        <td>{req.customerName}<br/><span style={{fontSize: '0.75rem', color: 'var(--text-muted)'}}>{req.customerPhone}</span></td>
                        <td>{req.technicianName || <span style={{color: 'var(--text-muted)'}}>Searching...</span>}</td>
                        <td style={{fontSize: '0.8rem'}}>{req.serviceAddress || 'N/A'}</td>
                        <td style={{fontSize: '0.8rem'}}>{new Date(req.createdAt).toLocaleString()}</td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          )}

          {/* Technician Locations Tab */}
          {activeTab === 'locations' && (
            <div className="glass-panel">
              <div style={{ marginBottom: '1rem', color: 'var(--text-muted)', fontSize: '0.85rem' }}>
                {techLocations.filter(t => t.isOnline).length} online / {techLocations.length} total technicians
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '1rem' }}>
                {techLocations.map(tech => (
                  <div key={tech._id} className="glass-card" style={{ padding: '1rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                      <strong>{tech.name}</strong>
                      <span style={{
                        width: '8px', height: '8px', borderRadius: '50%',
                        backgroundColor: tech.isOnline ? '#10b981' : '#6b7280',
                      }}></span>
                    </div>
                    <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>
                      <div>Phone: {tech.phone || 'N/A'}</div>
                      <div>Rating: {tech.rating?.toFixed(1) || 'N/A'} | Jobs: {tech.jobsDone || 0}</div>
                      <div>Location: {tech.lat && tech.lng ? `${tech.lat.toFixed(4)}, ${tech.lng.toFixed(4)}` : 'Unknown'}</div>
                      {tech.lastUpdate && <div>Last update: {new Date(tech.lastUpdate).toLocaleString()}</div>}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Payments Tab */}
          {activeTab === 'payments' && (
            <div>
              {/* Summary cards */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem', marginBottom: '1.5rem' }}>
                <div className="glass-card" style={{ padding: '1rem' }}>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Total Revenue</div>
                  <div style={{ fontSize: '1.5rem', fontWeight: 700 }}>₹{(payments.summary?.totalRevenue || 0).toLocaleString()}</div>
                </div>
                <div className="glass-card" style={{ padding: '1rem' }}>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Tech Earnings</div>
                  <div style={{ fontSize: '1.5rem', fontWeight: 700 }}>₹{(payments.summary?.totalTechEarnings || 0).toLocaleString()}</div>
                </div>
                <div className="glass-card" style={{ padding: '1rem' }}>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Platform Commission</div>
                  <div style={{ fontSize: '1.5rem', fontWeight: 700, color: 'var(--accent-primary)' }}>₹{(payments.summary?.platformCommission || 0).toLocaleString()}</div>
                </div>
                <div className="glass-card" style={{ padding: '1rem' }}>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Completed Orders</div>
                  <div style={{ fontSize: '1.5rem', fontWeight: 700 }}>{payments.summary?.completedCount || 0}</div>
                </div>
              </div>

              {/* Payments table */}
              <div className="glass-panel table-container">
                <table>
                  <thead>
                    <tr>
                      <th>Customer</th>
                      <th>Technician</th>
                      <th>Total</th>
                      <th>Tech Earning</th>
                      <th>Platform Fee</th>
                      <th>Method</th>
                      <th>Status</th>
                      <th>Date</th>
                    </tr>
                  </thead>
                  <tbody>
                    {(payments.data || []).length === 0 ? (
                      <tr><td colSpan="8" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No completed payments yet</td></tr>
                    ) : (
                      (payments.data || []).map(p => (
                        <tr key={p._id}>
                          <td>{p.customerName}</td>
                          <td>{p.technicianName}</td>
                          <td>₹{p.total}</td>
                          <td>₹{p.technicianEarning}</td>
                          <td>₹{p.platformFee}</td>
                          <td>{p.paymentMethod || 'cash'}</td>
                          <td><span className={`badge badge-${p.paymentStatus === 'collected' ? 'success' : 'warning'}`}>{p.paymentStatus}</span></td>
                          <td style={{fontSize: '0.8rem'}}>{p.completedAt ? new Date(p.completedAt).toLocaleDateString() : '—'}</td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
