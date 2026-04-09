"use client";

import React, { useEffect, useState } from "react";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import { Check, X, ExternalLink, Calendar, User, DollarSign } from "lucide-react";
import { useAuth } from "@/context/AuthContext";

interface PaymentRequest {
  id: string;
  userId: string;
  amount: number;
  screenshotUrl: string;
  status: string;
  timestamp: number | null;
}

export default function PaymentsPage() {
  const [requests, setRequests] = useState<PaymentRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const { user: adminUser } = useAuth();

  useEffect(() => {
    fetchRequests();
  }, []);

  const fetchRequests = async () => {
    setLoading(true);
    try {
      if (!adminUser) {
        setRequests([]);
        return;
      }
      const token = await adminUser.getIdToken();
      const res = await fetch("/api/admin/payments", {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) throw new Error("Failed to fetch payment requests");
      const data = await res.json();
      setRequests(data.requests || []);
    } catch (error) {
      console.error("Error loading payment requests:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (request: PaymentRequest) => {
    if (!confirm("Approve this payment and grant Premium status?")) return;

    try {
      if (!adminUser) throw new Error("Not authenticated");
      const token = await adminUser.getIdToken();
      const res = await fetch("/api/admin/payments", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          id: request.id,
          userId: request.userId,
          action: "approve",
        }),
      });
      if (!res.ok) throw new Error("Failed to approve payment");
      alert("Payment approved successfully!");
      fetchRequests();
    } catch (error) {
      console.error("Error approving payment:", error);
      alert("Failed to approve payment.");
    }
  };

  const handleReject = async (request: PaymentRequest) => {
    const reason = prompt("Enter reason for rejection (optional):");
    if (reason === null) return;

    try {
      if (!adminUser) throw new Error("Not authenticated");
      const token = await adminUser.getIdToken();
      const res = await fetch("/api/admin/payments", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          id: request.id,
          userId: request.userId,
          action: "reject",
          rejectionReason: reason || "",
        }),
      });
      if (!res.ok) throw new Error("Failed to reject payment");
      alert("Payment rejected.");
      fetchRequests();
    } catch (error) {
      console.error("Error rejecting payment:", error);
      alert("Failed to reject payment.");
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <Sidebar />
      <div className="flex-1 ml-64 flex flex-col min-h-screen">
        <Navbar />

        <main className="flex-1 p-8">
          <div className="mb-6">
            <h1 className="text-2xl font-bold text-gray-900 mb-1">Telebirr Payment Requests</h1>
            <p className="text-gray-500 text-sm">Review manual payment proof and activate premium memberships.</p>
          </div>

          {loading ? (
            <div className="flex justify-center items-center h-64">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
            </div>
          ) : requests.length === 0 ? (
            <div className="bg-white rounded-2xl p-12 text-center border border-gray-100 shadow-sm">
              <div className="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-4">
                <Check className="w-8 h-8 text-gray-400" />
              </div>
              <h3 className="text-lg font-medium text-gray-900">All caught up!</h3>
              <p className="text-gray-500">No pending payment requests at the moment.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {requests.map((req) => (
                <div key={req.id} className="bg-white rounded-2xl overflow-hidden shadow-sm border border-gray-100 flex flex-col">
                  <div className="aspect-[3/4] bg-gray-100 relative group">
                    <img 
                      src={req.screenshotUrl} 
                      alt="Payment screenshot" 
                      className="w-full h-full object-cover"
                    />
                    <a 
                      href={req.screenshotUrl} 
                      target="_blank" 
                      rel="noopener noreferrer"
                      className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white font-medium"
                    >
                      <ExternalLink className="w-5 h-5 mr-2" />
                      View Full Size
                    </a>
                  </div>
                  
                  <div className="p-5 flex-1 flex flex-col">
                    <div className="space-y-3 mb-6">
                      <div className="flex items-center text-sm text-gray-600">
                        <User className="w-4 h-4 mr-2 text-gray-400" />
                        <span className="font-medium mr-1 text-gray-900">User ID:</span>
                        <span className="truncate">{req.userId}</span>
                      </div>
                      <div className="flex items-center text-sm text-gray-600">
                        <DollarSign className="w-4 h-4 mr-2 text-gray-400" />
                        <span className="font-medium mr-1 text-gray-900">Amount:</span>
                        {req.amount} ETB
                      </div>
                      <div className="flex items-center text-sm text-gray-600">
                        <Calendar className="w-4 h-4 mr-2 text-gray-400" />
                        <span className="font-medium mr-1 text-gray-900">Submitted:</span>
                        {req.timestamp ? new Date(req.timestamp).toLocaleString() : "Loading..."}
                      </div>
                    </div>

                    <div className="mt-auto flex gap-3">
                      <button 
                        onClick={() => handleApprove(req)}
                        className="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white font-medium py-2 rounded-xl transition flex items-center justify-center"
                      >
                        <Check className="w-4 h-4 mr-2" />
                        Approve
                      </button>
                      <button 
                        onClick={() => handleReject(req)}
                        className="flex-1 bg-white border border-red-200 text-red-600 hover:bg-red-50 font-medium py-2 rounded-xl transition flex items-center justify-center"
                      >
                        <X className="w-4 h-4 mr-2" />
                        Reject
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </main>
      </div>
    </div>
  );
}
