import { useNavigate } from "react-router";
import { Car, Backpack } from "lucide-react";

export function Home() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-white flex flex-col items-center justify-center px-6 py-12">
      <div className="w-full max-w-md">
        {/* Logo/Brand */}
        <div className="text-center mb-3">
          <h1 className="text-5xl font-bold text-[#1A73E8] mb-4">Viajemos</h1>
          <p className="text-lg text-gray-600">Tu próximo viaje, más fácil</p>
        </div>

        {/* Role Selection Cards */}
        <div className="mt-16 space-y-4">
          {/* Driver Card */}
          <button
            onClick={() => navigate("/driver")}
            className="w-full bg-[#1A73E8] text-white rounded-2xl p-8 shadow-lg hover:bg-[#1557b0] transition-colors flex items-center justify-center gap-4"
          >
            <Car className="w-8 h-8" />
            <span className="text-xl font-semibold">Soy el conductor</span>
          </button>

          {/* Passenger Card */}
          <button
            onClick={() => navigate("/passenger")}
            className="w-full bg-white text-[#1A73E8] border-2 border-[#1A73E8] rounded-2xl p-8 shadow-md hover:bg-[#E8F0FE] transition-colors flex items-center justify-center gap-4"
          >
            <Backpack className="w-8 h-8" />
            <span className="text-xl font-semibold">Soy un pasajero</span>
          </button>
        </div>
      </div>
    </div>
  );
}
