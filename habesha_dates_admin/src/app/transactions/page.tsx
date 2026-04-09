"use client";

import React, { useEffect, useMemo, useState } from "react";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import { CheckCircle, XCircle, Clock, Search, RefreshCw } from "lucide-react";
import { collection, getDocs, orderBy, query, limit } from "firebase/firestore";
import { db } from "@/lib/firebase";

interface TransactionRow {
  id: string;
  userId: string;
  txRef?: string;
  sku?: string;
  amount: number;
  currency?: string;
  status?: string;
  createdAt?: Date | null;
}

export default function TransactionsPage() {
  const [transactions, setTransactions] = useState<TransactionRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);

  const fetchTransactions = async () => {
    setLoading(true);
    try {
      const q = query(collection(db, "payment_transactions"), orderBy("createdAt", "desc"), limit(200));
      const snap = await getDocs(q);
      const rows = snap.docs.map((docSnap) => {
        const data = docSnap.data() as any;
        return {
          id: docSnap.id,
          userId: data.userId || "unknown",
          txRef: data.txRef,
          sku: data.sku,
          amount: Number(data.amount || 0),
          currency: data.currency || "ETB",
          status: data.status || "pending",
          createdAt: data.createdAt?.toDate?.() ?? null,
        } as TransactionRow;
      });
      setTransactions(rows);
      setLastUpdated(new Date());
    } catch (error) {
      console.error("Error fetching transactions:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTransactions();
  }, []);

  const filteredTransactions = useMemo(() => {
    const term = searchTerm.toLowerCase();
    return transactions.filter((tx) =>
      (tx.txRef || "").toLowerCase().includes(term) ||
      tx.userId.toLowerCase().includes(term) ||
      (tx.sku || "").toLowerCase().includes(term)
    );
  }, [transactions, searchTerm]);

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <Sidebar />
      <div className="flex-1 ml-64 flex flex-col min-h-screen">
        <Navbar />

        <main className="flex-1 p-8">
          <div className="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 mb-1">Transactions</h1>
              <p className="text-gray-500 text-sm">Review payment activity and reconciliation status.</p>
            </div>
            <div className="flex items-center gap-3">
              <div className="text-xs text-gray-500">
                Last updated: {lastUpdated ? lastUpdated.toLocaleString() : "Loading..."}
              </div>
              <button
                onClick={fetchTransactions}
                className="px-3 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 transition text-sm text-gray-700"
              >
                <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
              </button>
            </div>
          </div>

          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            <div className="p-4 border-b border-gray-100 flex flex-col md:flex-row md:justify-between md:items-center gap-3 bg-gray-50/50">
              <div className="relative w-80">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search by txRef or user..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                />
              </div>
              <div className="text-sm text-gray-500">Total: {transactions.length}</div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm whitespace-nowrap">
                <thead className="bg-gray-50/50 text-gray-500 border-b border-gray-100 uppercase tracking-wider text-xs font-semibold">
                  <tr>
                    <th className="px-6 py-4">Transaction</th>
                    <th className="px-6 py-4">User</th>
                    <th className="px-6 py-4">SKU</th>
                    <th className="px-6 py-4">Amount</th>
                    <th className="px-6 py-4">Status</th>
                    <th className="px-6 py-4 text-right">Date</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {loading ? (
                    <tr>
                      <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                        Loading transactions...
                      </td>
                    </tr>
                  ) : filteredTransactions.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                        No transactions found.
                      </td>
                    </tr>
                  ) : (
                    filteredTransactions.map((tx) => (
                      <tr key={tx.id} className="hover:bg-gray-50/50 transition-colors">
                        <td className="px-6 py-4 font-semibold text-gray-900">{tx.txRef || tx.id}</td>
                        <td className="px-6 py-4 text-gray-600">{tx.userId}</td>
                        <td className="px-6 py-4">{tx.sku || "n/a"}</td>
                        <td className="px-6 py-4 font-medium">
                          {tx.amount.toLocaleString()} {tx.currency || "ETB"}
                        </td>
                        <td className="px-6 py-4">
                          <span
                            className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium border ${
                              tx.status === "success"
                                ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                                : tx.status === "pending"
                                  ? "bg-yellow-50 text-yellow-700 border-yellow-200"
                                  : "bg-red-50 text-red-700 border-red-200"
                            }`}
                          >
                            {tx.status === "success" && <CheckCircle className="w-3 h-3 mr-1" />}
                            {tx.status === "pending" && <Clock className="w-3 h-3 mr-1" />}
                            {tx.status === "failed" && <XCircle className="w-3 h-3 mr-1" />}
                            {tx.status}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-right text-gray-500">
                          {tx.createdAt ? tx.createdAt.toLocaleDateString() : "n/a"}
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
