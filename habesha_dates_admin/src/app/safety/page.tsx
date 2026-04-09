"use client";

import React, { useEffect, useState } from "react";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import { Shield, Ban, Flag, Plus } from "lucide-react";
import { addDoc, collection, doc, getDoc, serverTimestamp, setDoc } from "firebase/firestore";
import { db } from "@/lib/firebase";
import { useAuth } from "@/context/AuthContext";

interface SafetySettings {
  blockedTerms: string[];
  banReasons: string[];
  autoFlags: {
    reportThreshold: number;
    hideBlockedTerms: boolean;
    autoBanAfterViolations: number;
  };
}

const DEFAULT_SETTINGS: SafetySettings = {
  blockedTerms: ["scam", "explicit", "harassment", "whatsapp", "telegram"],
  banReasons: ["Spam profile", "Harassment", "Impersonation", "Payment fraud"],
  autoFlags: {
    reportThreshold: 3,
    hideBlockedTerms: true,
    autoBanAfterViolations: 2,
  },
};

export default function SafetyPage() {
  const [settings, setSettings] = useState<SafetySettings>(DEFAULT_SETTINGS);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [newKeyword, setNewKeyword] = useState("");
  const [newReason, setNewReason] = useState("");
  const { user } = useAuth();

  useEffect(() => {
    const fetchSettings = async () => {
      setLoading(true);
      try {
        const ref = doc(db, "safety_settings", "default");
        const snap = await getDoc(ref);
        if (snap.exists()) {
          setSettings({ ...DEFAULT_SETTINGS, ...(snap.data() as SafetySettings) });
        }
      } catch (error) {
        console.error("Failed to load safety settings:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchSettings();
  }, []);

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

  const handleSave = async () => {
    setSaving(true);
    try {
      await setDoc(doc(db, "safety_settings", "default"), {
        ...settings,
        updatedAt: serverTimestamp(),
        updatedBy: user?.uid || null,
      }, { merge: true });
      await writeAuditLog("safety_settings_update", "safety_settings/default", settings);
    } catch (error) {
      console.error("Failed to save safety settings:", error);
      alert("Failed to save safety settings");
    } finally {
      setSaving(false);
    }
  };

  const addKeyword = () => {
    const value = newKeyword.trim();
    if (!value) return;
    setSettings((prev) => ({ ...prev, blockedTerms: [...prev.blockedTerms, value] }));
    setNewKeyword("");
  };

  const addReason = () => {
    const value = newReason.trim();
    if (!value) return;
    setSettings((prev) => ({ ...prev, banReasons: [...prev.banReasons, value] }));
    setNewReason("");
  };

  return (
    <div className="min-h-screen bg-gray-50 flex">
      <Sidebar />
      <div className="flex-1 ml-64 flex flex-col min-h-screen">
        <Navbar />

        <main className="flex-1 p-8">
          <div className="mb-6 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 mb-1">Safety & Content Controls</h1>
              <p className="text-gray-500 text-sm">Manage community safeguards and policy enforcement tools.</p>
            </div>
            <button 
              onClick={handleSave}
              disabled={saving}
              className="px-4 py-2 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition disabled:opacity-70"
            >
              {saving ? "Saving..." : "Save Safety Rules"}
            </button>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
              <h2 className="text-lg font-bold text-gray-900 mb-4">Blocked Keywords</h2>
              {loading ? (
                <p className="text-sm text-gray-500">Loading settings...</p>
              ) : (
                <>
                  <div className="flex flex-wrap gap-2">
                    {settings.blockedTerms.map((term) => (
                      <span key={term} className="px-3 py-1 rounded-full text-xs font-semibold bg-red-50 text-red-600 border border-red-100">
                        {term}
                      </span>
                    ))}
                  </div>
                  <div className="flex items-center mt-4 gap-2">
                    <input
                      value={newKeyword}
                      onChange={(e) => setNewKeyword(e.target.value)}
                      placeholder="Add keyword"
                      className="flex-1 border border-gray-200 rounded-lg px-3 py-2 text-sm"
                    />
                    <button onClick={addKeyword} className="px-3 py-2 rounded-lg bg-gray-100 text-gray-700 text-sm font-medium flex items-center">
                      <Plus className="w-4 h-4 mr-1" /> Add
                    </button>
                  </div>
                  <p className="text-xs text-gray-500 mt-3">Used to flag profiles and messages for review.</p>
                </>
              )}
            </div>

            <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
              <h2 className="text-lg font-bold text-gray-900 mb-4">Auto-Flags</h2>
              <div className="space-y-4 text-sm text-gray-600">
                <div className="flex items-start">
                  <Flag className="w-4 h-4 text-indigo-600 mr-2 mt-0.5" />
                  Flag profiles after {settings.autoFlags.reportThreshold}+ reports in 24 hours.
                </div>
                <div className="flex items-start">
                  <Shield className="w-4 h-4 text-indigo-600 mr-2 mt-0.5" />
                  Auto-hide messages containing blocked terms: {settings.autoFlags.hideBlockedTerms ? "On" : "Off"}
                </div>
                <div className="flex items-start">
                  <Ban className="w-4 h-4 text-indigo-600 mr-2 mt-0.5" />
                  Auto-ban after {settings.autoFlags.autoBanAfterViolations} verified violations.
                </div>
              </div>
            </div>
          </div>

          <div className="mt-8 bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            <h2 className="text-lg font-bold text-gray-900 mb-4">Ban Reasons</h2>
            {loading ? (
              <p className="text-sm text-gray-500">Loading settings...</p>
            ) : (
              <>
                <div className="flex flex-wrap gap-2">
                  {settings.banReasons.map((reason) => (
                    <span key={reason} className="px-3 py-1 rounded-full text-xs font-semibold bg-gray-50 text-gray-700 border border-gray-200">
                      {reason}
                    </span>
                  ))}
                </div>
                <div className="flex items-center mt-4 gap-2">
                  <input
                    value={newReason}
                    onChange={(e) => setNewReason(e.target.value)}
                    placeholder="Add ban reason"
                    className="flex-1 border border-gray-200 rounded-lg px-3 py-2 text-sm"
                  />
                  <button onClick={addReason} className="px-3 py-2 rounded-lg bg-gray-100 text-gray-700 text-sm font-medium flex items-center">
                    <Plus className="w-4 h-4 mr-1" /> Add
                  </button>
                </div>
              </>
            )}
          </div>
        </main>
      </div>
    </div>
  );
}
