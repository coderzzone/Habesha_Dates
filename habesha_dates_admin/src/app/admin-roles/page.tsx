"use client";

import React, { useEffect, useState } from "react";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import { ShieldCheck, UserPlus, KeyRound, RefreshCw } from "lucide-react";
import {
  addDoc,
  collection,
  getDocs,
  orderBy,
  query,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase";

interface AdminRoleRow {
  id: string;
  userId?: string;
  email?: string;
  role?: string;
  status?: string;
  createdAt?: Date | null;
}

export default function AdminRolesPage() {
  const [admins, setAdmins] = useState<AdminRoleRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const [inviteForm, setInviteForm] = useState({
    email: "",
    role: "moderator",
    userId: "",
  });
  const [inviting, setInviting] = useState(false);

  const fetchAdmins = async () => {
    setLoading(true);
    try {
      const q = query(collection(db, "admin_roles"), orderBy("createdAt", "desc"));
      const snap = await getDocs(q);
      const rows = snap.docs.map((docSnap) => {
        const data = docSnap.data() as any;
        return {
          id: docSnap.id,
          userId: data.userId,
          email: data.email,
          role: data.role,
          status: data.status,
          createdAt: data.createdAt?.toDate?.() ?? null,
        } as AdminRoleRow;
      });
      setAdmins(rows);
      setLastUpdated(new Date());
    } catch (error) {
      console.error("Error fetching admin roles:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAdmins();
  }, []);

  const handleInvite = async () => {
    if (!inviteForm.email.trim()) {
      alert("Please enter an email.");
      return;
    }
    setInviting(true);
    try {
      await addDoc(collection(db, "admin_roles"), {
        email: inviteForm.email.trim(),
        role: inviteForm.role,
        userId: inviteForm.userId.trim() || null,
        status: "invited",
        createdAt: serverTimestamp(),
      });
      setInviteForm({ email: "", role: "moderator", userId: "" });
      await fetchAdmins();
    } catch (error) {
      console.error("Failed to invite admin:", error);
      alert("Failed to invite admin.");
    } finally {
      setInviting(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <Sidebar />
      <div className="flex-1 ml-64 flex flex-col min-h-screen">
        <Navbar />

        <main className="flex-1 p-8">
          <div className="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 mb-1">Admin Roles</h1>
              <p className="text-gray-500 text-sm">Manage staff access and permissions.</p>
            </div>
            <div className="flex items-center gap-3">
              <div className="text-xs text-gray-500">
                Last updated: {lastUpdated ? lastUpdated.toLocaleString() : "Loading..."}
              </div>
              <button
                onClick={fetchAdmins}
                className="px-3 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 transition text-sm text-gray-700"
              >
                <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
              <div className="p-4 border-b border-gray-100">
                <h2 className="text-lg font-bold text-gray-900">Admins</h2>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm whitespace-nowrap">
                  <thead className="bg-gray-50/50 text-gray-500 border-b border-gray-100 uppercase tracking-wider text-xs font-semibold">
                    <tr>
                      <th className="px-6 py-4">Admin</th>
                      <th className="px-6 py-4">Role</th>
                      <th className="px-6 py-4">Status</th>
                      <th className="px-6 py-4 text-right">Created</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-50">
                    {loading ? (
                      <tr>
                        <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                          Loading admin roles...
                        </td>
                      </tr>
                    ) : admins.length === 0 ? (
                      <tr>
                        <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                          No admins found.
                        </td>
                      </tr>
                    ) : (
                      admins.map((admin) => (
                        <tr key={admin.id} className="hover:bg-gray-50/50 transition-colors">
                          <td className="px-6 py-4">
                            <div className="font-semibold text-gray-900">
                              {admin.email || admin.userId || "unknown"}
                            </div>
                            <div className="text-xs text-gray-500">{admin.userId || "n/a"}</div>
                          </td>
                          <td className="px-6 py-4 capitalize">{admin.role || "unknown"}</td>
                          <td className="px-6 py-4">
                            <span
                              className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${
                                admin.status === "active"
                                  ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                                  : admin.status === "invited"
                                    ? "bg-indigo-50 text-indigo-700 border-indigo-200"
                                    : "bg-gray-50 text-gray-600 border-gray-200"
                              }`}
                            >
                              {admin.status || "unknown"}
                            </span>
                          </td>
                          <td className="px-6 py-4 text-right text-gray-500">
                            {admin.createdAt ? admin.createdAt.toLocaleDateString() : "n/a"}
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="space-y-6">
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                <h2 className="text-lg font-bold text-gray-900 mb-4">Invite Admin</h2>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Email</label>
                    <input
                      value={inviteForm.email}
                      onChange={(e) => setInviteForm({ ...inviteForm, email: e.target.value })}
                      className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm"
                      placeholder="admin@habesha.com"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Role</label>
                    <select
                      value={inviteForm.role}
                      onChange={(e) => setInviteForm({ ...inviteForm, role: e.target.value })}
                      className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm"
                    >
                      <option value="super_admin">Super Admin</option>
                      <option value="moderator">Moderator</option>
                      <option value="support">Support</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">User ID (optional)</label>
                    <input
                      value={inviteForm.userId}
                      onChange={(e) => setInviteForm({ ...inviteForm, userId: e.target.value })}
                      className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm"
                      placeholder="Firebase UID"
                    />
                  </div>
                  <button
                    onClick={handleInvite}
                    disabled={inviting}
                    className="w-full px-4 py-2 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition flex items-center justify-center disabled:opacity-70"
                  >
                    <UserPlus className="w-4 h-4 mr-2" />
                    {inviting ? "Inviting..." : "Invite Admin"}
                  </button>
                </div>
              </div>

              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                <h2 className="text-lg font-bold text-gray-900 mb-4">Default Permissions</h2>
                <div className="space-y-4 text-sm text-gray-600">
                  <div className="flex items-start">
                    <ShieldCheck className="w-4 h-4 text-indigo-600 mr-2 mt-0.5" />
                    Super Admin: full access to all data and settings.
                  </div>
                  <div className="flex items-start">
                    <KeyRound className="w-4 h-4 text-indigo-600 mr-2 mt-0.5" />
                    Moderator: reports, safety actions, limited user actions.
                  </div>
                  <div className="flex items-start">
                    <KeyRound className="w-4 h-4 text-indigo-600 mr-2 mt-0.5" />
                    Support: view-only on users and matches.
                  </div>
                </div>
                <button className="mt-6 w-full text-sm font-medium text-gray-700 border border-gray-200 rounded-lg py-2 hover:bg-gray-50 transition">
                  Edit Permission Matrix
                </button>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
