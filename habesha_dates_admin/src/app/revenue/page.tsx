"use client";

import React, { useEffect, useMemo, useState } from "react";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import { DollarSign, ArrowUpRight, ArrowDownRight, CreditCard, TrendingUp, RefreshCw } from "lucide-react";
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";
import { collection, getDocs, orderBy, query, limit } from "firebase/firestore";
import { db } from "@/lib/firebase";

interface RevenueDay {
  id: string;
  date: string;
  gross: number;
  net: number;
  refunds: number;
  currency: string;
}

interface TransactionRow {
  id: string;
  userId: string;
  txRef?: string;
  amount: number;
  currency?: string;
  status?: string;
  createdAt?: Date | null;
}

export default function RevenuePage() {
  const [days, setDays] = useState<RevenueDay[]>([]);
  const [transactions, setTransactions] = useState<TransactionRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);

  const fetchRevenue = async () => {
    setLoading(true);
    try {
      const revenueQuery = query(collection(db, "revenue_daily"), orderBy("date", "desc"), limit(7));
      const revenueSnap = await getDocs(revenueQuery);
      const revenueRows = revenueSnap.docs.map((docSnap) => {
        const data = docSnap.data() as any;
        const dateVal = data.date?.toDate?.() ?? data.date;
        const dateStr = typeof dateVal === "string" ? dateVal : dateVal?.toISOString?.().slice(0, 10);
        return {
          id: docSnap.id,
          date: dateStr || "",
          gross: Number(data.gross || 0),
          net: Number(data.net || 0),
          refunds: Number(data.refunds || 0),
          currency: data.currency || "ETB",
        } as RevenueDay;
      });

      const txQuery = query(collection(db, "payment_transactions"), orderBy("createdAt", "desc"), limit(8));
      const txSnap = await getDocs(txQuery);
      const txRows = txSnap.docs.map((docSnap) => {
        const data = docSnap.data() as any;
        return {
          id: docSnap.id,
          userId: data.userId || "unknown",
          txRef: data.txRef,
          amount: Number(data.amount || 0),
          currency: data.currency || "ETB",
          status: data.status || "pending",
          createdAt: data.createdAt?.toDate?.() ?? null,
        } as TransactionRow;
      });

      setDays(revenueRows.reverse());
      setTransactions(txRows);
      setLastUpdated(new Date());
    } catch (error) {
      console.error("Error fetching revenue:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRevenue();
  }, []);

  const totals = useMemo(() => {
    const gross = days.reduce((sum, d) => sum + d.gross, 0);
    const net = days.reduce((sum, d) => sum + d.net, 0);
    const refunds = days.reduce((sum, d) => sum + d.refunds, 0);
    const avgGross = days.length ? gross / days.length : 0;
    return { gross, net, refunds, avgGross };
  }, [days]);

  const chartData = days.map((day) => ({
    name: day.date?.slice(5) || day.date,
    revenue: day.gross,
  }));

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <Sidebar />
      <div className="flex-1 ml-64 flex flex-col min-h-screen">
        <Navbar />

        <main className="flex-1 p-8">
          <div className="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 mb-1">Financial Overview</h1>
              <p className="text-gray-500 text-sm">Monitor monetization, subscriptions, and transactions.</p>
            </div>
            <div className="flex items-center gap-3">
              <div className="text-xs text-gray-500">
                Last updated: {lastUpdated ? lastUpdated.toLocaleString() : "Loading..."}
              </div>
              <button
                onClick={fetchRevenue}
                className="px-3 py-2 border border-gray-200 rounded-lg hover:bg-gray-50 transition text-sm text-gray-700"
              >
                <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex flex-col group hover:border-emerald-200 transition-colors">
              <div className="flex justify-between items-start mb-4">
                <div className="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-600 flex items-center justify-center group-hover:bg-emerald-500 group-hover:text-white transition-colors">
                  <DollarSign className="w-5 h-5" />
                </div>
                <div className="flex items-center text-emerald-600 text-sm font-semibold bg-emerald-50 px-2.5 py-1 rounded-full">
                  <ArrowUpRight className="w-3 h-3 mr-1" />
                  Weekly
                </div>
              </div>
              <p className="text-gray-500 text-sm font-medium">Total Weekly Gross</p>
              <h3 className="text-3xl font-bold text-gray-900 mt-1">
                {loading ? "..." : `${totals.gross.toLocaleString()} ETB`}
              </h3>
            </div>

            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex flex-col group hover:border-indigo-200 transition-colors">
              <div className="flex justify-between items-start mb-4">
                <div className="w-10 h-10 rounded-xl bg-indigo-100 text-indigo-600 flex items-center justify-center group-hover:bg-indigo-500 group-hover:text-white transition-colors">
                  <CreditCard className="w-5 h-5" />
                </div>
                <div className="flex items-center text-emerald-600 text-sm font-semibold bg-emerald-50 px-2.5 py-1 rounded-full">
                  <ArrowUpRight className="w-3 h-3 mr-1" />
                  Net
                </div>
              </div>
              <p className="text-gray-500 text-sm font-medium">Total Weekly Net</p>
              <h3 className="text-3xl font-bold text-gray-900 mt-1">
                {loading ? "..." : `${totals.net.toLocaleString()} ETB`}
              </h3>
            </div>

            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex flex-col group hover:border-pink-200 transition-colors">
              <div className="flex justify-between items-start mb-4">
                <div className="w-10 h-10 rounded-xl bg-pink-100 text-pink-600 flex items-center justify-center group-hover:bg-pink-500 group-hover:text-white transition-colors">
                  <TrendingUp className="w-5 h-5" />
                </div>
                <div className="flex items-center text-red-600 text-sm font-semibold bg-red-50 px-2.5 py-1 rounded-full">
                  <ArrowDownRight className="w-3 h-3 mr-1" />
                  Refunds
                </div>
              </div>
              <p className="text-gray-500 text-sm font-medium">Total Refunds</p>
              <h3 className="text-3xl font-bold text-gray-900 mt-1">
                {loading ? "..." : `${totals.refunds.toLocaleString()} ETB`}
              </h3>
            </div>

            <div className="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex flex-col">
              <div className="flex justify-between items-start mb-4">
                <div className="w-10 h-10 rounded-xl bg-amber-100 text-amber-600 flex items-center justify-center">
                  <TrendingUp className="w-5 h-5" />
                </div>
              </div>
              <p className="text-gray-500 text-sm font-medium">Avg Daily Gross</p>
              <h3 className="text-3xl font-bold text-gray-900 mt-1">
                {loading ? "..." : `${Math.round(totals.avgGross).toLocaleString()} ETB`}
              </h3>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
              <h2 className="text-lg font-bold text-gray-900 mb-6">Revenue Growth (Last 7 Days)</h2>
              <div className="h-72 w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={chartData}>
                    <defs>
                      <linearGradient id="colorRevs" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#10b981" stopOpacity={0.3} />
                        <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f3f4f6" />
                    <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: "#9ca3af", fontSize: 12 }} dy={10} />
                    <YAxis axisLine={false} tickLine={false} tick={{ fill: "#9ca3af", fontSize: 12 }} dx={-10} />
                    <Tooltip
                      contentStyle={{ borderRadius: "12px", border: "none", boxShadow: "0 4px 6px -1px rgb(0 0 0 / 0.1)" }}
                      formatter={(value: any) => [value, "Gross"]}
                    />
                    <Area type="monotone" dataKey="revenue" stroke="#10b981" strokeWidth={3} fillOpacity={1} fill="url(#colorRevs)" />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            </div>

            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden flex flex-col">
              <div className="p-6 border-b border-gray-100">
                <h2 className="text-lg font-bold text-gray-900">Recent Transactions</h2>
              </div>
              <div className="flex-1 overflow-y-auto p-2">
                {loading ? (
                  <div className="p-4 text-sm text-gray-500">Loading transactions...</div>
                ) : transactions.length === 0 ? (
                  <div className="p-4 text-sm text-gray-500">No recent transactions.</div>
                ) : (
                  transactions.map((tx) => (
                    <div key={tx.id} className="p-4 hover:bg-gray-50 rounded-xl transition flex justify-between items-center">
                      <div>
                        <p className="font-semibold text-gray-900 text-sm">{tx.txRef || tx.id}</p>
                        <p className="text-xs text-gray-500 mt-0.5">
                          {tx.userId} - {tx.createdAt ? tx.createdAt.toLocaleDateString() : "n/a"}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className={`font-bold text-sm ${tx.status === "failed" ? "text-red-500" : "text-gray-900"}`}>
                          {tx.amount.toLocaleString()} {tx.currency || "ETB"}
                        </p>
                        <p className={`text-xs mt-0.5 capitalize ${tx.status === "failed" ? "text-red-500" : "text-emerald-500"}`}>
                          {tx.status || "pending"}
                        </p>
                      </div>
                    </div>
                  ))
                )}
              </div>
              <div className="p-4 border-t border-gray-100 bg-gray-50 text-center">
                <button className="text-sm font-medium text-indigo-600 hover:text-indigo-800 transition">View All Purchases</button>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
