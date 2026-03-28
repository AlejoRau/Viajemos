import { Plus, MapPin, Calendar, Users } from "lucide-react";
import { Link } from "react-router";
import BottomNav from "../components/BottomNav";

export default function HomeScreen() {
  const passengers = [
    { id: 1, name: "María", image: "https://i.pravatar.cc/150?img=5" },
    { id: 2, name: "Carlos", image: "https://i.pravatar.cc/150?img=12" },
  ];

  return (
    <div className="min-h-screen bg-[#F9FAF7] pb-20">
      {/* Header */}
      <div className="bg-gradient-to-b from-[#1B6B3A] to-[#1B6B3A]/90 text-white px-6 pt-12 pb-8 rounded-b-[32px]">
        <h1 className="text-2xl mb-1">Buenos días, Lucas 👋</h1>
        <p className="text-white/80 text-sm">¿Listo para tu próximo viaje?</p>
      </div>

      <div className="px-6 -mt-4">
        {/* Next Trip Card */}
        <div className="bg-white rounded-2xl shadow-lg p-5 mb-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-gray-900 font-semibold">Tu próximo viaje</h3>
            <span className="text-xs bg-[#4CAF7D]/10 text-[#1B6B3A] px-3 py-1 rounded-full font-medium">
              Confirmado
            </span>
          </div>
          
          <div className="space-y-3 mb-4">
            <div className="flex items-start gap-3">
              <MapPin className="w-5 h-5 text-[#1B6B3A] mt-0.5" />
              <div className="flex-1">
                <p className="text-sm text-gray-600">Desde</p>
                <p className="font-semibold text-gray-900">Córdoba</p>
              </div>
            </div>
            
            <div className="flex items-center gap-3 pl-8">
              <div className="w-0.5 h-8 bg-gray-300 -ml-8"></div>
            </div>
            
            <div className="flex items-start gap-3">
              <MapPin className="w-5 h-5 text-[#F4A228] mt-0.5" />
              <div className="flex-1">
                <p className="text-sm text-gray-600">Hasta</p>
                <p className="font-semibold text-gray-900">Buenos Aires</p>
              </div>
            </div>
          </div>

          <div className="flex items-center justify-between pt-4 border-t border-gray-100">
            <div className="flex items-center gap-2">
              <Calendar className="w-4 h-4 text-gray-500" />
              <span className="text-sm text-gray-700">Mañana, 08:00</span>
            </div>
            <div className="flex items-center gap-2">
              <Users className="w-4 h-4 text-gray-500" />
              <span className="text-sm text-gray-700">2/4 asientos</span>
            </div>
          </div>

          {/* Passengers */}
          <div className="mt-4 pt-4 border-t border-gray-100">
            <p className="text-xs text-gray-600 mb-3">Pasajeros confirmados</p>
            <div className="flex gap-2">
              {passengers.map((passenger) => (
                <div key={passenger.id} className="flex flex-col items-center">
                  <img
                    src={passenger.image}
                    alt={passenger.name}
                    className="w-12 h-12 rounded-full border-2 border-[#4CAF7D]"
                  />
                  <span className="text-xs text-gray-600 mt-1">
                    {passenger.name}
                  </span>
                </div>
              ))}
              <div className="flex flex-col items-center">
                <div className="w-12 h-12 rounded-full border-2 border-dashed border-gray-300 flex items-center justify-center">
                  <span className="text-gray-400 text-xs">+2</span>
                </div>
                <span className="text-xs text-gray-400 mt-1">Libres</span>
              </div>
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="space-y-3 mb-6">
          <Link
            to="/trip-requests"
            className="block bg-white rounded-2xl p-4 shadow-sm border border-[#F4A228]/20"
          >
            <div className="flex items-center justify-between">
              <div>
                <h4 className="font-semibold text-gray-900 mb-1">
                  Solicitudes pendientes
                </h4>
                <p className="text-sm text-gray-600">
                  3 personas quieren unirse
                </p>
              </div>
              <div className="bg-[#F4A228] text-white w-8 h-8 rounded-full flex items-center justify-center font-semibold">
                3
              </div>
            </div>
          </Link>

          <Link
            to="/search"
            className="block bg-white rounded-2xl p-4 shadow-sm"
          >
            <div className="flex items-center justify-between">
              <div>
                <h4 className="font-semibold text-gray-900 mb-1">
                  Buscar viajes
                </h4>
                <p className="text-sm text-gray-600">
                  Encontrá tu próximo destino
                </p>
              </div>
              <MapPin className="w-6 h-6 text-[#4CAF7D]" />
            </div>
          </Link>
        </div>
      </div>

      {/* FAB Button */}
      <Link
        to="/create-trip"
        className="fixed bottom-24 right-6 w-16 h-16 bg-[#1B6B3A] rounded-full shadow-2xl flex items-center justify-center z-40"
      >
        <Plus className="w-8 h-8 text-white" />
      </Link>

      <BottomNav />
    </div>
  );
}
