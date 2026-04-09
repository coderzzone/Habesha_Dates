"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { 
  Home, 
  Users, 
  Heart, 
  AlertOctagon, 
  Settings, 
  LogOut, 
  DollarSign, 
  BarChart3,
  Shield, 
  Bell, 
  ToggleLeft, 
  UserCog, 
  ClipboardList, 
  CreditCard,
  Receipt
} from "lucide-react";
import { auth } from "@/lib/firebase";
import { signOut } from "firebase/auth";

const menus = [
  { name: "Dashboard", href: "/", icon: Home },
  { name: "Users", href: "/users", icon: Users },
  { name: "Matches", href: "/matches", icon: Heart },
  { name: "Reports", href: "/reports", icon: AlertOctagon },
  { name: "Safety", href: "/safety", icon: Shield },
  { name: "Revenue", href: "/revenue", icon: DollarSign },
  { name: "Monetization", href: "/monetization", icon: CreditCard },
  { name: "Transactions", href: "/transactions", icon: Receipt },
  { name: "Payment Requests", href: "/payments", icon: ClipboardList },
  { name: "Analytics", href: "/analytics", icon: BarChart3 },
  { name: "Notifications", href: "/notifications", icon: Bell },
  { name: "Feature Flags", href: "/feature-flags", icon: ToggleLeft },
  { name: "Admin Roles", href: "/admin-roles", icon: UserCog },
  { name: "Audit Logs", href: "/audit-logs", icon: ClipboardList },
  { name: "Settings", href: "/settings", icon: Settings },
];

export default function Sidebar() {
  const pathname = usePathname();

  const handleLogout = async () => {
    try {
      await signOut(auth);
    } catch (error) {
      console.error("Error signing out: ", error);
    }
  };

  return (
    <aside className="fixed inset-y-0 left-0 w-64 bg-white shadow-lg z-50 flex flex-col">
      <div className="h-16 flex items-center px-6 border-b border-gray-100">
        <Link href="/" className="text-lg font-semibold text-gray-900 tracking-tight">
          Habesha Dates
          <span className="ml-2 text-xs uppercase tracking-[0.2em] text-indigo-600">Admin</span>
        </Link>
      </div>

      <div className="flex-1 py-6 px-4 space-y-2 overflow-y-auto">
        <div className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-4 px-2">
          Apps & Pages
        </div>
        
        {menus.map((menu) => {
          const isActive = pathname === menu.href;
          const Icon = menu.icon;
          return (
            <Link
              key={menu.name}
              href={menu.href}
              className={`flex items-center px-4 py-3 rounded-xl transition-all duration-200 group ${
                isActive
                  ? "bg-indigo-50 text-indigo-600 font-medium shadow-sm"
                  : "text-gray-600 hover:bg-gray-50 hover:text-gray-900"
              }`}
            >
              <Icon 
                className={`w-5 h-5 mr-3 transition-colors ${
                  isActive ? "text-indigo-600" : "text-gray-400 group-hover:text-gray-500"
                }`} 
              />
              {menu.name}
            </Link>
          );
        })}
      </div>

      <div className="p-4 border-t border-gray-100">
        <button
          onClick={handleLogout}
          className="flex items-center w-full px-4 py-3 text-red-600 hover:bg-red-50 rounded-xl transition-colors"
        >
          <LogOut className="w-5 h-5 mr-3" />
          <span className="font-medium">Logout</span>
        </button>
      </div>
    </aside>
  );
}
