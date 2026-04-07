import { useNavigate } from "react-router";
import { ArrowLeft, MapPin, List } from "lucide-react";

export function DriverHome() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <div className="bg-[#1A73E8] text-white px-6 py-4 flex items-center gap-4 shadow-md">
        <button onClick={() => navigate("/")} className="p-1">
          <ArrowLeft className="w-6 h-6" />
        </button>
        <h1 className="text-xl font-semibold">Conductor</h1>
      </div>

      {/* Content */}
      <div className="px-6 py-8">
        <div className="max-w-md mx-auto space-y-4">
          {/* Create Trip Card */}
          <button
            onClick={() => navigate("/driver/create-trip")}
            className="w-full bg-white border-2 border-gray-200 rounded-2xl p-8 shadow-md hover:shadow-lg hover:border-[#1A73E8] transition-all flex flex-col items-center gap-3"
          >
            <div className="w-16 h-16 bg-[#E8F0FE] rounded-full flex items-center justify-center">
              <MapPin className="w-8 h-8 text-[#1A73E8]" />
            </div>
            <span className="text-xl font-semibold text-gray-800">Crear un viaje</span>
          </button>

          {/* View Requests Card */}
          <button
            onClick={() => navigate("/driver/passenger-requests")}
            className="w-full bg-white border-2 border-gray-200 rounded-2xl p-8 shadow-md hover:shadow-lg hover:border-[#1A73E8] transition-all flex flex-col items-center gap-3"
          >
            <div className="w-16 h-16 bg-[#E8F0FE] rounded-full flex items-center justify-center">
              <List className="w-8 h-8 text-[#1A73E8]" />
            </div>
            <span className="text-xl font-semibold text-gray-800">Ver pedidos de pasajeros</span>
          </button>
        </div>
      </div>
    </div>
  );
}
