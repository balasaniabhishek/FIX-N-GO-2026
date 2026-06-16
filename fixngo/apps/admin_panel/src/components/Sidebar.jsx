import { NavLink } from 'react-router-dom';
import { LayoutDashboard, ListOrdered, Users, Wrench, LogOut, UserCog, Wallet, Radio } from 'lucide-react';

export default function Sidebar() {
  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    window.location.href = '/';
  };

  return (
    <div className="sidebar">
      <div style={{ padding: '2rem', borderBottom: '1px solid var(--border-light)', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
        <Wrench color="var(--accent-primary)" size={28} />
        <h2 style={{ fontSize: '1.25rem', margin: 0, fontWeight: 700, letterSpacing: '0.5px' }}>Fix-N-Go</h2>
      </div>
      <nav style={{ padding: '1rem 0', display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
        <NavLink to="/" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`} end>
          <LayoutDashboard size={20} />
          Dashboard
        </NavLink>
        <NavLink to="/orders" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
          <ListOrdered size={20} />
          Orders
        </NavLink>
        <NavLink to="/users" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
          <Users size={20} />
          Users
        </NavLink>
        <NavLink to="/technicians" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
          <UserCog size={20} />
          Technicians
        </NavLink>
        <NavLink to="/withdrawals" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
          <Wallet size={20} />
          Withdrawals
        </NavLink>
        <NavLink to="/monitoring" className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}>
          <Radio size={20} />
          Live Monitoring
        </NavLink>
      </nav>
      <div style={{ marginTop: 'auto', padding: '1.5rem', borderTop: '1px solid var(--border-light)' }}>
        <button onClick={handleLogout} className="nav-item" style={{ background: 'none', border: 'none', cursor: 'pointer', width: '100%', textAlign: 'left', color: 'var(--danger)', padding: '0.5rem 0' }}>
          <LogOut size={20} />
          Logout
        </button>
        <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginTop: '1rem' }}>
          © 2026 Fix-N-Go Admin
        </div>
      </div>
    </div>
  );
}
