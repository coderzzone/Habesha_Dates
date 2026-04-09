"use client";

import React, { useEffect, useMemo, useState } from "react";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import { Send, Bell, Users, Target, RefreshCw } from "lucide-react";
import {
  addDoc,
  collection,
  getDocs,
  getCountFromServer,
  orderBy,
  query,
  serverTimestamp,
  where,
  limit,
} from "firebase/firestore";
import { db } from "@/lib/firebase";

interface CampaignRow {
  id: string;
  title: string;
  audience: string;
  status: string;
  createdAt?: Date | null;
  scheduledAt?: Date | null;
}

export default function NotificationsPage() {
  const [campaigns, setCampaigns] = useState<CampaignRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const [audienceStats, setAudienceStats] = useState({ total: 0, premium: 0, newUsers: 0 });

  const [form, setForm] = useState({
    title: "",
    channel: "Push Notification",
    message: "",
    sendDate: "",
    audience: "All Users",
  });

  const fetchCampaigns = async () => {
    setLoading(true);
    try {
      const campaignsQuery = query(collection(db, "notifications"), orderBy("createdAt", "desc"), limit(50));
      const snap = await getDocs(campaignsQuery);
      const rows = snap.docs.map((docSnap) => {
        const data = docSnap.data() as any;
        return {
          id: docSnap.id,
          title: data.title || "Untitled",
          audience: data.audience || "All Users",
          status: data.status || "draft",
          createdAt: data.createdAt?.toDate?.() ?? null,
          scheduledAt: data.scheduledAt?.toDate?.() ?? null,
        } as CampaignRow;
      });

      const [totalUsersSnap, premiumUsersSnap, analyticsSnap] = await Promise.all([
        getCountFromServer(collection(db, "users")),
        getCountFromServer(query(collection(db, "users"), where("isPremium", "==", true))),
        getDocs(query(collection(db, "analytics_daily"), orderBy("date", "desc"), limit(1))),
      ]);

      const latestAnalytics = analyticsSnap.docs[0]?.data() as any;
      const newUsers = Number(latestAnalytics?.newUsers || 0);

      setCampaigns(rows);
      setAudienceStats({
        total: totalUsersSnap.data().count,
        premium: premiumUsersSnap.data().count,
        newUsers,
      });
      setLastUpdated(new Date());
    } catch (error) {
      console.error("Error fetching notifications:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCampaigns();
  }, []);

  const handleLaunch = async () => {
    if (!form.title || !form.message) {
      alert("Please enter a title and message.");
      return;
    }
    setSending(true);
    try {
      const scheduledAt = form.sendDate ? new Date(form.sendDate) : null;
      const status = scheduledAt ? "scheduled" : "draft";
      await addDoc(collection(db, "notifications"), {
        title: form.title,
        body: form.message,
        channel: form.channel,
        audience: form.audience,
        status,
        scheduledAt: scheduledAt ? scheduledAt : null,
        createdAt: serverTimestamp(),
      });
      setForm({
        title: "",
        channel: "Push Notification",
        message: "",
        sendDate: "",
        audience: "All Users",
      });
      await fetchCampaigns();
    } catch (error) {
      console.error("Failed to launch campaign:", error);
      alert("Failed to create campaign.");
    } finally {
      setSending(false);
    }
  };

  const audienceCards = useMemo(
    () => [
      { label: "Total Users", value: audienceStats.total, icon: Users },
      { label: "Premium Users", value: audienceStats.premium, icon: Target },
      { label: "New Users (Today)", value: audienceStats.newUsers, icon: Bell },
    ],
    [audienceStats]
  );

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <Sidebar />
      <div className="flex-1 ml-64 flex flex-col min-h-screen">
        <Navbar />

        <main className="flex-1 p-8">
          <div className="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 mb-1">Notifications</h1>
              <p className="text-gray-500 text-sm">Create and manage push + in-app messaging campaigns.</p>
            </div>
            <div className="flex items-center gap-3">
              <div className="text-xs text-gray-500">
                Last updated: {lastUpdated ? lastUpdated.toLocaleString() : "Loading..."}
              </div>
              <button
                onClick={fetchCampaigns}
                className="px-3 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 transition text-sm text-gray-700"
              >
                <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
              </button>
              <button
                onClick={handleLaunch}
                disabled={sending}
                className="px-4 py-2 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition flex items-center disabled:opacity-70"
              >
                <Send className="w-4 h-4 mr-2" />
                {sending ? "Saving..." : "Launch Campaign"}
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
              <h2 className="text-lg font-bold text-gray-900 mb-4">New Campaign</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Campaign Title</label>
                  <input
                    className="w-full border border-gray-200 rounded-lg px-4 py-2 text-sm"
                    value={form.title}
                    onChange={(e) => setForm({ ...form, title: e.target.value })}
                    placeholder="Spring Promo"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Delivery Channel</label>
                  <select
                    className="w-full border border-gray-200 rounded-lg px-4 py-2 text-sm"
                    value={form.channel}
                    onChange={(e) => setForm({ ...form, channel: e.target.value })}
                  >
                    <option>Push Notification</option>
                    <option>In-App Message</option>
                    <option>Email</option>
                  </select>
                </div>
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-2">Message</label>
                  <textarea
                    className="w-full border border-gray-200 rounded-lg px-4 py-2 text-sm"
                    rows={4}
                    value={form.message}
                    onChange={(e) => setForm({ ...form, message: e.target.value })}
                    placeholder="You have 3 new likes waiting!"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Send Date</label>
                  <input
                    type="date"
                    className="w-full border border-gray-200 rounded-lg px-4 py-2 text-sm"
                    value={form.sendDate}
                    onChange={(e) => setForm({ ...form, sendDate: e.target.value })}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Audience Segment</label>
                  <select
                    className="w-full border border-gray-200 rounded-lg px-4 py-2 text-sm"
                    value={form.audience}
                    onChange={(e) => setForm({ ...form, audience: e.target.value })}
                  >
                    <option>All Users</option>
                    <option>Premium Users</option>
                    <option>Dormant 7 Days</option>
                    <option>New Users (7d)</option>
                  </select>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
              <h2 className="text-lg font-bold text-gray-900 mb-4">Audience Overview</h2>
              <div className="space-y-4">
                {audienceCards.map((stat) => {
                  const Icon = stat.icon;
                  return (
                    <div key={stat.label} className="flex items-center justify-between border border-gray-100 rounded-xl p-3">
                      <div className="flex items-center">
                        <Icon className="w-4 h-4 text-indigo-600 mr-2" />
                        <span className="text-sm text-gray-600">{stat.label}</span>
                      </div>
                      <span className="text-sm font-semibold text-gray-900">
                        {loading ? "..." : stat.value.toLocaleString()}
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          <div className="mt-8 bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div className="p-4 border-b border-gray-100">
              <h2 className="text-lg font-bold text-gray-900">Campaign History</h2>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm whitespace-nowrap">
                <thead className="bg-gray-50/50 text-gray-500 border-b border-gray-100 uppercase tracking-wider text-xs font-semibold">
                  <tr>
                    <th className="px-6 py-4">Campaign</th>
                    <th className="px-6 py-4">Audience</th>
                    <th className="px-6 py-4">Status</th>
                    <th className="px-6 py-4 text-right">Date</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {loading ? (
                    <tr>
                      <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                        Loading campaigns...
                      </td>
                    </tr>
                  ) : campaigns.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                        No campaigns yet.
                      </td>
                    </tr>
                  ) : (
                    campaigns.map((camp) => (
                      <tr key={camp.id} className="hover:bg-gray-50/50 transition-colors">
                        <td className="px-6 py-4 font-semibold text-gray-900">{camp.title}</td>
                        <td className="px-6 py-4 text-gray-600">{camp.audience}</td>
                        <td className="px-6 py-4">
                          <span
                            className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${
                              camp.status === "sent"
                                ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                                : camp.status === "scheduled"
                                  ? "bg-indigo-50 text-indigo-700 border-indigo-200"
                                  : "bg-gray-50 text-gray-600 border-gray-200"
                            }`}
                          >
                            {camp.status}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-right text-gray-500">
                          {camp.scheduledAt
                            ? camp.scheduledAt.toLocaleDateString()
                            : camp.createdAt
                              ? camp.createdAt.toLocaleDateString()
                              : "n/a"}
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
