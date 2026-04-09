"use client";

import React, { useEffect, useMemo, useState } from "react";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import { AlertOctagon, CheckCircle, Search, ShieldBan, MessageSquareX } from "lucide-react";
import { addDoc, collection, getDocs, orderBy, query, serverTimestamp, updateDoc, doc } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { useAuth } from "@/context/AuthContext";

interface ReportRow {
  id: string;
  reportedUser: string;
  reporter: string;
  reason: string;
  status: "pending" | "reviewed" | "dismissed";
  date?: string;
  reportedUserId?: string;
  reporterId?: string;
}

export default function ReportsPage() {
  const [searchTerm, setSearchTerm] = useState("");
  const [reports, setReports] = useState<ReportRow[]>([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  useEffect(() => {
    const fetchReports = async () => {
      setLoading(true);
      try {
        const q = query(collection(db, "reports"), orderBy("createdAt", "desc"));
        const snap = await getDocs(q);
        const rows = snap.docs.map((d) => {
          const data = d.data() as any;
          return {
            id: d.id,
            reportedUser: data.reportedUserName || "Unknown",
            reporter: data.reporterName || "Unknown",
            reason: data.reason || "Unspecified",
            status: data.status || "pending",
            date: data.createdAt?.toDate?.()?.toISOString?.()?.slice(0, 10),
            reportedUserId: data.reportedUserId,
            reporterId: data.reporterId,
          } as ReportRow;
        });
        setReports(rows);
      } catch (error) {
        console.error("Error fetching reports:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchReports();
  }, []);

  const filteredReports = useMemo(() => {
    return reports.filter(report => 
      report.reportedUser.toLowerCase().includes(searchTerm.toLowerCase()) || 
      report.reporter.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [reports, searchTerm]);

  const writeAuditLog = async (action: string, target: string, metadata?: Record<string, any>) => {
    try {
      await addDoc(collection(db, "audit_logs"), {
        actorId: user?.uid || null,
        actorEmail: user?.email || "unknown",
        action,
        target,
        metadata: metadata || {},
        createdAt: serverTimestamp(),
      });
    } catch (error) {
      console.error("Failed to write audit log:", error);
    }
  };

  const updateReportStatus = async (reportId: string, status: "reviewed" | "dismissed") => {
    try {
      await updateDoc(doc(db, "reports", reportId), { status, updatedAt: serverTimestamp() });
      setReports((prev) => prev.map((r) => (r.id === reportId ? { ...r, status } : r)));
      await writeAuditLog("report_status_update", reportId, { status });
    } catch (error) {
      console.error("Failed to update report:", error);
      alert("Failed to update report");
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
               <h1 className="text-2xl font-bold text-gray-900 mb-1">Moderation Queue</h1>
               <p className="text-gray-500 text-sm">Review flagged users and inappropriate content reports.</p>
             </div>
          </div>

          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div className="p-4 border-b border-gray-100 flex justify-between items-center bg-yellow-50/50">
               <div className="relative w-80">
                 <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                 <input 
                   type="text" 
                   placeholder="Search tickets by username..." 
                   value={searchTerm}
                   onChange={(e) => setSearchTerm(e.target.value)}
                   className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500"
                 />
               </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm whitespace-nowrap">
                <thead className="bg-gray-50/50 text-gray-500 border-b border-gray-100 uppercase tracking-wider text-xs font-semibold">
                  <tr>
                    <th className="px-6 py-4">Report Ticket</th>
                    <th className="px-6 py-4">Reported By</th>
                    <th className="px-6 py-4">Reason</th>
                    <th className="px-6 py-4">Status</th>
                    <th className="px-6 py-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {loading ? (
                    <tr>
                       <td colSpan={5} className="px-6 py-12 text-center text-gray-500">
                          Loading reports...
                       </td>
                    </tr>
                  ) : filteredReports.length === 0 ? (
                    <tr>
                       <td colSpan={5} className="px-6 py-12 text-center text-gray-500">
                          No reports in the queue!
                       </td>
                    </tr>
                  ) : (
                    filteredReports.map((report) => (
                      <tr key={report.id} className="hover:bg-yellow-50/20 transition-colors group">
                        <td className="px-6 py-4">
                           <div className="flex flex-col">
                             <span className="font-semibold text-gray-900">{report.reportedUser}</span>
                             <span className="text-xs text-gray-500 uppercase">#{report.id} • {report.date}</span>
                           </div>
                        </td>
                        <td className="px-6 py-4 text-gray-600">
                           {report.reporter}
                        </td>
                        <td className="px-6 py-4">
                           <div className="flex items-center text-red-600 bg-red-50 px-3 py-1 rounded-full w-max text-xs font-medium border border-red-100">
                             <AlertOctagon className="w-3 h-3 mr-1.5" />
                             {report.reason}
                           </div>
                        </td>
                        <td className="px-6 py-4">
                           <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${
                             report.status === "pending" 
                               ? "bg-yellow-50 text-yellow-700 border-yellow-200" 
                               : report.status === "dismissed"
                                 ? "bg-gray-50 text-gray-600 border-gray-200"
                                 : "bg-emerald-50 text-emerald-700 border-emerald-200"
                           }`}>
                             {report.status === "pending" ? "Needs Review" : report.status === "dismissed" ? "Dismissed" : "Resolved"}
                           </span>
                        </td>
                        <td className="px-6 py-4 text-right">
                           <div className="flex items-center justify-end space-x-2">
                              <button 
                                className="p-1.5 rounded-md hover:bg-red-50 text-gray-400 hover:text-red-600 transition"
                                title="Mark Reviewed"
                                onClick={() => updateReportStatus(report.id, "reviewed")}
                              >
                                <ShieldBan className="w-4 h-4" />
                              </button>
                              <button 
                                className="p-1.5 rounded-md hover:bg-emerald-50 text-gray-400 hover:text-emerald-600 transition"
                                title="Dismiss Report"
                                onClick={() => updateReportStatus(report.id, "dismissed")}
                              >
                                <CheckCircle className="w-4 h-4" />
                              </button>
                              <button 
                                className="p-1.5 rounded-md hover:bg-gray-200 text-gray-400 hover:text-gray-900 transition"
                                title="Read Chat Context"
                              >
                                <MessageSquareX className="w-4 h-4" />
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
