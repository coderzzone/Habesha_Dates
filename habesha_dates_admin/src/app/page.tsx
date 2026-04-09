"use client";

import React, { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import {
  Users,
  BadgeCheck,
  Crown,
  UserX,
  AlertOctagon,
  CreditCard,
  ShieldCheck,
  Settings,
  Bell,
  ToggleLeft,
  UserCog,
  ClipboardList,
  RefreshCw,
  History,
  FileText,
} from "lucide-react";
import {
  collection,
  getCountFromServer,
  getDocs,
  limit,
  orderBy,
  query,
  where,
} from "firebase/firestore";
import { db } from "@/lib/firebase";

type DashboardStats = {
  totalUsers: number;
  verifiedUsers: number;
  premiumUsers: number;
  bannedUsers: number;
  pendingReports: number;
  pendingPayments: number;
};

type QueueReport = {
  id: string;
  reportedUser: string;
  reason: string;
  createdAt?: Date | null;
};

type QueuePayment = {
  id: string;
  userId: string;
  amount: number;
  createdAt?: Date | null;
};

type AuditLog = {
  id: string;
  actorEmail: string;
  action: string;
  target: string;
  createdAt?: Date | null;
};

const emptyStats: DashboardStats = {
  totalUsers: 0,
  verifiedUsers: 0,
  premiumUsers: 0,
  bannedUsers: 0,
  pendingReports: 0,
  pendingPayments: 0,
};

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats>(emptyStats);
  const [reportQueue, setReportQueue] = useState<QueueReport[]>([]);
  const [paymentQueue, setPaymentQueue] = useState<QueuePayment[]>([]);
  const [auditLogs, setAuditLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);

  const loadDashboard = async () => {
    setLoading(true);
    try {
      const usersRef = collection(db, "users");
      const reportsRef = collection(db, "reports");
      const paymentsRef = collection(db, "payment_requests");
      const auditRef = collection(db, "audit_logs");

      const [
        totalUsersSnap,
        verifiedUsersSnap,
        premiumUsersSnap,
        bannedUsersSnap,
        pendingReportsSnap,
        pendingPaymentsSnap,
        reportsSnap,
        paymentsSnap,
        auditSnap,
      ] = await Promise.all([
        getCountFromServer(usersRef),
        getCountFromServer(query(usersRef, where("isVerified", "==", true))),
        getCountFromServer(query(usersRef, where("isPremium", "==", true))),
        getCountFromServer(query(usersRef, where("status", "==", "banned"))),
        getCountFromServer(query(reportsRef, where("status", "==", "pending"))),
        getCountFromServer(query(paymentsRef, where("status", "==", "pending"))),
        getDocs(query(reportsRef, where("status", "==", "pending"), limit(6))),
        getDocs(query(paymentsRef, where("status", "==", "pending"), limit(6))),
        getDocs(query(auditRef, orderBy("createdAt", "desc"), limit(6))),
      ]);

      setStats({
        totalUsers: totalUsersSnap.data().count,
        verifiedUsers: verifiedUsersSnap.data().count,
        premiumUsers: premiumUsersSnap.data().count,
        bannedUsers: bannedUsersSnap.data().count,
        pendingReports: pendingReportsSnap.data().count,
        pendingPayments: pendingPaymentsSnap.data().count,
      });

      const reports = reportsSnap.docs.map((docSnap) => {
        const data = docSnap.data() as any;
        return {
          id: docSnap.id,
          reportedUser: data.reportedUserName || "Unknown",
          reason: data.reason || "Unspecified",
          createdAt: data.createdAt?.toDate?.() ?? null,
        } as QueueReport;
      });

      const payments = paymentsSnap.docs.map((docSnap) => {
        const data = docSnap.data() as any;
        return {
          id: docSnap.id,
          userId: data.userId || "unknown",
          amount: Number(data.amount || 0),
          createdAt: data.timestamp?.toDate?.() ?? data.createdAt?.toDate?.() ?? null,
        } as QueuePayment;
      });

      const audits = auditSnap.docs.map((docSnap) => {
        const data = docSnap.data() as any;
        return {
          id: docSnap.id,
          actorEmail: data.actorEmail || "unknown",
          action: data.action || "unknown",
          target: data.target || "",
          createdAt: data.createdAt?.toDate?.() ?? null,
        } as AuditLog;
      });

      setReportQueue(reports);
      setPaymentQueue(payments);
      setAuditLogs(audits);
      setLastUpdated(new Date());
    } catch (error) {
      console.error("Error fetching dashboard stats:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadDashboard();
  }, []);

  const summaryCards = useMemo(
    () => [
      {
        label: "Total Users",
        value: stats.totalUsers,
        icon: Users,
        bg: "bg-indigo-50",
        text: "text-indigo-600",
      },
      {
        label: "Verified Users",
        value: stats.verifiedUsers,
        icon: BadgeCheck,
        bg: "bg-emerald-50",
        text: "text-emerald-600",
      },
      {
        label: "Premium Users",
        value: stats.premiumUsers,
        icon: Crown,
        bg: "bg-amber-50",
        text: "text-amber-600",
      },
      {
        label: "Banned Users",
        value: stats.bannedUsers,
        icon: UserX,
        bg: "bg-rose-50",
        text: "text-rose-600",
      },
      {
        label: "Pending Reports",
        value: stats.pendingReports,
        icon: AlertOctagon,
        bg: "bg-orange-50",
        text: "text-orange-600",
      },
      {
        label: "Pending Payments",
        value: stats.pendingPayments,
        icon: CreditCard,
        bg: "bg-violet-50",
        text: "text-violet-600",
      },
    ],
    [stats]
  );

  const quickActions = [
    {
      title: "User Management",
      description: "Search users, ban or restore access, assign premium.",
      href: "/users",
      icon: Users,
    },
    {
      title: "Safety Review",
      description: "Handle reports, enforce policy, and review abuse.",
      href: "/reports",
      icon: ShieldCheck,
    },
    {
      title: "Payment Requests",
      description: "Approve Telebirr proofs and activate premium.",
      href: "/payments",
      icon: CreditCard,
    },
    {
      title: "Notifications",
      description: "Push campaigns and system-wide announcements.",
      href: "/notifications",
      icon: Bell,
    },
    {
      title: "Feature Flags",
      description: "Toggle experiments and staged rollouts.",
      href: "/feature-flags",
      icon: ToggleLeft,
    },
    {
      title: "Admin Roles",
      description: "Control staff permissions and access levels.",
      href: "/admin-roles",
      icon: UserCog,
    },
    {
      title: "Audit Logs",
      description: "Track sensitive actions and admin changes.",
      href: "/audit-logs",
      icon: ClipboardList,
    },
    {
      title: "Platform Settings",
      description: "Core configuration and safety policies.",
      href: "/settings",
      icon: Settings,
    },
  ];

  const formatShort = (value?: Date | null) => {
    if (!value) return "n/a";
    return value.toLocaleDateString();
  };

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <Sidebar />
      <div className="flex-1 ml-64 flex flex-col min-h-screen">
        <Navbar />

        <main className="flex-1 p-8">
          <div className="mb-8 flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 mb-1">Operations Dashboard</h1>
              <p className="text-gray-500 text-sm">
                Control every service in one place: users, verification, safety, payments, and rollout.
              </p>
            </div>
            <div className="flex items-center gap-3">
              <div className="text-xs text-gray-500">
                Last updated: {lastUpdated ? lastUpdated.toLocaleString() : "Loading..."}
              </div>
              <button
                onClick={loadDashboard}
                className="flex items-center px-3 py-2 rounded-lg bg-white border border-gray-200 text-sm font-medium text-gray-700 hover:bg-gray-50 transition"
              >
                <RefreshCw className={`w-4 h-4 mr-2 ${loading ? "animate-spin" : ""}`} />
                Refresh
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6 mb-10">
            {summaryCards.map((card) => {
              const Icon = card.icon;
              return (
                <div
                  key={card.label}
                  className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 flex items-center gap-4"
                >
                <div
                    className={`w-12 h-12 rounded-xl ${card.bg} flex items-center justify-center`}
                  >
                    <Icon className={`w-6 h-6 ${card.text}`} />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-gray-500">{card.label}</p>
                    <h3 className="text-2xl font-bold text-gray-900">
                      {loading ? "..." : card.value.toLocaleString()}
                    </h3>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="grid grid-cols-1 xl:grid-cols-3 gap-6 mb-10">
            <div className="xl:col-span-2 bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-center justify-between mb-5">
                <div>
                  <h2 className="text-lg font-bold text-gray-900">Admin Control Center</h2>
                  <p className="text-sm text-gray-500">Direct links to every operational tool.</p>
                </div>
                <History className="w-5 h-5 text-gray-300" />
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {quickActions.map((action) => {
                  const Icon = action.icon;
                  return (
                    <Link
                      key={action.title}
                      href={action.href}
                      className="group rounded-xl border border-gray-100 p-4 hover:border-indigo-200 hover:shadow-sm transition"
                    >
                      <div className="flex items-start gap-3">
                        <div className="w-10 h-10 rounded-lg bg-indigo-50 flex items-center justify-center text-indigo-600">
                          <Icon className="w-5 h-5" />
                        </div>
                        <div>
                          <p className="text-sm font-semibold text-gray-900 group-hover:text-indigo-700">
                            {action.title}
                          </p>
                          <p className="text-xs text-gray-500 mt-1">{action.description}</p>
                        </div>
                      </div>
                    </Link>
                  );
                })}
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <h2 className="text-lg font-bold text-gray-900 mb-4">Priority Queues</h2>
              <div className="space-y-5">
                <div>
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2 text-sm font-semibold text-gray-700">
                      <AlertOctagon className="w-4 h-4 text-orange-500" />
                      Reports Pending
                    </div>
                    <span className="text-xs text-gray-500">{stats.pendingReports}</span>
                  </div>
                  <div className="space-y-2">
                    {loading ? (
                      <div className="text-xs text-gray-400">Loading report queue...</div>
                    ) : reportQueue.length === 0 ? (
                      <div className="text-xs text-gray-400">No pending reports.</div>
                    ) : (
                      reportQueue.map((report) => (
                        <div
                          key={report.id}
                          className="flex items-start justify-between gap-3 rounded-lg border border-gray-100 px-3 py-2 text-xs text-gray-600"
                        >
                          <div>
                            <p className="font-semibold text-gray-900">{report.reportedUser}</p>
                            <p className="text-gray-500">{report.reason}</p>
                          </div>
                          <span className="text-[10px] text-gray-400 mt-1">{formatShort(report.createdAt)}</span>
                        </div>
                      ))
                    )}
                  </div>
                </div>

                <div>
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2 text-sm font-semibold text-gray-700">
                      <CreditCard className="w-4 h-4 text-indigo-500" />
                      Payment Reviews
                    </div>
                    <span className="text-xs text-gray-500">{stats.pendingPayments}</span>
                  </div>
                  <div className="space-y-2">
                    {loading ? (
                      <div className="text-xs text-gray-400">Loading payment queue...</div>
                    ) : paymentQueue.length === 0 ? (
                      <div className="text-xs text-gray-400">No pending payment requests.</div>
                    ) : (
                      paymentQueue.map((payment) => (
                        <div
                          key={payment.id}
                          className="flex items-start justify-between gap-3 rounded-lg border border-gray-100 px-3 py-2 text-xs text-gray-600"
                        >
                          <div>
                            <p className="font-semibold text-gray-900">{payment.userId}</p>
                            <p className="text-gray-500">{payment.amount} ETB</p>
                          </div>
                          <span className="text-[10px] text-gray-400 mt-1">{formatShort(payment.createdAt)}</span>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
            <div className="xl:col-span-2 bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h2 className="text-lg font-bold text-gray-900">Recent Admin Activity</h2>
                  <p className="text-sm text-gray-500">Latest actions from moderators and staff.</p>
                </div>
                <Link href="/audit-logs" className="text-sm text-indigo-600 font-medium hover:text-indigo-700">
                  View all
                </Link>
              </div>
              <div className="space-y-3">
                {loading ? (
                  <div className="text-sm text-gray-400">Loading audit logs...</div>
                ) : auditLogs.length === 0 ? (
                  <div className="text-sm text-gray-400">No audit logs yet.</div>
                ) : (
                  auditLogs.map((log) => (
                    <div
                      key={log.id}
                      className="flex items-start justify-between gap-4 rounded-xl border border-gray-100 px-4 py-3"
                    >
                      <div className="flex items-start gap-3">
                        <div className="w-10 h-10 rounded-lg bg-gray-50 flex items-center justify-center text-gray-500">
                          <FileText className="w-5 h-5" />
                        </div>
                        <div>
                          <p className="text-sm font-semibold text-gray-900">{log.action}</p>
                          <p className="text-xs text-gray-500">
                            {log.actorEmail} on {log.target || "system"}
                          </p>
                        </div>
                      </div>
                      <span className="text-xs text-gray-400">{formatShort(log.createdAt)}</span>
                    </div>
                  ))
                )}
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <h2 className="text-lg font-bold text-gray-900 mb-4">Verification & Trust</h2>
              <div className="space-y-4 text-sm text-gray-600">
                <div className="flex items-start gap-3">
                  <BadgeCheck className="w-4 h-4 text-emerald-600 mt-0.5" />
                  <div>
                    <p className="font-semibold text-gray-900">Verified Profiles</p>
                    <p className="text-xs text-gray-500">
                      {loading ? "..." : `${stats.verifiedUsers} verified users`}
                    </p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <ShieldCheck className="w-4 h-4 text-indigo-600 mt-0.5" />
                  <div>
                    <p className="font-semibold text-gray-900">Safety Rules</p>
                    <p className="text-xs text-gray-500">
                      Blocked keywords, auto-flags, and ban reasons are managed in Safety.
                    </p>
                  </div>
                </div>
                <div className="flex items-start gap-3">
                  <AlertOctagon className="w-4 h-4 text-orange-600 mt-0.5" />
                  <div>
                    <p className="font-semibold text-gray-900">Queue Status</p>
                    <p className="text-xs text-gray-500">
                      {loading
                        ? "Loading..."
                        : `${stats.pendingReports} reports and ${stats.pendingPayments} payments waiting.`}
                    </p>
                  </div>
                </div>
                <Link
                  href="/safety"
                  className="mt-2 inline-flex items-center text-sm font-medium text-indigo-600 hover:text-indigo-700"
                >
                  Open Safety Console
                </Link>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
