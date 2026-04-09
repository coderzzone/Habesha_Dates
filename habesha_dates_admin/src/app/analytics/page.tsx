"use client";

import React, { useEffect, useMemo, useState } from "react";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import { TrendingUp, Users, Activity, MessageSquare } from "lucide-react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { useAuth } from "@/context/AuthContext";

interface AnalyticsDay {
  id: string;
  date: string;
  newUsers: number;
  activeUsers: number;
  matchesCreated: number;
  messagesSent: number;
}

export default function AnalyticsPage() {
  const [days, setDays] = useState<AnalyticsDay[]>([]);
  const [loading, setLoading] = useState(true);
  const { user: adminUser } = useAuth();

  useEffect(() => {
    let isMounted = true;
    const fetchAnalytics = async () => {
      setLoading(true);
      try {
        if (!adminUser) {
          setDays([]);
          return;
        }
        const token = await adminUser.getIdToken();
        const res = await fetch("/api/admin/analytics", {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (!res.ok) throw new Error("Failed to fetch analytics");
        const data = await res.json();
        if (isMounted) setDays(data.days || []);
      } catch (error) {
        console.error("Error fetching analytics:", error);
      } finally {
        if (isMounted) setLoading(false);
      }
    };
    fetchAnalytics();
    const interval = setInterval(fetchAnalytics, 30000);
    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, [adminUser]);

  const latest = days[days.length - 1];

  const kpiData = useMemo(
    () => [
      { label: "New Users", value: latest?.newUsers ?? 0, icon: Users },
      { label: "Active Users", value: latest?.activeUsers ?? 0, icon: Activity },
      { label: "Matches", value: latest?.matchesCreated ?? 0, icon: TrendingUp },
      { label: "Messages", value: latest?.messagesSent ?? 0, icon: MessageSquare },
    ],
    [latest]
  );

  const chartData = days.map((day) => ({
    name: day.date?.slice(5) || day.date,
    users: day.activeUsers,
  }));

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <Sidebar />
      <div className="flex-1 ml-64 flex flex-col min-h-screen">
        <Navbar />

        <main className="flex-1 p-8">
          <div className="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 mb-1">Analytics & KPIs</h1>
              <p className="text-gray-500 text-sm">Track growth, engagement, and platform health.</p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            {kpiData.map((kpi) => {
              const Icon = kpi.icon;
              return (
                <div key={kpi.label} className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
                  <div className="flex items-center justify-between mb-4">
                    <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
                      <Icon className="w-5 h-5" />
                    </div>
                  </div>
                  <p className="text-gray-500 text-sm font-medium">{kpi.label}</p>
                  <h3 className="text-2xl font-bold text-gray-900 mt-1">
                    {loading ? "..." : kpi.value.toLocaleString()}
                  </h3>
                </div>
              );
            })}
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
              <h2 className="text-lg font-bold text-gray-900 mb-6">Daily Active Users (Last 14 Days)</h2>
              <div className="h-72 w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={chartData}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" />
                    <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: "#9ca3af", fontSize: 12 }} />
                    <YAxis axisLine={false} tickLine={false} tick={{ fill: "#9ca3af", fontSize: 12 }} />
                    <Tooltip
                      contentStyle={{ borderRadius: "12px", border: "none", boxShadow: "0 4px 6px -1px rgb(0 0 0 / 0.1)" }}
                      formatter={(value: any) => [value, "DAU"]}
                    />
                    <Line type="monotone" dataKey="users" stroke="#6366f1" strokeWidth={3} dot={false} />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </div>

            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
              <h2 className="text-lg font-bold text-gray-900 mb-4">Funnel Snapshot</h2>
              <div className="space-y-4">
                {[
                  { label: "New Users", value: latest?.newUsers ?? 0, pct: 100 },
                  { label: "Active Users", value: latest?.activeUsers ?? 0, pct: 70 },
                  { label: "Matches Created", value: latest?.matchesCreated ?? 0, pct: 45 },
                  { label: "Messages Sent", value: latest?.messagesSent ?? 0, pct: 30 },
                ].map((row) => (
                  <div key={row.label}>
                    <div className="flex justify-between text-sm text-gray-700 mb-1">
                      <span>{row.label}</span>
                      <span className="font-medium">{loading ? "..." : row.value.toLocaleString()}</span>
                    </div>
                    <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                      <div className="h-full bg-indigo-500" style={{ width: `${row.pct}%` }} />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
