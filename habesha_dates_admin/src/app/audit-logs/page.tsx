"use client";

import React, { useEffect, useMemo, useState } from "react";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import { Search, ShieldAlert } from "lucide-react";
import { collection, getDocs, limit, orderBy, query } from "firebase/firestore";
import { db } from "@/lib/firebase";

interface AuditLogRow {
  id: string;
  actorEmail: string;
  action: string;
  target: string;
  date: string;
}

export default function AuditLogsPage() {
  const [logs, setLogs] = useState<AuditLogRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");

  useEffect(() => {
    const fetchLogs = async () => {
      setLoading(true);
      try {
        const q = query(collection(db, "audit_logs"), orderBy("createdAt", "desc"), limit(200));
        const snap = await getDocs(q);
        const rows = snap.docs.map((d) => {
          const data = d.data() as any;
          const date = data.createdAt?.toDate?.();
          return {
            id: d.id,
            actorEmail: data.actorEmail || "unknown",
            action: data.action || "unknown",
            target: data.target || "",
            date: date ? date.toLocaleString() : "n/a",
          } as AuditLogRow;
        });
        setLogs(rows);
      } catch (error) {
        console.error("Error fetching audit logs:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchLogs();
  }, []);

  const filteredLogs = useMemo(() => {
    const term = searchTerm.toLowerCase();
    return logs.filter((log) => 
      log.actorEmail.toLowerCase().includes(term) ||
      log.action.toLowerCase().includes(term) ||
      log.target.toLowerCase().includes(term)
    );
  }, [logs, searchTerm]);

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <Sidebar />
      <div className="flex-1 ml-64 flex flex-col min-h-screen">
        <Navbar />

        <main className="flex-1 p-8">
          <div className="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 mb-1">Audit Logs</h1>
              <p className="text-gray-500 text-sm">Track critical actions across the platform.</p>
            </div>
          </div>

          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div className="p-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
              <div className="relative w-80">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input 
                  type="text" 
                  placeholder="Search logs..." 
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                />
              </div>
              <button className="px-3 py-2 text-sm border border-gray-200 rounded-lg hover:bg-gray-50 transition">
                Export
              </button>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm whitespace-nowrap">
                <thead className="bg-gray-50/50 text-gray-500 border-b border-gray-100 uppercase tracking-wider text-xs font-semibold">
                  <tr>
                    <th className="px-6 py-4">Actor</th>
                    <th className="px-6 py-4">Action</th>
                    <th className="px-6 py-4">Target</th>
                    <th className="px-6 py-4 text-right">Date</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {loading ? (
                    <tr>
                      <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                        Loading audit logs...
                      </td>
                    </tr>
                  ) : filteredLogs.length === 0 ? (
                    <tr>
                      <td colSpan={4} className="px-6 py-12 text-center text-gray-500">
                        No logs found.
                      </td>
                    </tr>
                  ) : (
                    filteredLogs.map((log) => (
                      <tr key={log.id} className="hover:bg-gray-50/50 transition-colors">
                        <td className="px-6 py-4 font-semibold text-gray-900">{log.actorEmail}</td>
                        <td className="px-6 py-4 text-gray-600 flex items-center">
                          <ShieldAlert className="w-4 h-4 text-indigo-600 mr-2" />
                          {log.action}
                        </td>
                        <td className="px-6 py-4 text-gray-500">{log.target}</td>
                        <td className="px-6 py-4 text-right text-gray-500">{log.date}</td>
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
