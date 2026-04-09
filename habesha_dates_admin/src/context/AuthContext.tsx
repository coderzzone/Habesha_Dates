"use client";

import React, { createContext, useContext, useEffect, useState } from "react";
import { onAuthStateChanged, User } from "firebase/auth";
import { auth, db } from "@/lib/firebase";
import { doc, getDoc } from "firebase/firestore";
import { useRouter, usePathname } from "next/navigation";

interface AuthContextType {
  user: User | null;
  isAdmin: boolean;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  isAdmin: false,
  loading: true,
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      setUser(currentUser);
      
      if (currentUser) {
        // Here we theoretically check the user document to see if they are an admin.
        // For the sake of this CMS boilerplate, we'll verify it against the Firestore users collection.
        try {
          const userDoc = await getDoc(doc(db, "users", currentUser.uid));
          if (userDoc.exists() && userDoc.data().role === "admin") {
             setIsAdmin(true);
          } else {
             setIsAdmin(false);
             // If logged in but not admin, kick them out to login and sign them out
             // auth.signOut();
             // router.push("/login");
          }
        } catch (error) {
          console.error("Error fetching user admin status", error);
          setIsAdmin(false);
        }
      } else {
        setIsAdmin(false);
        if (pathname !== "/login") {
           router.push("/login"); // Force unauthenticated users to login
        }
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, [pathname, router]);

  return (
    <AuthContext.Provider value={{ user, isAdmin, loading }}>
        {!loading && children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
