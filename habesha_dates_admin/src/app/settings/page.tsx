"use client";

import React, { useEffect, useState } from "react";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";
import { Save, MapPin, Smartphone } from "lucide-react";
import { doc, getDoc, setDoc, serverTimestamp } from "firebase/firestore";
import { db } from "@/lib/firebase";

interface PlatformSettings {
  maxDailySwipes: string;
  defaultSearchRadius: string;
  matchingAlgorithm: string;
  requirePhotoVerification: boolean;
  maintenanceMode: boolean;
}

const DEFAULT_SETTINGS: PlatformSettings = {
  maxDailySwipes: "50",
  defaultSearchRadius: "25",
  matchingAlgorithm: "balanced",
  requirePhotoVerification: true,
  maintenanceMode: false,
};

export default function SettingsPage() {
  const [settings, setSettings] = useState<PlatformSettings>(DEFAULT_SETTINGS);
  const [saving, setSaving] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchSettings = async () => {
      setLoading(true);
      try {
        const ref = doc(db, "platform_settings", "default");
        const snap = await getDoc(ref);
        if (snap.exists()) {
          setSettings({ ...DEFAULT_SETTINGS, ...(snap.data() as PlatformSettings) });
        }
      } catch (error) {
        console.error("Failed to load platform settings:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchSettings();
  }, []);

  const handleSave = async () => {
    setSaving(true);
    try {
      await setDoc(
        doc(db, "platform_settings", "default"),
        {
          ...settings,
          updatedAt: serverTimestamp(),
        },
        { merge: true }
      );
      alert("Global Settings Saved Successfully!");
    } catch (error) {
      console.error("Failed to save platform settings:", error);
      alert("Failed to save settings.");
    } finally {
      setSaving(false);
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
              <h1 className="text-2xl font-bold text-gray-900 mb-1">App Configuration</h1>
              <p className="text-gray-500 text-sm">Manage global settings for the Habesha Dates mobile app.</p>
            </div>
            <button
              onClick={handleSave}
              disabled={saving || loading}
              className="flex items-center px-4 py-2 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition shadow-sm disabled:opacity-70"
            >
              <Save className="w-4 h-4 mr-2" />
              {saving ? "Saving..." : "Save Changes"}
            </button>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 space-y-6">
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                <div className="p-5 border-b border-gray-100 flex items-center bg-gray-50/50">
                  <Smartphone className="w-5 h-5 text-indigo-500 mr-3" />
                  <h2 className="text-lg font-semibold text-gray-800">Swiping & Matching Rules</h2>
                </div>
                <div className="p-6 space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">Max Daily Swipes (Free Tier)</label>
                      <input
                        type="number"
                        value={settings.maxDailySwipes}
                        onChange={(e) => setSettings({ ...settings, maxDailySwipes: e.target.value })}
                        className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">Algorithm Weighting</label>
                      <select
                        value={settings.matchingAlgorithm}
                        onChange={(e) => setSettings({ ...settings, matchingAlgorithm: e.target.value })}
                        className="w-full border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                      >
                        <option value="balanced">Balanced (Age & Location)</option>
                        <option value="location">Location Heavy</option>
                        <option value="engagement">High Engagement Priority</option>
                      </select>
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                <div className="p-5 border-b border-gray-100 flex items-center bg-gray-50/50">
                  <MapPin className="w-5 h-5 text-indigo-500 mr-3" />
                  <h2 className="text-lg font-semibold text-gray-800">Default Discovery</h2>
                </div>
                <div className="p-6 space-y-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Default Search Radius (km)</label>
                    <input
                      type="range"
                      min="5"
                      max="100"
                      value={settings.defaultSearchRadius}
                      onChange={(e) => setSettings({ ...settings, defaultSearchRadius: e.target.value })}
                      className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-indigo-600"
                    />
                    <div className="text-right text-sm font-bold text-indigo-600 mt-2">
                      {settings.defaultSearchRadius} km
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="space-y-6">
              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
                <h3 className="text-sm font-bold uppercase tracking-wider text-gray-500 mb-6">Security & Access</h3>

                <div className="flex items-center justify-between mb-4">
                  <div>
                    <p className="font-semibold text-gray-800">Photo Verification</p>
                    <p className="text-xs text-gray-500">Require selfie check</p>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      className="sr-only peer"
                      checked={settings.requirePhotoVerification}
                      onChange={() => setSettings({ ...settings, requirePhotoVerification: !settings.requirePhotoVerification })}
                    />
                    <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-500"></div>
                  </label>
                </div>

                <hr className="border-gray-100 my-4" />

                <div className="flex items-center justify-between">
                  <div>
                    <p className="font-semibold text-gray-800">Maintenance Mode</p>
                    <p className="text-xs text-red-500">Locks out all users</p>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      className="sr-only peer"
                      checked={settings.maintenanceMode}
                      onChange={() => setSettings({ ...settings, maintenanceMode: !settings.maintenanceMode })}
                    />
                    <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-red-500"></div>
                  </label>
                </div>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
