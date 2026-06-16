import { useState, useEffect } from 'react';
import { Activity, DollarSign, Users, Wrench, CheckCircle, Clock, TrendingUp, Navigation, Truck } from 'lucide-react';
import api from '../api';

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    api.get('/admin/stats')
      .then((res) => setStats(res.data))
      .catch((err) => setError(err.response?.data?.message || 'Failed to load stats'))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '60vh' }}>
        <div style={{ color: 'var(--text-muted)', fontSize: '1.1rem' }}>Loading dashboard...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="glass-panel" style={{ padding: '2rem', color: 'var(--danger)' }}>
        <strong>Error:</strong> {error}
      </div>
    );
  }

  const cards = [
    { title: 'Total Orders', value: stats?.orders ?? 0, icon: <Activity size={22} color="#3b82f6" />, sub: 'all time' },
    { title: 'Pending', value: stats?.pending ?? 0, icon: <Clock size={22} color="#f59e0b" />, sub: 'awaiting technician' },
    { title: 'Assigned', value: stats?.assigned ?? 0, icon: <Users size={22} color="#8b5cf6" />, sub: 'technician matched' },
    { title: 'En Route', value: stats?.enRoute ?? 0, icon: <Truck size={22} color="#06b6d4" />, sub: 'on the way' },
    { title: 'In Progress', value: stats?.inProgress ?? 0, icon: <Navigation size={22} color="#f97316" />, sub: 'service active' },
    { title: 'Completed', value: stats?.completed ?? 0, icon: <CheckCircle size={22} color="#10b981" />, sub: 'all time' },
    { title: 'Customers', value: stats?.users ?? 0, icon: <Users size={22} color="#8b5cf6" />, sub: 'registered' },
    { title: 'Technicians', value: stats?.technicians ?? 0, icon: <Wrench size={22} color="#ec4899" />, sub: 'registered' },
    { title: 'Services', value: stats?.services ?? 0, icon: <TrendingUp size={22} color="#06b6d4" />, sub: 'catalog' },
  ];

  return (
    <div style={{ animation: 'fadeIn 0.4s ease' }}>
      <h1 style={{ marginBottom: '0.5rem' }}>Dashboard</h1>
      <p style={{ color: 'var(--text-muted)', marginBottom: '2rem', fontSize: '0.9rem' }}>
        Live platform overview
      </p>

      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
        gap: '1rem',
        marginBottom: '2rem'
      }}>
        {cards.map((c) => (
          <div key={c.title} className="glass-card" style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 500 }}>{c.title}</span>
              <div style={{ padding: '0.3rem', background: 'rgba(255,255,255,0.06)', borderRadius: '6px' }}>
                {c.icon}
              </div>
            </div>
            <div>
              <div style={{ fontSize: '1.8rem', fontWeight: 700 }}>{c.value.toLocaleString()}</div>
              <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>{c.sub}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Revenue Summary */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
        <div className="glass-card" style={{ padding: '1.5rem' }}>
          <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '0.5rem' }}>Total Revenue</div>
          <div style={{ fontSize: '2rem', fontWeight: 700 }}>₹{(stats?.totalRevenue || 0).toLocaleString()}</div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>from completed orders</div>
        </div>
        <div className="glass-card" style={{ padding: '1.5rem' }}>
          <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '0.5rem' }}>Platform Commission</div>
          <div style={{ fontSize: '2rem', fontWeight: 700, color: 'var(--accent-primary)' }}>₹{(stats?.totalCommissions || 0).toLocaleString()}</div>
          <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>30% platform fee</div>
        </div>
      </div>
    </div>
  );
}
