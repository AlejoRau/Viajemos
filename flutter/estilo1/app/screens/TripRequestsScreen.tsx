import { ArrowLeft, Star } from "lucide-react";
import { Link } from "react-router";
import BottomNav from "../components/BottomNav";

export default function TripRequestsScreen() {
  const requests = [
    {
      id: 1,
      name: "Ana García",
      rating: 4.8,
      trips: 15,
      image: "https://i.pravatar.cc/150?img=9",
      message: "¡Hola! Me gustaría unirme a tu viaje, voy a visitar a mi familia en Buenos Aires.",
    },
    {
      id: 2,
      name: "Juan Pérez",
      rating: 4.5,
      trips: 8,
      image: "https://i.pravatar.cc/150?img=13",
      message: "Hola Lucas, tengo reunión de trabajo temprano. ¿Hay lugar?",
    },
    {
      id: 3,
      name: "Sofía Martínez",
      rating: 4.9,
      trips: 22,
      image: "https://i.pravatar.cc/150?img=25",
      message: "Buenas! Necesito llegar a Buenos Aires mañana. Puedo compartir los gastos de peaje también.",
    },
  ];

  return (
    <div className="min-h-screen bg-[#F9FAF7] pb-20">
      {/* Header */}
      <div className="bg-[#1B6B3A] text-white px-6 pt-12 pb-6 sticky top-0 z-10">
        <div className="flex items-center gap-4 mb-2">
          <Link to="/" className="p-2 -ml-2">
            <ArrowLeft className="w-6 h-6" />
          </Link>
          <h1 className="text-xl font-semibold">Solicitudes ({requests.length})</h1>
        </div>
        <p className="text-white/80 text-sm mt-2">
          Córdoba → Buenos Aires • Mañana 08:00
        </p>
      </div>

      <div className="px-6 py-6 space-y-4">
        {requests.map((request) => (
          <div
            key={request.id}
            className="bg-white rounded-2xl shadow-sm p-5 border-l-4 border-[#F4A228]"
          >
            <div className="flex gap-4 mb-4">
              <img
                src={request.image}
                alt={request.name}
                className="w-16 h-16 rounded-full border-2 border-[#4CAF7D]/20"
              />
              <div className="flex-1">
                <h3 className="font-semibold text-gray-900 mb-1">
                  {request.name}
                </h3>
                <div className="flex items-center gap-3 text-sm text-gray-600">
                  <div className="flex items-center gap-1">
                    <Star className="w-4 h-4 fill-[#F4A228] text-[#F4A228]" />
                    <span className="font-medium">{request.rating}</span>
                  </div>
                  <span>•</span>
                  <span className="bg-[#1B6B3A]/10 text-[#1B6B3A] px-2 py-0.5 rounded-full text-xs font-medium">
                    {request.trips} viajes
                  </span>
                </div>
              </div>
            </div>

            <p className="text-sm text-gray-700 mb-4 bg-gray-50 rounded-xl p-3">
              {request.message}
            </p>

            <div className="flex gap-3">
              <button className="flex-1 bg-white border-2 border-red-400 text-red-600 py-3 rounded-xl font-semibold hover:bg-red-50 transition-colors">
                Rechazar
              </button>
              <button className="flex-1 bg-[#1B6B3A] text-white py-3 rounded-xl font-semibold hover:bg-[#155a30] transition-colors">
                Aceptar
              </button>
            </div>
          </div>
        ))}

        {requests.length === 0 && (
          <div className="text-center py-12">
            <p className="text-gray-500">No hay solicitudes pendientes</p>
          </div>
        )}
      </div>

      <BottomNav />
    </div>
  );
}
