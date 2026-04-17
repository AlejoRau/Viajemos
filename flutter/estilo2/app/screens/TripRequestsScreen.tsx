import { Link } from "react-router";
import { ArrowLeft, ChevronLeft, ChevronRight, Check, X } from "lucide-react";
import { useState } from "react";
import { mockRequests } from "../data/mockData";

export function TripRequestsScreen() {
  const [activeTab, setActiveTab] = useState<"pending" | "accepted">("pending");
  const [swipedCard, setSwipedCard] = useState<string | null>(null);

  const pendingRequests = mockRequests.filter(r => r.status === "pending");
  const acceptedRequests = mockRequests.filter(r => r.status === "accepted");
  const currentRequests = activeTab === "pending" ? pendingRequests : acceptedRequests;

  const handleAccept = (id: string) => {
    setSwipedCard(id);
    setTimeout(() => setSwipedCard(null), 500);
  };

  const handleReject = (id: string) => {
    setSwipedCard(id);
    setTimeout(() => setSwipedCard(null), 500);
  };

  return (
    <div className="min-h-screen bg-[#F0F4FF]">
      {/* Header */}
      <div className="bg-white shadow-sm">
        <div className="max-w-md mx-auto px-6 py-5 flex items-center justify-between">
          <Link to="/" className="p-2 -ml-2 hover:bg-gray-100 rounded-full transition-colors">
            <ArrowLeft className="w-6 h-6 text-gray-700" />
          </Link>
          <h1 className="text-xl font-bold text-gray-900">
            Solicitudes de viaje
          </h1>
          <div className="w-10"></div>
        </div>
      </div>

      <div className="max-w-md mx-auto">
        {/* Title */}
        <div className="px-6 pt-6 pb-4">
          <h2 className="text-3xl font-extrabold text-gray-900">
            Quieren sumarse a tu viaje
          </h2>
        </div>

        {/* Filter Tabs */}
        <div className="px-6 pb-4">
          <div className="flex gap-2 bg-white rounded-xl p-1.5 shadow-sm">
            <button
              onClick={() => setActiveTab("pending")}
              className={`flex-1 py-2.5 rounded-lg font-bold text-sm transition-all ${
                activeTab === "pending"
                  ? "bg-[#2B4EFF] text-white"
                  : "text-gray-600 hover:bg-gray-50"
              }`}
            >
              Pendientes ({pendingRequests.length})
            </button>
            <button
              onClick={() => setActiveTab("accepted")}
              className={`flex-1 py-2.5 rounded-lg font-bold text-sm transition-all ${
                activeTab === "accepted"
                  ? "bg-[#2B4EFF] text-white"
                  : "text-gray-600 hover:bg-gray-50"
              }`}
            >
              Aceptados ({acceptedRequests.length})
            </button>
          </div>
        </div>

        {/* Swipe Hint */}
        {activeTab === "pending" && currentRequests.length > 0 && (
          <div className="px-6 pb-4">
            <div className="bg-blue-50 rounded-xl p-3 flex items-center justify-center gap-3">
              <ChevronLeft className="w-5 h-5 text-[#EF4444] animate-pulse" />
              <span className="text-sm font-semibold text-gray-700">
                Desliza para aceptar o rechazar
              </span>
              <ChevronRight className="w-5 h-5 text-[#10B981] animate-pulse" />
            </div>
          </div>
        )}

        {/* Request Cards Feed */}
        <div className="px-6 pb-6 space-y-4">
          {currentRequests.map((request) => (
            <div
              key={request.id}
              className={`bg-white rounded-[20px] shadow-md hover:shadow-lg transition-all border-l-4 overflow-hidden ${
                activeTab === "pending"
                  ? "border-[#F59E0B]"
                  : "border-[#10B981]"
              } ${swipedCard === request.id ? "opacity-50 scale-95" : ""}`}
            >
              <div className="p-5 space-y-4">
                {/* Passenger Info */}
                <div className="flex items-center gap-3">
                  <img
                    src={request.passenger.avatar}
                    alt={request.passenger.name}
                    className="w-14 h-14 rounded-full object-cover"
                  />
                  <div className="flex-1">
                    <h3 className="font-bold text-lg text-gray-900">
                      {request.passenger.name}
                    </h3>
                    <div className="flex items-center gap-1.5 text-sm text-gray-600">
                      <span className="text-yellow-500">★</span>
                      <span className="font-bold">{request.passenger.rating}</span>
                      <span className="text-gray-400">·</span>
                      <span>{request.passenger.tripCount} viajes</span>
                    </div>
                  </div>
                  {activeTab === "accepted" && (
                    <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                      <Check className="w-5 h-5 text-[#10B981]" />
                    </div>
                  )}
                </div>

                {/* Trip Route */}
                <div className="bg-gray-50 rounded-xl p-3">
                  <div className="flex items-center gap-2 text-sm">
                    <span className="font-semibold text-gray-900">
                      {request.trip.from}
                    </span>
                    <span className="text-gray-400">→</span>
                    <span className="font-semibold text-gray-900">
                      {request.trip.to}
                    </span>
                    <span className="text-gray-400 ml-auto">
                      {request.trip.date}
                    </span>
                  </div>
                </div>

                {/* Message Preview */}
                <div className="bg-blue-50 rounded-xl p-3">
                  <p className="text-sm text-gray-700">
                    "{request.message}"
                  </p>
                </div>

                {/* Action Buttons */}
                {activeTab === "pending" && (
                  <div className="flex gap-3 pt-2">
                    <button
                      onClick={() => handleReject(request.id)}
                      className="flex-1 bg-gray-100 text-gray-700 font-bold py-3.5 rounded-xl flex items-center justify-center gap-2 hover:bg-gray-200 transition-colors"
                    >
                      <X className="w-5 h-5" />
                      Rechazar
                    </button>
                    <button
                      onClick={() => handleAccept(request.id)}
                      className="flex-1 bg-[#10B981] text-white font-bold py-3.5 rounded-xl flex items-center justify-center gap-2 hover:bg-[#059669] transition-colors"
                    >
                      <Check className="w-5 h-5" />
                      Aceptar
                    </button>
                  </div>
                )}
              </div>
            </div>
          ))}

          {currentRequests.length === 0 && (
            <div className="text-center py-12">
              <p className="text-gray-500 font-semibold">
                No hay solicitudes {activeTab === "pending" ? "pendientes" : "aceptadas"}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
