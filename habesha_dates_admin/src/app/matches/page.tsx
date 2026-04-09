"use client";

import React, { useEffect, useMemo, useState } from "react";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import { Search, Calendar, RefreshCw, MessageSquare } from "lucide-react";
import { useAuth } from "@/context/AuthContext";

interface MatchRow {
  id: string;
  userAId: string;
  userBId: string;
  userAName: string;
  userBName: string;
  matchedAt?: Date | null;
  lastMessage?: string;
}

export default function MatchesPage() {
  const [searchTerm, setSearchTerm] = useState("");
  const [loading, setLoading] = useState(true);
  const [matches, setMatches] = useState<MatchRow[]>([]);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const { user: adminUser } = useAuth();

  const fetchMatches = async () => {
    setLoading(true);
    try {
      if (!adminUser) {
        setMatches([]);
        return;
      }
      const token = await adminUser.getIdToken();
      const res = await fetch("/api/admin/matches", {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) throw new Error("Failed to fetch matches");
      const data = await res.json();
      setMatches(data.matches || []);
      setLastUpdated(new Date());
    } catch (error) {
      console.error("Error fetching matches:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMatches();
  }, []);

  const filteredMatches = useMemo(() => {
    const term = searchTerm.toLowerCase();
    return matches.filter(
      (match) =>
        match.userAName.toLowerCase().includes(term) ||
        match.userBName.toLowerCase().includes(term) ||
        match.userAId.toLowerCase().includes(term) ||
        match.userBId.toLowerCase().includes(term)
    );
  }, [matches, searchTerm]);

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <Sidebar />
      <div className="flex-1 ml-64 flex flex-col min-h-screen">
        <Navbar />
        
        <main className="flex-1 p-8">
          <div className="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 mb-1">Matches Overview</h1>
              <p className="text-gray-500 text-sm">
                Track real matches created by mutual likes (chat rooms).
              </p>
            </div>
            <div className="flex items-center gap-3 text-xs text-gray-500">
              <span>
                Last updated: {lastUpdated ? lastUpdated.toLocaleString() : "Loading..."}
              </span>
              <button
                onClick={fetchMatches}
                className="flex items-center px-3 py-2 rounded-lg bg-white border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 transition"
              >
                <RefreshCw className={`w-4 h-4 mr-2 ${loading ? "animate-spin" : ""}`} />
                Refresh
              </button>
            </div>
          </div>

          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div className="p-4 border-b border-gray-100 flex flex-col md:flex-row md:items-center md:justify-between gap-3 bg-gray-50/50">
               <div className="relative w-80">
                 <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                 <input 
                   type="text" 
                   placeholder="Search by user name or UID..." 
                   value={searchTerm}
                   onChange={(e) => setSearchTerm(e.target.value)}
                   className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                 />
               </div>
               <div className="text-sm text-gray-500">
                 Total Matches: {matches.length}
               </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm whitespace-nowrap">
                <thead className="bg-gray-50/50 text-gray-500 border-b border-gray-100 uppercase tracking-wider text-xs font-semibold">
                  <tr>
                    <th className="px-6 py-4">Match Pair</th>
                    <th className="px-6 py-4">Date Matched</th>
                    <th className="px-6 py-4">Status</th>
                    <th className="px-6 py-4 text-center">Compatibility</th>
                    <th className="px-6 py-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {loading ? (
                    <tr>
                      <td colSpan={5} className="px-6 py-12 text-center text-gray-500">
                        Loading matches...
                      </td>
                    </tr>
                  ) : filteredMatches.length === 0 ? (
                    <tr>
                       <td colSpan={5} className="px-6 py-12 text-center text-gray-500">
                          No matches found.
                       </td>
                    </tr>
                  ) : (
                    filteredMatches.map((match) => (
                      <tr key={match.id} className="hover:bg-gray-50/50 transition-colors group">
                        <td className="px-6 py-4 flex items-center">
                          <div className="flex -space-x-3 mr-4">
                             <div className="w-8 h-8 rounded-full bg-indigo-100 border-2 border-white flex items-center justify-center text-xs font-bold text-indigo-600 uppercase z-10">
                               {match.userAName.charAt(0)}
                             </div>
                             <div className="w-8 h-8 rounded-full bg-pink-100 border-2 border-white flex items-center justify-center text-xs font-bold text-pink-600 uppercase">
                               {match.userBName.charAt(0)}
                             </div>
                          </div>
                          <div>
                            <p className="font-semibold text-gray-900">
                              {match.userAName} <span className="text-gray-400 font-normal mx-1">&</span> {match.userBName}
                            </p>
                            <p className="text-xs text-gray-400">
                              {match.userAId} - {match.userBId}
                            </p>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-gray-500 flex items-center">
                           <Calendar className="w-4 h-4 mr-2 opacity-50" />
                           {match.matchedAt
                             ? new Date(
                                 match.matchedAt?.seconds
                                   ? match.matchedAt.seconds * 1000
                                   : match.matchedAt
                               ).toLocaleDateString()
                             : "n/a"}
                        </td>
                        <td className="px-6 py-4">
                           <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${
                             match.lastMessage
                               ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                               : 'bg-gray-50 text-gray-600 border-gray-200' 
                           }`}>
                             {match.lastMessage ? "Messaging" : "Created"}
                           </span>
                        </td>
                        <td className="px-6 py-4 text-center text-xs text-gray-500">
                          {match.lastMessage ? match.lastMessage.slice(0, 42) : "No messages yet"}
                        </td>
                        <td className="px-6 py-4 text-right">
                           <button className="inline-flex items-center text-sm font-medium text-indigo-600 hover:text-indigo-800 transition-colors">
                             <MessageSquare className="w-4 h-4 mr-2" />
                             View Chat
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
