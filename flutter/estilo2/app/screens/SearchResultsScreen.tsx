import { Link } from "react-router";
import { ArrowLeft, Search, Map, List, Users, ChevronRight } from "lucide-react";
import { useState } from "react";
import { mockTrips } from "../data/mockData";

export function SearchResultsScreen() {
  const [viewMode, setViewMode] = useState<"list" | "map">("list");
  const [searchQuery] = useState("Buenos Aires");

  return (
    <div className="min-h-screen bg-[#F0F4FF]">
      {/* Header */}
      <div className="bg-white shadow-sm">
        <div className="max-w-md mx-auto px-6 py-5">
          <div className="flex items-center gap-3 mb-4">
            <Link to="/" className="p-2 -ml-2 hover:bg-gray-100 rounded-full transition-colors">
              <ArrowLeft className="w-6 h-6 text-gray-700" />
            </Link>
            <h1 className="text-xl font-bold text-gray-900 flex-1">
              Viajes disponibles
            </h1>
          </div>

          {/* Search Bar */}
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              defaultValue={searchQuery}
              placeholder="¿A dónde quieres ir?"
              className="w-full pl-12 pr-4 py-3.5 rounded-xl bg-gray-50 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-[#2B4EFF] focus:border-transparent font-semibold"
            />
          </div>
        </div>
      </div>

      <div className="max-w-md mx-auto px-6 py-6 space-y-4">
        {/* View Toggle */}
        <div className="flex items-center justify-between">
          <div className="text-sm font-semibold text-gray-600">
            {mockTrips.length} viajes encontrados
          </div>
          <div className="flex gap-2 bg-white rounded-lg p-1 shadow-sm">
            <button
              onClick={() => setViewMode("list")}
              className={`p-2 rounded transition-colors ${
                viewMode === "list"
                  ? "bg-[#2B4EFF] text-white"
                  : "text-gray-600 hover:bg-gray-50"
              }`}
            >
              <List className="w-5 h-5" />
            </button>
            <button
              onClick={() => setViewMode("map")}
              className={`p-2 rounded transition-colors ${
                viewMode === "map"
                  ? "bg-[#2B4EFF] text-white"
                  : "text-gray-600 hover:bg-gray-50"
              }`}
            >
              <Map className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Map View */}
        {viewMode === "map" && (
          <div className="space-y-4">
            <div className="bg-white rounded-[20px] p-4 shadow-md">
              <div className="aspect-[4/3] bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl relative overflow-hidden">
                {/* Simplified map with pins */}
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="space-y-8">
                    <div className="flex items-center justify-around gap-12">
                      <div className="w-8 h-8 bg-[#2B4EFF] rounded-full shadow-lg flex items-center justify-center text-white font-bold text-sm">
                        3
                      </div>
                      <div className="w-6 h-6 bg-[#FF6B35] rounded-full shadow-lg"></div>
                    </div>
                    <div className="flex items-center justify-center">
                      <div className="w-6 h-6 bg-[#2B4EFF] rounded-full shadow-lg"></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Floating Trip Cards */}
            <div className="space-y-3">
              {mockTrips.slice(0, 2).map((trip) => (
                <TripCard key={trip.id} trip={trip} compact />
              ))}
            </div>
          </div>
        )}

        {/* List View */}
        {viewMode === "list" && (
          <div className="space-y-3">
            {mockTrips.map((trip) => (
              <TripCard key={trip.id} trip={trip} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function TripCard({ trip, compact = false }: { trip: typeof mockTrips[0]; compact?: boolean }) {
  const filledSeats = trip.totalSeats - trip.availableSeats;
  const statusColors = {
    open: "bg-[#10B981]",
    pending: "bg-[#F59E0B]",
    full: "bg-[#EF4444]",
  };

  const statusLabels = {
    open: "Disponible",
    pending: "Pendiente",
    full: "Completo",
  };

  return (
    <Link
      to={`/viaje/${trip.id}`}
      className="block bg-white rounded-[20px] p-5 shadow-md hover:shadow-lg transition-shadow"
    >
      <div className="flex items-start gap-4">
        {/* Driver Photo */}
        <img
          src={trip.driver.avatar}
          alt={trip.driver.name}
          className="w-14 h-14 rounded-full object-cover flex-shrink-0"
        />

        {/* Trip Info */}
        <div className="flex-1 min-w-0">
          {/* Driver Name & Rating */}
          <div className="flex items-center gap-2 mb-2">
            <h3 className="font-bold text-gray-900 truncate">
              {trip.driver.name}
            </h3>
            <div className="flex items-center gap-1 text-sm flex-shrink-0">
              <span className="text-yellow-500">★</span>
              <span className="font-bold text-gray-700">{trip.driver.rating}</span>
            </div>
          </div>

          {/* Route Visualization */}
          <div className="space-y-2 mb-3">
            <div className="flex items-center gap-2">
              <div className="w-2.5 h-2.5 rounded-full bg-[#2B4EFF]"></div>
              <span className="font-semibold text-gray-900">{trip.from}</span>
            </div>
            <div className="h-6 border-l-2 border-dashed border-gray-300 ml-1"></div>
            <div className="flex items-center gap-2">
              <div className="w-2.5 h-2.5 rounded-full bg-[#FF6B35]"></div>
              <span className="font-semibold text-gray-900">{trip.to}</span>
            </div>
          </div>

          {/* Trip Details */}
          <div className="flex items-center gap-4 text-sm text-gray-600 mb-3">
            <div className="flex items-center gap-1.5">
              <span className="font-semibold">📅</span>
              <span>{new Date(trip.date).toLocaleDateString('es-AR', { month: 'short', day: 'numeric' })}</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="font-semibold">🕐</span>
              <span>{trip.time}</span>
            </div>
          </div>

          {/* Seats & Status */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Users className="w-4 h-4 text-gray-400" />
              <div className="flex gap-1">
                {Array.from({ length: trip.totalSeats }).map((_, i) => (
                  <div
                    key={i}
                    className={`w-6 h-6 rounded-full border-2 ${
                      i < filledSeats
                        ? "bg-[#2B4EFF] border-[#2B4EFF]"
                        : "bg-white border-gray-300"
                    }`}
                  ></div>
                ))}
              </div>
            </div>

            <div className="flex items-center gap-3">
              <div className={`px-2 py-1 rounded-lg text-xs font-bold text-white ${statusColors[trip.status]}`}>
                {statusLabels[trip.status]}
              </div>
              <div className="text-[#FF6B35] font-bold text-lg">
                ${trip.price}
              </div>
              <ChevronRight className="w-5 h-5 text-gray-400" />
            </div>
          </div>
        </div>
      </div>
    </Link>
  );
}
