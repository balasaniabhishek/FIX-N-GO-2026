import React, { useState, useEffect } from 'react';
import api from '../api';

export default function Technicians() {
  const [technicians, setTechnicians] = useState([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(null);
  const [expandedId, setExpandedId] = useState(null);
  const [rejectReason, setRejectReason] = useState('');
  const [showRejectInput, setShowRejectInput] = useState(null);

  const fetchTechnicians = () => {
    setLoading(true);
    api.get('/admin/technicians')
      .then(res => setTechnicians(res.data.data || []))
      .catch(err => console.error(err))
      .finally(() => setLoading(false));
  };

  useEffect(() => { fetchTechnicians(); }, []);

  const handleApprove = async (id) => {
    setActionLoading(id);
    try {
      await api.patch(`/admin/technicians/${id}/approve`);
      fetchTechnicians();
      setExpandedId(null);
    } catch (err) {
      console.error(err);
    }
    setActionLoading(null);
  };

  const handleReject = async (id) => {
    if (!rejectReason.trim()) {
      alert('Please provide a rejection reason');
      return;
    }
    setActionLoading(id);
    try {
      await api.patch(`/admin/technicians/${id}/reject`, { reason: rejectReason });
      fetchTechnicians();
      setShowRejectInput(null);
      setRejectReason('');
      setExpandedId(null);
    } catch (err) {
      console.error(err);
    }
    setActionLoading(null);
  };

  const handleSuspend = async (id) => {
    setActionLoading(id);
    try {
      await api.patch(`/admin/technicians/${id}/suspend`);
      fetchTechnicians();
    } catch (err) {
      console.error(err);
    }
    setActionLoading(null);
  };

  const getVerificationBadge = (tech) => {
    const status = tech.technicianMeta?.verification?.status || 'unverified';
    const colors = { verified: 'success', pending: 'warning', rejected: 'danger', unverified: 'info' };
    return <span className={`badge badge-${colors[status] || 'info'}`}>{status}</span>;
  };

  return (
    <div>
      <h1 style={{ marginBottom: '2rem' }}>Technician Management</h1>
      <div className="glass-panel table-container">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Phone</th>
              <th>KYC Status</th>
              <th>Account</th>
              <th>Rating</th>
              <th>Jobs</th>
              <th>Wallet</th>
              <th>Joined</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan="10" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>Loading technicians...</td></tr>
            ) : technicians.length === 0 ? (
              <tr><td colSpan="10" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No technicians found.</td></tr>
            ) : (
              technicians.map(tech => (
                <React.Fragment key={tech._id}>
                  <tr>
                    <td style={{ fontWeight: 600 }}>{tech.name || 'N/A'}</td>
                    <td>{tech.email}</td>
                    <td>{tech.phone || '—'}</td>
                    <td>{getVerificationBadge(tech)}</td>
                    <td>
                      <span className={`badge badge-${tech.isApproved ? 'success' : 'warning'}`}>
                        {tech.isApproved ? 'Active' : 'Inactive'}
                      </span>
                      {tech.isOnline && <span className="badge badge-info" style={{ marginLeft: '0.25rem', fontSize: '0.65rem' }}>Online</span>}
                    </td>
                    <td>{tech.technicianMeta?.rating?.toFixed(1) || '—'}</td>
                    <td>{tech.technicianMeta?.jobsDone || 0}</td>
                    <td>₹{(tech.technicianMeta?.walletBalance || 0).toFixed(2)}</td>
                    <td>{new Date(tech.createdAt).toLocaleDateString()}</td>
                    <td style={{ display: 'flex', gap: '0.4rem', flexWrap: 'wrap' }}>
                      <button
                        className="btn btn-outline"
                        style={{ padding: '0.2rem 0.6rem', fontSize: '0.7rem' }}
                        onClick={() => setExpandedId(expandedId === tech._id ? null : tech._id)}
                      >
                        {expandedId === tech._id ? 'Hide' : 'View KYC'}
                      </button>
                    </td>
                  </tr>

                  {expandedId === tech._id && (
                    <tr style={{ backgroundColor: 'rgba(255,255,255,0.02)' }}>
                      <td colSpan="10" style={{ padding: '1.5rem' }}>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1.5rem' }}>
                          {/* KYC Documents */}
                          <div>
                            <h4 style={{ marginBottom: '0.75rem', color: 'var(--text-primary)' }}>KYC Documents</h4>
                            <div style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginBottom: '0.5rem' }}>
                              <strong>Aadhaar:</strong> {tech.technicianMeta?.documents?.aadharNumber || 'Not submitted'}
                            </div>
                            <div style={{ display: 'flex', gap: '0.75rem', marginTop: '0.5rem' }}>
                              {tech.technicianMeta?.documents?.aadharFront && (
                                <div>
                                  <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Front</div>
                                  <img src={`${api.defaults.baseURL?.replace('/api','')}${tech.technicianMeta.documents.aadharFront}`} alt="Front" style={{ width: '120px', height: '80px', objectFit: 'cover', borderRadius: '6px', border: '1px solid var(--border-color)' }} />
                                </div>
                              )}
                              {tech.technicianMeta?.documents?.aadharBack && (
                                <div>
                                  <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Back</div>
                                  <img src={`${api.defaults.baseURL?.replace('/api','')}${tech.technicianMeta.documents.aadharBack}`} alt="Back" style={{ width: '120px', height: '80px', objectFit: 'cover', borderRadius: '6px', border: '1px solid var(--border-color)' }} />
                                </div>
                              )}
                              {!tech.technicianMeta?.documents?.aadharFront && !tech.technicianMeta?.documents?.aadharBack && (
                                <div style={{ color: 'var(--text-muted)', fontSize: '0.8rem' }}>No documents uploaded</div>
                              )}
                            </div>
                          </div>

                          {/* Bank Details */}
                          <div>
                            <h4 style={{ marginBottom: '0.75rem', color: 'var(--text-primary)' }}>Bank Details</h4>
                            <div style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', display: 'grid', gap: '0.3rem' }}>
                              <div><strong>Name:</strong> {tech.technicianMeta?.bankDetails?.accountName || 'N/A'}</div>
                              <div><strong>Account:</strong> {tech.technicianMeta?.bankDetails?.accountNumber || 'N/A'}</div>
                              <div><strong>IFSC:</strong> {tech.technicianMeta?.bankDetails?.ifscCode || 'N/A'}</div>
                            </div>
                            {tech.technicianMeta?.verification?.rejectionReason && (
                              <div style={{ marginTop: '1rem', padding: '0.5rem', backgroundColor: 'rgba(239,68,68,0.1)', borderRadius: '6px', fontSize: '0.8rem', color: '#ef4444' }}>
                                <strong>Last rejection:</strong> {tech.technicianMeta.verification.rejectionReason}
                              </div>
                            )}
                          </div>

                          {/* Actions */}
                          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', justifyContent: 'center' }}>
                            {!tech.isApproved && (
                              <button
                                style={{ padding: '0.6rem 1.2rem', backgroundColor: 'var(--success)', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: 600 }}
                                onClick={() => handleApprove(tech._id)}
                                disabled={actionLoading === tech._id}
                              >
                                {actionLoading === tech._id ? '...' : 'Approve KYC'}
                              </button>
                            )}

                            {showRejectInput === tech._id ? (
                              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                <input
                                  type="text"
                                  placeholder="Enter rejection reason..."
                                  value={rejectReason}
                                  onChange={(e) => setRejectReason(e.target.value)}
                                  style={{ padding: '0.5rem', borderRadius: '6px', border: '1px solid var(--border-color)', background: 'var(--bg-dark)', color: 'var(--text-primary)', fontSize: '0.8rem' }}
                                />
                                <div style={{ display: 'flex', gap: '0.5rem' }}>
                                  <button
                                    style={{ padding: '0.4rem 0.8rem', backgroundColor: '#ef4444', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer', fontSize: '0.75rem' }}
                                    onClick={() => handleReject(tech._id)}
                                    disabled={actionLoading === tech._id}
                                  >
                                    Confirm Reject
                                  </button>
                                  <button
                                    style={{ padding: '0.4rem 0.8rem', backgroundColor: 'transparent', color: 'var(--text-muted)', border: '1px solid var(--border-color)', borderRadius: '6px', cursor: 'pointer', fontSize: '0.75rem' }}
                                    onClick={() => { setShowRejectInput(null); setRejectReason(''); }}
                                  >
                                    Cancel
                                  </button>
                                </div>
                              </div>
                            ) : (
                              <button
                                style={{ padding: '0.6rem 1.2rem', backgroundColor: '#ef4444', color: 'white', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: 600 }}
                                onClick={() => setShowRejectInput(tech._id)}
                              >
                                Reject KYC
                              </button>
                            )}

                            {tech.isApproved && (
                              <button
                                style={{ padding: '0.6rem 1.2rem', backgroundColor: 'transparent', color: 'var(--text-muted)', border: '1px solid var(--border-color)', borderRadius: '6px', cursor: 'pointer' }}
                                onClick={() => handleSuspend(tech._id)}
                                disabled={actionLoading === tech._id}
                              >
                                {actionLoading === tech._id ? '...' : 'Suspend Account'}
                              </button>
                            )}
                          </div>
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
