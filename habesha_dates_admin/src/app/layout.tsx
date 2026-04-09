import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/context/AuthContext";
import Sidebar from "@/components/layout/Sidebar";
import Navbar from "@/components/layout/Navbar";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Habesha Dates | Admin CMS",
  description: "Administrative dashboard for Habesha Dates app",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={`${inter.className} bg-gray-50 text-gray-900 antialiased`} suppressHydrationWarning>
        <AuthProvider>
          {/* 
            Since this layout wraps the whole app, we use a simple check inside children
            if it's the login page, we won't show the sidebar. 
            For now, we render Sidebar/Navbar generally. A true implementation 
            might use conditional rendering based on pathname (which we will handle in page components) 
            or a separate layout for authenticated views.
          */}
          {children}
        </AuthProvider>
      </body>
    </html>
  );
}
