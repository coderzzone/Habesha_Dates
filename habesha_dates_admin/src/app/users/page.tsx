"use client";

import React, { useEffect, useState } from "react";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import { MoreVertical, ShieldAlert, Trash2, CheckCircle, Search, Crown, BadgeCheck, Mail, Phone, User } from "lucide-react";
import { useAuth } from "@/context/AuthContext";

interface AppUser {
  id: string;
  name?: string;
  email?: string;
  phoneNumber?: string;
  status?: string;
  photoUrl?: string;
  isPremium?: boolean;
  createdAt?: any;
  authProvider?: string;
  providerIds?: string[];
}

export default function UsersPage() {
  const [users, setUsers] = useState<AppUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const { user: adminUser } = useAuth();

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      if (!adminUser) {
        setUsers([]);
        return;
      }
      const token = await adminUser.getIdToken();
      const res = await fetch("/api/admin/users", {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) throw new Error("Failed to fetch users");
      const data = await res.json();
      const usersData = (data.users || []) as AppUser[];
      setUsers(usersData);
    } catch (error) {
      console.error("Error fetching users:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleBanUser = async (userId: string, currentStatus: string | undefined) => {
    const newStatus = currentStatus === "banned" ? "active" : "banned";
    if (confirm(`Are you sure you want to ${newStatus === 'banned' ? 'BAN' : 'UNBAN'} this user?`)) {
      try {
        if (!adminUser) throw new Error("Not authenticated");
        const token = await adminUser.getIdToken();
        const res = await fetch("/api/admin/users/status", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ uid: userId, status: newStatus }),
        });
        if (!res.ok) {
          const err = await res.json().catch(() => ({}));
          throw new Error(err.error || "Failed to update user status");
        }
        fetchUsers(); // Refresh list
      } catch (error) {
        console.error("Error updating user status", error);
        alert("Failed to update user status");
      }
    }
  };

  const handleDeleteUser = async (userId: string) => {
    if (confirm("WARNING: This will permanently delete the user document from Firestore. Are you sure?")) {
      try {
        if (!adminUser) throw new Error("Not authenticated");
        const token = await adminUser.getIdToken();
        const res = await fetch("/api/admin/users/delete", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ uid: userId }),
        });
        if (!res.ok) {
          const err = await res.json().catch(() => ({}));
          throw new Error(err.error || "Failed to delete user");
        }
        fetchUsers();
      } catch (error) {
        console.error("Error deleting user", error);
        alert("Failed to delete user");
      }
    }
  };

  const handleTogglePremium = async (userId: string, current: boolean | undefined) => {
    if (!adminUser) {
      alert("You must be logged in as admin.");
      return;
    }
    const next = !current;
    if (confirm(`Are you sure you want to ${next ? "GRANT" : "REMOVE"} Premium?`)) {
      try {
        const token = await adminUser.getIdToken();
        const res = await fetch("/api/admin/premium", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ uid: userId, isPremium: next }),
        });
        if (!res.ok) {
          const err = await res.json().catch(() => ({}));
          throw new Error(err.error || "Failed to toggle premium");
        }
        fetchUsers();
      } catch (error) {
        console.error("Error toggling premium", error);
        alert("Failed to toggle premium");
      }
    }
  };

  const handleToggleVerified = async (userId: string, current: boolean | undefined) => {
    if (!adminUser) {
      alert("You must be logged in as admin.");
      return;
    }
    const next = !current;
    if (confirm(`Are you sure you want to ${next ? "VERIFY" : "UNVERIFY"} this user?`)) {
      try {
        const token = await adminUser.getIdToken();
        const res = await fetch("/api/admin/users/verify", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ uid: userId, isVerified: next }),
        });
        if (!res.ok) {
          const err = await res.json().catch(() => ({}));
          throw new Error(err.error || "Failed to toggle verification");
        }
        fetchUsers();
      } catch (error) {
        console.error("Error toggling verification", error);
        alert("Failed to update verification status");
      }
    }
  };

  const filteredUsers = users.filter(user => 
    (user.name?.toLowerCase() || "").includes(searchTerm.toLowerCase()) ||
    (user.email?.toLowerCase() || "").includes(searchTerm.toLowerCase()) ||
    (user.phoneNumber?.toLowerCase() || "").includes(searchTerm.toLowerCase())
  );

  const GoogleIcon = () => (
    <svg viewBox="0 0 48 48" className="w-3.5 h-3.5" aria-hidden="true">
      <path fill="#EA4335" d="M24 20.5v7.3h10.2c-.4 2.3-2.7 6.7-10.2 6.7-6.1 0-11-5-11-11.2s4.9-11.2 11-11.2c3.5 0 5.8 1.5 7.1 2.8l4.8-4.6C32.8 7.4 29 6 24 6 14.8 6 7.3 13.5 7.3 22.8S14.8 39.6 24 39.6c10.9 0 13.5-7.6 13.5-11.6 0-.8-.1-1.4-.2-2H24z"/>
      <path fill="#34A853" d="M9.3 14.1l6 4.4C16.8 15.4 20.1 13 24 13c3.5 0 5.8 1.5 7.1 2.8l4.8-4.6C32.8 7.4 29 6 24 6c-6.4 0-11.9 3.4-14.7 8.1z"/>
      <path fill="#FBBC05" d="M24 39.6c5 0 9.2-1.6 12.3-4.4l-5.7-4.7c-1.6 1.1-3.7 1.9-6.6 1.9-5.5 0-10.1-3.7-11.7-8.7l-6 4.6c2.8 4.7 8.2 7.7 13.7 7.7z"/>
      <path fill="#4285F4" d="M37.3 28c.1-.6.2-1.2.2-2 0-.8-.1-1.4-.2-2H24v7.3h10.2c-.5 1.7-1.7 3.6-3.6 5.1l5.7 4.7c3.3-3 5-7.4 5-13.1z"/>
    </svg>
  );

  const renderAuthIcon = (user: AppUser) => {
    const provider = user.authProvider && user.authProvider !== "unknown"
      ? user.authProvider
      : user.phoneNumber
        ? "phone"
        : user.email
          ? "password"
          : "unknown";

    if (provider === "google") return <GoogleIcon />;
    if (provider === "phone") return <Phone className="w-3.5 h-3.5" />;
    if (provider === "password") return <Mail className="w-3.5 h-3.5" />;
    return <User className="w-3.5 h-3.5" />;
  };

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <Sidebar />
      <div className="flex-1 ml-64 flex flex-col min-h-screen">
        <Navbar />
        
        <main className="flex-1 p-8">
          <div className="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
             <div>
               <h1 className="text-2xl font-bold text-gray-900 mb-1">User Management</h1>
               <p className="text-gray-500 text-sm">View, search, and moderate Habesha Dates users.</p>
             </div>
             <div>
                <button 
                  onClick={fetchUsers}
                  className="px-4 py-2 bg-white border border-gray-200 text-sm font-medium text-gray-700 rounded-lg hover:bg-gray-50 transition shadow-sm"
                >
                  Refresh Data
                </button>
             </div>
          </div>

          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div className="p-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
               <div className="relative w-72">
                 <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                 <input 
                   type="text" 
                   placeholder="Search users..." 
                   value={searchTerm}
                   onChange={(e) => setSearchTerm(e.target.value)}
                   className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                 />
               </div>
               <div className="text-sm text-gray-500 font-medium">
                 Total Users: {users.length}
               </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm whitespace-nowrap">
                <thead className="bg-gray-50/50 text-gray-500 border-b border-gray-100 uppercase tracking-wider text-xs font-semibold">
                  <tr>
                    <th className="px-6 py-4">User</th>
                    <th className="px-6 py-4">Status</th>
                    <th className="px-6 py-4">Joined</th>
                    <th className="px-6 py-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {loading ? (
                    <tr>
                       <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                          Loading users from Firebase...
                       </td>
                    </tr>
                  ) : filteredUsers.length === 0 ? (
                    <tr>
                       <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                          No users found.
                       </td>
                    </tr>
                  ) : (
                    filteredUsers.map((user) => (
                      <tr key={user.id} className="hover:bg-gray-50/50 transition-colors group">
                        <td className="px-6 py-4">
                          <div className="flex items-center">
                            <div className="w-10 h-10 rounded-full bg-indigo-100 flex items-center justify-center overflow-hidden mr-3 flex-shrink-0 border border-gray-200">
                              {user.photoUrl ? (
                                <img src={user.photoUrl} alt="avatar" className="w-full h-full object-cover" />
                              ) : (
                                <span className="text-indigo-600 font-bold text-sm">
                                  {user.name?.charAt(0) || user.email?.charAt(0) || 'U'}
                                </span>
                              )}
                            </div>
                            <div>
                              <p className="font-semibold text-gray-900">{user.name || "Unknown User"}</p>
                              <div className="flex items-center gap-1 text-xs text-gray-500">
                                <span className="text-gray-400" title={`Auth: ${user.authProvider || "unknown"}`}>
                                  {renderAuthIcon(user)}
                                </span>
                                <span>
                                  {user.email || user.phoneNumber || "No contact"}
                                </span>
                              </div>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                           <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${
                             user.status === 'banned' 
                               ? 'bg-red-50 text-red-700 border-red-200' 
                               : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                           }`}>
                             {user.status === 'banned' ? 'Banned' : 'Active'}
                           </span>
                           {user.isPremium && (
                             <span className="ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200">
                               Premium
                             </span>
                           )}
                           {user.isVerified && (
                             <span className="ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-sky-50 text-sky-700 border border-sky-200">
                               Verified
                             </span>
                           )}
                        </td>
                        <td className="px-6 py-4 text-gray-500">
                           {/* Assuming Firestore Timestamp or simple string */}
                           {user.createdAt ? new Date(user.createdAt?.seconds * 1000 || user.createdAt).toLocaleDateString() : 'N/A'}
                        </td>
                        <td className="px-6 py-4 text-right">
                           <div className="flex items-center justify-end space-x-2 opacity-0 group-hover:opacity-100 transition-opacity">
                              <button 
                                onClick={() => handleTogglePremium(user.id, user.isPremium)}
                                className={`p-1.5 rounded-md transition ${
                                  user.isPremium
                                    ? 'text-amber-700 hover:bg-amber-50'
                                    : 'text-gray-500 hover:bg-gray-200'
                                }`}
                                title={user.isPremium ? "Remove premium" : "Grant premium"}
                              >
                                <Crown className="w-4 h-4" />
                              </button>
                              <button
                                onClick={() => handleToggleVerified(user.id, user.isVerified)}
                                className={`p-1.5 rounded-md transition ${
                                  user.isVerified
                                    ? 'text-sky-700 hover:bg-sky-50'
                                    : 'text-gray-500 hover:bg-gray-200'
                                }`}
                                title={user.isVerified ? "Unverify user" : "Verify user"}
                              >
                                <BadgeCheck className="w-4 h-4" />
                              </button>
                              <button 
                                onClick={() => handleBanUser(user.id, user.status)}
                                className={`p-1.5 rounded-md hover:bg-gray-200 text-gray-600 transition ${user.status === 'banned' ? 'text-emerald-600 hover:bg-emerald-50 hover:text-emerald-700' : 'hover:text-red-600'}`}
                                title={user.status === 'banned' ? "Unban user" : "Ban user"}
                              >
                                {user.status === 'banned' ? <CheckCircle className="w-4 h-4" /> : <ShieldAlert className="w-4 h-4" />}
                              </button>
                              <button 
                                onClick={() => handleDeleteUser(user.id)}
                                className="p-1.5 rounded-md text-gray-400 hover:text-red-600 hover:bg-red-50 transition"
                                title="Delete Document"
                              >
                                <Trash2 className="w-4 h-4" />
                              </button>
                           </div>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

          </div>
        </main>
      </div>
    </div>
  );
}
