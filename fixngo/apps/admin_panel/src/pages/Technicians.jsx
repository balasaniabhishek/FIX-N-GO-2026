import React, { useState, useEffect } from 'react';
import api from '../api';

export default function Technicians() {
  const [technicians, setTechnicians] = useState([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(null);
  const [expandedKycId, setExpandedKycId] = useState(null);

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
      setExpandedKycId(null);
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
      setExpandedKycId(null);
    } catch (err) {
      console.error(err);
    }
    setActionLoading(null);
  };

  const getImageUrl = (path) => {
    if (!path) return null;
    const baseUrl = api.defaults.baseURL.replace('/api', '');
    return `${baseUrl}${path}`;
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
              <th>Status</th>
              <th>Rating</th>
              <th>Jobs Done</th>
              <th>Wallet</th>
              <th>Joined</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan="9" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>Loading technicians...</td></tr>
            ) : technicians.length === 0 ? (
              <tr><td colSpan="9" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>No technicians found.</td></tr>
            ) : (
              technicians.map(tech => (
                <React.Fragment key={tech._id}>
                  <tr>
                    <td style={{ fontWeight: 600 }}>{tech.name || 'N/A'}</td>
                    <td>{tech.email}</td>
                    <td>{tech.phone || '—'}</td>
                    <td>
                      <span className={`badge badge-${tech.isApproved !== false ? 'success' : 'warning'}`}>
                        {tech.isApproved !== false ? 'Approved' : 'Pending'}
                      </span>
                      {tech.isOnline && (
                        <span className="badge badge-info" style={{ marginLeft: '0.25rem', fontSize: '0.65rem' }}>Online</span>
                      )}
                    </td>
                    <td>{tech.technicianMeta?.rating?.toFixed(1) || '—'}</td>
                    <td>{tech.technicianMeta?.jobsDone || 0}</td>
                    <td>₹{(tech.technicianMeta?.walletBalance || 0).toFixed(2)}</td>
                    <td>{new Date(tech.createdAt).toLocaleDateString()}</td>
                    <td style={{ display: 'flex', gap: '0.5rem' }}>
                      <button
                        className="btn btn-outline"
                        style={{ padding: '0.25rem 0.75rem', fontSize: '0.75rem' }}
                        onClick={() => setExpandedKycId(expandedKycId === tech._id ? null : tech._id)}
                      >
                        {expandedKycId === tech._id ? 'Hide KYC' : 'View KYC'}
                      </button>
                    </td>
                  </tr>
                  
                  {expandedKycId === tech._id && (
                    <tr style={{ backgroundColor: 'rgba(255,255,255,0.02)' }}>
                      <td colSpan="9" style={{ padding: '1.5rem' }}>
                        <div style={{ display: 'flex', gap: '2rem', flexWrap: 'wrap' }}>
                          
                          {/* Documents Section */}
                          <div style={{ flex: '1', minWidth: '300px' }}>
                            <h3 style={{ marginBottom: '1rem', color: 'var(--text-primary)' }}>KYC Documents</h3>
                            <div style={{ marginBottom: '0.5rem', color: 'var(--text-secondary)' }}>
                              <strong>Aadhaar Number:</strong> {tech.technicianMeta?.documents?.aadharNumber || 'Not submitted'}
                            </div>
                            <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
                              {tech.technicianMeta?.documents?.aadharFront ? (
                                <div>
                                  <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '0.25rem' }}>Aadhaar Front</div>
                                  <img 
                                    src={getImageUrl(tech.technicianMeta.documents.aadharFront)} 
                                    alt="Aadhaar Front" 
                                    style={{ width: '150px', height: '100px', objectFit: 'cover', borderRadius: '8px', border: '1px solid var(--border-color)' }}
                                  />
                                </div>
                              ) : (
                                <div style={{ width: '150px', height: '100px', backgroundColor: 'var(--bg-dark)', display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: '8px', border: '1px dashed var(--border-color)', color: 'var(--text-muted)' }}>No Front Img</div>
                              )}
                              
                              {tech.technicianMeta?.documents?.aadharBack ? (
                                <div>
                                  <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '0.25rem' }}>Aadhaar Back</div>
                                  <img 
                                    src={getImageUrl(tech.technicianMeta.documents.aadharBack)} 
                                    alt="Aadhaar Back" 
                                    style={{ width: '150px', height: '100px', objectFit: 'cover', borderRadius: '8px', border: '1px solid var(--border-color)' }}
                                  />
                                </div>
                              ) : (
                                <div style={{ width: '150px', height: '100px', backgroundColor: 'var(--bg-dark)', display: 'flex', alignItems: 'center', justifyContent: 'center', borderRadius: '8px', border: '1px dashed var(--border-color)', color: 'var(--text-muted)' }}>No Back Img</div>
                              )}
                            </div>
                          </div>

                          {/* Bank Details Section */}
                          <div style={{ flex: '1', minWidth: '250px' }}>
                            <h3 style={{ marginBottom: '1rem', color: 'var(--text-primary)' }}>Bank Details</h3>
                            <div style={{ display: 'grid', gridTemplateColumns: '120px 1fr', gap: '0.5rem', color: 'var(--text-secondary)' }}>
                              <strong>Account Name:</strong>
                              <span>{tech.technicianMeta?.bankDetails?.accountName || 'N/A'}</span>
                              <strong>Account No:</strong>
                              <span>{tech.technicianMeta?.bankDetails?.accountNumber || 'N/A'}</span>
                              <strong>IFSC Code:</strong>
                              <span>{tech.technicianMeta?.bankDetails?.ifscCode || 'N/A'}</span>
                            </div>
                          </div>

                          {/* Approval Actions */}
                          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', justifyContent: 'center', paddingLeft: '1rem', borderLeft: '1px solid var(--border-color)' }}>
                            {tech.isApproved === false ? (
                              <button
                                className="btn"
                                style={{ backgroundColor: 'var(--success)', color: 'white', border: 'none', padding: '0.75rem 1.5rem', width: '120px' }}
                                onClick={() => handleApprove(tech._id)}
                                disabled={actionLoading === tech._id}
                              >
                                {actionLoading === tech._id ? '...' : 'Approve'}
                              </button>
                            ) : (
                              <button
                                className="btn"
                                style={{ backgroundColor: 'var(--danger)', color: 'white', border: 'none', padding: '0.75rem 1.5rem', width: '120px' }}
                                onClick={() => handleSuspend(tech._id)}
                                disabled={actionLoading === tech._id}
                              >
                                {actionLoading === tech._id ? '...' : 'Suspend'}
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
