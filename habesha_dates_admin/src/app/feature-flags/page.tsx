"use client";

import React, { useEffect, useState } from "react";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import { ToggleLeft, ToggleRight, RefreshCw } from "lucide-react";
import { collection, getDocs, orderBy, query, updateDoc, doc } from "firebase/firestore";
import { db } from "@/lib/firebase";

interface FeatureFlagRow {
  id: string;
  key: string;
  description?: string;
  enabled: boolean;
  updatedAt?: Date | null;
}

export default function FeatureFlagsPage() {
  const [flags, setFlags] = useState<FeatureFlagRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);

  const fetchFlags = async () => {
    setLoading(true);
    try {
      const q = query(collection(db, "feature_flags"), orderBy("key", "asc"));
      const snap = await getDocs(q);
      const rows = snap.docs.map((docSnap) => {
        const data = docSnap.data() as any;
        return {
          id: docSnap.id,
          key: data.key || docSnap.id,
          description: data.description || "",
          enabled: Boolean(data.enabled),
          updatedAt: data.updatedAt?.toDate?.() ?? null,
        } as FeatureFlagRow;
      });
      setFlags(rows);
      setLastUpdated(new Date());
    } catch (error) {
      console.error("Error fetching feature flags:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFlags();
  }, []);

  const toggleFlag = async (flag: FeatureFlagRow) => {
    const next = !flag.enabled;
    setFlags((prev) => prev.map((f) => (f.id === flag.id ? { ...f, enabled: next } : f)));
    try {
      await updateDoc(doc(db, "feature_flags", flag.id), { enabled: next });
    } catch (error) {
      console.error("Failed to update flag:", error);
      setFlags((prev) => prev.map((f) => (f.id === flag.id ? { ...f, enabled: !next } : f)));
      alert("Failed to update flag.");
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
              <h1 className="text-2xl font-bold text-gray-900 mb-1">Feature Flags</h1>
              <p className="text-gray-500 text-sm">Control gradual rollouts and experiment toggles.</p>
            </div>
            <div className="flex items-center gap-3">
              <div className="text-xs text-gray-500">
                Last updated: {lastUpdated ? lastUpdated.toLocaleString() : "Loading..."}
              </div>
              <button
                onClick={fetchFlags}
                className="px-3 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 transition text-sm text-gray-700"
              >
                <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
              </button>
            </div>
          </div>

          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm whitespace-nowrap">
                <thead className="bg-gray-50/50 text-gray-500 border-b border-gray-100 uppercase tracking-wider text-xs font-semibold">
                  <tr>
                    <th className="px-6 py-4">Feature</th>
                    <th className="px-6 py-4">Key</th>
                    <th className="px-6 py-4">Description</th>
                    <th className="px-6 py-4 text-right">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {loading ? (
                    <tr>
                      <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                        Loading flags...
                      </td>
                    </tr>
                  ) : flags.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                        No flags found.
                      </td>
                    </tr>
                  ) : (
                    flags.map((flag) => (
                      <tr key={flag.id} className="hover:bg-gray-50/50 transition-colors">
                        <td className="px-6 py-4 font-semibold text-gray-900">{flag.key}</td>
                        <td className="px-6 py-4 text-gray-500">{flag.id}</td>
                        <td className="px-6 py-4 text-gray-500">{flag.description || "n/a"}</td>
                        <td className="px-6 py-4 text-right">
                          <button
                            onClick={() => toggleFlag(flag)}
                            className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${
                              flag.enabled
                                ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                                : "bg-gray-50 text-gray-600 border-gray-200"
                            }`}
                          >
                            {flag.enabled ? <ToggleRight className="w-3 h-3 mr-1" /> : <ToggleLeft className="w-3 h-3 mr-1" />}
                            {flag.enabled ? "Enabled" : "Disabled"}
                          </button>
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
