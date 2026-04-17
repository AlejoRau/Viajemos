import { Home, MapPin, MessageCircle, Bell, User } from "lucide-react";
import { Link, useLocation } from "react-router";

export default function BottomNav() {
  const location = useLocation();
  
  const navItems = [
    { icon: Home, label: "Home", path: "/" },
    { icon: MapPin, label: "Mis Viajes", path: "/search" },
    { icon: MessageCircle, label: "Chat", path: "/chat/1" },
    { icon: Bell, label: "Notificaciones", path: "/notifications" },
    { icon: User, label: "Perfil", path: "/profile" },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 pb-safe z-50">
      <div className="flex justify-around items-center h-16 max-w-md mx-auto px-2">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = location.pathname === item.path;
          
          return (
            <Link
              key={item.path}
              to={item.path}
              className="flex flex-col items-center justify-center gap-1 flex-1 py-2"
            >
              <Icon
                className={`w-5 h-5 ${
                  isActive ? "text-[#1B6B3A]" : "text-gray-500"
                }`}
              />
              <span
                className={`text-[10px] ${
                  isActive ? "text-[#1B6B3A] font-medium" : "text-gray-500"
                }`}
              >
                {item.label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
