import { Link } from "react-router";
import { ArrowLeft, CheckCircle, AlertCircle, Clock, XCircle } from "lucide-react";
import { mockNotifications } from "../data/mockData";

export function NotificationsScreen() {
  const unreadCount = mockNotifications.filter(n => !n.read).length;

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case "accepted":
        return <CheckCircle className="w-5 h-5 text-[#10B981]" />;
      case "request":
        return <AlertCircle className="w-5 h-5 text-[#F59E0B]" />;
      case "reminder":
        return <Clock className="w-5 h-5 text-[#2B4EFF]" />;
      case "declined":
        return <XCircle className="w-5 h-5 text-[#EF4444]" />;
      default:
        return <AlertCircle className="w-5 h-5 text-gray-400" />;
    }
  };

  const getNotificationDotColor = (type: string) => {
    switch (type) {
      case "accepted":
        return "bg-[#10B981]";
      case "request":
        return "bg-[#F59E0B]";
      case "reminder":
        return "bg-[#2B4EFF]";
      case "declined":
        return "bg-[#EF4444]";
      default:
        return "bg-gray-400";
    }
  };

  return (
    <div className="min-h-screen bg-[#F0F4FF]">
      {/* Header */}
      <div className="bg-white shadow-sm">
        <div className="max-w-md mx-auto px-6 py-5">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center gap-3">
              <Link to="/" className="p-2 -ml-2 hover:bg-gray-100 rounded-full transition-colors">
                <ArrowLeft className="w-6 h-6 text-gray-700" />
              </Link>
              <h1 className="text-xl font-bold text-gray-900">
                Actividad
              </h1>
            </div>
            <button className="text-sm font-bold text-[#2B4EFF] hover:text-[#1a3acc]">
              Marcar todo como leído
            </button>
          </div>
          
          {unreadCount > 0 && (
            <div className="text-sm text-gray-600 ml-14">
              {unreadCount} {unreadCount === 1 ? "notificación nueva" : "notificaciones nuevas"}
            </div>
          )}
        </div>
      </div>

      <div className="max-w-md mx-auto py-4">
        {/* Notifications Feed */}
        <div className="divide-y divide-gray-100">
          {mockNotifications.map((notification) => (
            <div
              key={notification.id}
              className={`px-6 py-4 hover:bg-white transition-colors ${
                !notification.read ? "bg-blue-50/50" : ""
              }`}
            >
              <div className="flex items-start gap-4">
                {/* Icon with Dot */}
                <div className="relative flex-shrink-0 mt-1">
                  {getNotificationIcon(notification.type)}
                  <div className={`absolute -left-1.5 -top-1.5 w-3 h-3 rounded-full ${getNotificationDotColor(notification.type)}`}></div>
                </div>

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <p className={`text-gray-900 mb-1 ${!notification.read ? "font-semibold" : ""}`}>
                    {notification.message}
                  </p>
                  <p className="text-sm text-gray-500">
                    {notification.timestamp}
                  </p>
                </div>

                {/* Unread Indicator */}
                {!notification.read && (
                  <div className="w-2 h-2 rounded-full bg-[#2B4EFF] mt-2 flex-shrink-0"></div>
                )}
              </div>
            </div>
          ))}
        </div>

        {/* Empty State */}
        {mockNotifications.length === 0 && (
          <div className="text-center py-16">
            <div className="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <AlertCircle className="w-10 h-10 text-gray-400" />
            </div>
            <p className="text-gray-500 font-semibold mb-2">
              No hay notificaciones
            </p>
            <p className="text-sm text-gray-400">
              Cuando tengas actividad nueva, aparecerá aquí
            </p>
          </div>
        )}

        {/* Action Buttons */}
        <div className="px-6 pt-8 pb-6 space-y-3">
          <Link
            to="/solicitudes"
            className="block bg-white rounded-xl p-4 shadow-sm hover:shadow-md transition-shadow"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-orange-50 rounded-full flex items-center justify-center">
                  <AlertCircle className="w-5 h-5 text-[#F59E0B]" />
                </div>
                <span className="font-bold text-gray-900">
                  Ver solicitudes pendientes
                </span>
              </div>
              <span className="w-6 h-6 bg-[#F59E0B] rounded-full flex items-center justify-center text-white text-xs font-bold">
                2
              </span>
            </div>
          </Link>

          <Link
            to="/"
            className="block bg-white rounded-xl p-4 shadow-sm hover:shadow-md transition-shadow"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-blue-50 rounded-full flex items-center justify-center">
                  <Clock className="w-5 h-5 text-[#2B4EFF]" />
                </div>
                <span className="font-bold text-gray-900">
                  Ver próximos viajes
                </span>
              </div>
            </div>
          </Link>
        </div>
      </div>
    </div>
  );
}
