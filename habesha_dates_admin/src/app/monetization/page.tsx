"use client";

import React, { useEffect, useMemo, useState } from "react";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import { Crown, Sparkles, CreditCard, RefreshCw } from "lucide-react";
import { collection, getDocs, orderBy, query, limit } from "firebase/firestore";
import { db } from "@/lib/firebase";

interface SubscriptionRow {
  id: string;
  userId: string;
  plan?: string;
  status?: string;
  provider?: string;
  startedAt?: Date | null;
  expiresAt?: Date | null;
}

interface MonetizationEventRow {
  id: string;
  userId: string;
  type?: string;
  amount?: number;
  currency?: string;
  createdAt?: Date | null;
}

export default function MonetizationPage() {
  const [subscriptions, setSubscriptions] = useState<SubscriptionRow[]>([]);
  const [events, setEvents] = useState<MonetizationEventRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);

  const fetchMonetization = async () => {
    setLoading(true);
    try {
      const subsQuery = query(collection(db, "subscriptions"), orderBy("startedAt", "desc"), limit(50));
      const subsSnap = await getDocs(subsQuery);
      const subs = subsSnap.docs.map((docSnap) => {
        const data = docSnap.data() as any;
        return {
          id: docSnap.id,
          userId: data.userId || "unknown",
          plan: data.plan,
          status: data.status,
          provider: data.provider,
          startedAt: data.startedAt?.toDate?.() ?? null,
          expiresAt: data.expiresAt?.toDate?.() ?? null,
        } as SubscriptionRow;
      });

      const eventsQuery = query(collection(db, "monetization_events"), orderBy("createdAt", "desc"), limit(10));
      const eventsSnap = await getDocs(eventsQuery);
      const ev = eventsSnap.docs.map((docSnap) => {
        const data = docSnap.data() as any;
        return {
          id: docSnap.id,
          userId: data.userId || "unknown",
          type: data.type,
          amount: Number(data.amount || 0),
          currency: data.currency || "ETB",
          createdAt: data.createdAt?.toDate?.() ?? null,
        } as MonetizationEventRow;
      });

      setSubscriptions(subs);
      setEvents(ev);
      setLastUpdated(new Date());
    } catch (error) {
      console.error("Error fetching monetization data:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMonetization();
  }, []);

  const stats = useMemo(() => {
    const active = subscriptions.filter((s) => s.status === "active").length;
    const canceled = subscriptions.filter((s) => s.status === "canceled").length;
    const expired = subscriptions.filter((s) => s.status === "expired").length;
    return { active, canceled, expired };
  }, [subscriptions]);

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <Sidebar />
      <div className="flex-1 ml-64 flex flex-col min-h-screen">
        <Navbar />

        <main className="flex-1 p-8">
          <div className="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 mb-1">Monetization</h1>
              <p className="text-gray-500 text-sm">Track subscriptions and upgrade activity.</p>
            </div>
            <div className="flex items-center gap-3">
              <div className="text-xs text-gray-500">
                Last updated: {lastUpdated ? lastUpdated.toLocaleString() : "Loading..."}
              </div>
              <button
                onClick={fetchMonetization}
                className="px-3 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 transition text-sm text-gray-700"
              >
                <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
            {[
              { label: "Active Subscriptions", value: stats.active, icon: Crown, bg: "bg-indigo-50", text: "text-indigo-600" },
              { label: "Canceled", value: stats.canceled, icon: Sparkles, bg: "bg-amber-50", text: "text-amber-600" },
              { label: "Expired", value: stats.expired, icon: CreditCard, bg: "bg-rose-50", text: "text-rose-600" },
            ].map((card) => {
              const Icon = card.icon;
              return (
                <div key={card.label} className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                  <div className="flex items-center justify-between mb-4">
                    <div className={`w-10 h-10 rounded-xl ${card.bg} ${card.text} flex items-center justify-center`}>
                      <Icon className="w-5 h-5" />
                    </div>
                  </div>
                  <p className="text-gray-500 text-sm font-medium">{card.label}</p>
                  <h3 className="text-2xl font-bold text-gray-900 mt-1">
                    {loading ? "..." : card.value.toLocaleString()}
                  </h3>
                </div>
              );
            })}
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
              <h2 className="text-lg font-bold text-gray-900 mb-4">Recent Subscriptions</h2>
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm whitespace-nowrap">
                  <thead className="bg-gray-50/50 text-gray-500 border-b border-gray-100 uppercase tracking-wider text-xs font-semibold">
                    <tr>
                      <th className="px-6 py-4">User</th>
                      <th className="px-6 py-4">Plan</th>
                      <th className="px-6 py-4">Status</th>
                      <th className="px-6 py-4">Provider</th>
                      <th className="px-6 py-4 text-right">Started</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-50">
                    {loading ? (
                      <tr>
                        <td colSpan={5} className="px-6 py-12 text-center text-gray-500">
                          Loading subscriptions...
                        </td>
                      </tr>
                    ) : subscriptions.length === 0 ? (
                      <tr>
                        <td colSpan={5} className="px-6 py-12 text-center text-gray-500">
                          No subscriptions found.
                        </td>
                      </tr>
                    ) : (
                      subscriptions.map((sub) => (
                        <tr key={sub.id} className="hover:bg-gray-50/50 transition-colors">
                          <td className="px-6 py-4 font-semibold text-gray-900">{sub.userId}</td>
                          <td className="px-6 py-4 capitalize">{sub.plan || "n/a"}</td>
                          <td className="px-6 py-4">
                            <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${
                              sub.status === "active"
                                ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                                : sub.status === "canceled"
                                  ? "bg-amber-50 text-amber-700 border-amber-200"
                                  : "bg-gray-50 text-gray-600 border-gray-200"
                            }`}>
                              {sub.status || "unknown"}
                            </span>
                          </td>
                          <td className="px-6 py-4">{sub.provider || "n/a"}</td>
                          <td className="px-6 py-4 text-right text-gray-500">
                            {sub.startedAt ? sub.startedAt.toLocaleDateString() : "n/a"}
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
              <h2 className="text-lg font-bold text-gray-900 mb-4">Recent Events</h2>
              <div className="space-y-4">
                {loading ? (
                  <div className="text-sm text-gray-500">Loading events...</div>
                ) : events.length === 0 ? (
                  <div className="text-sm text-gray-500">No monetization events yet.</div>
                ) : (
                  events.map((event) => (
                    <div key={event.id} className="flex items-center justify-between border border-gray-100 rounded-xl p-3">
                      <div>
                        <p className="text-sm font-semibold text-gray-900">{event.type || "event"}</p>
                        <p className="text-xs text-gray-500">{event.userId}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-sm font-semibold text-gray-900">
                          {event.amount?.toLocaleString()} {event.currency || "ETB"}
                        </p>
                        <p className="text-xs text-gray-500">
                          {event.createdAt ? event.createdAt.toLocaleDateString() : "n/a"}
                        </p>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
