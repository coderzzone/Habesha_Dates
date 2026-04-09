"use client";

import React from "react";
import { Bell, Search, Menu } from "lucide-react";
import { useAuth } from "@/context/AuthContext";

export default function Navbar() {
  const { user } = useAuth();

  return (
    <header className="h-16 bg-white/80 backdrop-blur-md sticky top-0 z-40 border-b border-gray-100 px-6 flex items-center justify-between transition-all duration-300">
      
      {/* Left side */}
      <div className="flex items-center">
        <button className="p-2 mr-2 md:hidden text-gray-500 hover:bg-gray-100 rounded-lg">
          <Menu className="w-5 h-5" />
        </button>
        
        <div className="hidden md:flex items-center bg-gray-50 px-3 py-2 rounded-xl focus-within:ring-2 focus-within:ring-indigo-100 transition-all">
          <Search className="w-4 h-4 text-gray-400 mr-2" />
          <input 
            type="text" 
            placeholder="Search (Ctrl+/)" 
            className="bg-transparent border-none outline-none text-sm w-48 text-gray-700 placeholder-gray-400"
          />
        </div>
      </div>

      {/* Right side */}
      <div className="flex items-center space-x-4">
        <button className="relative p-2 text-gray-500 hover:bg-gray-100 rounded-full transition-colors">
          <Bell className="w-5 h-5" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full border-2 border-white"></span>
        </button>

        <div className="h-8 w-px bg-gray-200 mx-2"></div>

        <div className="flex items-center cursor-pointer group">
          <div className="w-9 h-9 rounded-full bg-indigo-100 flex items-center justify-center overflow-hidden border-2 border-transparent group-hover:border-indigo-100 transition-all">
            {user?.photoURL ? (
              <img src={user.photoURL} alt="Avatar" className="w-full h-full object-cover" />
            ) : (
              <span className="text-indigo-600 font-bold text-sm">
                {user?.email?.charAt(0).toUpperCase() || 'A'}
              </span>
            )}
            
          </div>
          <div className="hidden md:block ml-3">
             <p className="text-sm font-semibold text-gray-700 leading-none mb-1">Admin</p>
             <p className="text-xs text-gray-500">{user?.email || 'admin@habesha.com'}</p>
          </div>
        </div>
      </div>
      
    </header>
  );
}
