import { Link } from "react-router";
import { Car, Search, Bell, ChevronRight, Check, X } from "lucide-react";
import { mockRequests, mockTrips, mockUsers } from "../data/mockData";

export function HomeScreen() {
  const currentUser = mockUsers[2]; // Laura Fernández
  const pendingRequests = mockRequests.filter(r => r.status === "pending").slice(0, 2);
  const nextTrip = mockTrips[0];

  return (
    <div className="min-h-screen bg-[#F0F4FF]">
      {/* Header */}
      <div className="bg-white shadow-sm">
        <div className="max-w-md mx-auto px-6 py-5 flex items-center justify-between">
          <h1 className="text-3xl font-extrabold text-[#2B4EFF] tracking-tight">
            Viajemos
          </h1>
          <div className="flex items-center gap-3">
            <Link to="/notificaciones" className="relative">
              <Bell className="w-6 h-6 text-gray-700" />
              <span className="absolute -top-1 -right-1 w-5 h-5 bg-[#FF6B35] rounded-full flex items-center justify-center text-white text-xs font-bold">
                3
              </span>
            </Link>
            <img
              src={currentUser.avatar}
              alt={currentUser.name}
              className="w-10 h-10 rounded-full object-cover ring-2 ring-[#2B4EFF]"
            />
          </div>
        </div>
      </div>

      <div className="max-w-md mx-auto px-6 py-6 space-y-8">
        {/* Action Cards */}
        <div className="grid grid-cols-2 gap-4">
          <Link
            to="/crear-viaje"
            className="bg-gradient-to-br from-[#2B4EFF] to-[#1a3acc] rounded-[20px] p-6 shadow-lg hover:shadow-xl transition-shadow"
          >
            <div className="flex flex-col items-center text-center space-y-3">
              <div className="w-14 h-14 bg-white/20 rounded-full flex items-center justify-center">
                <Car className="w-7 h-7 text-white" />
              </div>
              <span className="text-white font-bold text-lg leading-tight">
                Publicar un viaje 🚗
              </span>
            </div>
          </Link>

          <Link
            to="/buscar"
            className="bg-gradient-to-br from-[#FF6B35] to-[#e55a25] rounded-[20px] p-6 shadow-lg hover:shadow-xl transition-shadow"
          >
            <div className="flex flex-col items-center text-center space-y-3">
              <div className="w-14 h-14 bg-white/20 rounded-full flex items-center justify-center">
                <Search className="w-7 h-7 text-white" />
              </div>
              <span className="text-white font-bold text-lg leading-tight">
                Buscar viaje 🔍
              </span>
            </div>
          </Link>
        </div>

        {/* Pending Requests Section */}
        {pendingRequests.length > 0 && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-2xl font-extrabold text-gray-900">
                Solicitudes pendientes
              </h2>
              <Link
                to="/solicitudes"
                className="text-[#2B4EFF] font-bold text-sm flex items-center gap-1"
              >
                Ver todas
                <ChevronRight className="w-4 h-4" />
              </Link>
            </div>

            <div className="space-y-3">
              {pendingRequests.map((request) => (
                <div
                  key={request.id}
                  className="bg-white rounded-[20px] p-4 shadow-md hover:shadow-lg transition-shadow"
                >
                  <div className="flex items-center gap-3 mb-3">
                    <img
                      src={request.passenger.avatar}
                      alt={request.passenger.name}
                      className="w-12 h-12 rounded-full object-cover"
                    />
                    <div className="flex-1">
                      <h3 className="font-bold text-gray-900">
                        {request.passenger.name}
                      </h3>
                      <div className="flex items-center gap-1 text-sm text-gray-600">
                        <span className="text-yellow-500">★</span>
                        <span className="font-semibold">{request.passenger.rating}</span>
                        <span className="text-gray-400">·</span>
                        <span>{request.passenger.tripCount} viajes</span>
                      </div>
                    </div>
                  </div>
                  <p className="text-sm text-gray-600 mb-4 line-clamp-2">
                    {request.message}
                  </p>
                  <div className="flex gap-2">
                    <button className="flex-1 bg-[#10B981] text-white font-bold py-3 rounded-xl flex items-center justify-center gap-2 hover:bg-[#059669] transition-colors">
                      <Check className="w-5 h-5" />
                      Aceptar
                    </button>
                    <button className="flex-1 bg-gray-100 text-gray-700 font-bold py-3 rounded-xl flex items-center justify-center gap-2 hover:bg-gray-200 transition-colors">
                      <X className="w-5 h-5" />
                      Rechazar
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Next Trip Section */}
        <div className="space-y-4">
          <h2 className="text-2xl font-extrabold text-gray-900">
            Próximo viaje
          </h2>
          <Link
            to={`/viaje/${nextTrip.id}`}
            className="block bg-white rounded-[20px] p-5 shadow-md hover:shadow-lg transition-shadow"
          >
            <div className="flex items-start justify-between mb-4">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-2">
                  <div className="w-3 h-3 rounded-full bg-[#2B4EFF]"></div>
                  <span className="font-bold text-lg text-gray-900">
                    {nextTrip.from}
                  </span>
                </div>
                <div className="h-8 border-l-2 border-dashed border-gray-300 ml-1.5"></div>
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full bg-[#FF6B35]"></div>
                  <span className="font-bold text-lg text-gray-900">
                    {nextTrip.to}
                  </span>
                </div>
              </div>
              <div className="text-right">
                <div className="text-sm text-gray-500">Mañana</div>
                <div className="font-bold text-xl text-[#2B4EFF]">
                  {nextTrip.time}
                </div>
              </div>
            </div>

            <div className="flex items-center justify-between pt-4 border-t border-gray-100">
              <div className="flex items-center gap-2">
                <img
                  src={nextTrip.driver.avatar}
                  alt={nextTrip.driver.name}
                  className="w-8 h-8 rounded-full object-cover"
                />
                <span className="font-semibold text-gray-700">
                  {nextTrip.driver.name}
                </span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-sm text-gray-500">
                  {nextTrip.passengers.length}/{nextTrip.totalSeats} plazas
                </span>
                <ChevronRight className="w-5 h-5 text-gray-400" />
              </div>
            </div>
          </Link>
        </div>
      </div>
    </div>
  );
}
