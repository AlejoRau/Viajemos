import { Link } from "react-router";
import { ArrowLeft, MapPin, Navigation } from "lucide-react";
import { useState } from "react";

export function CreateTripScreen() {
  const [step] = useState(1);
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");

  return (
    <div className="min-h-screen bg-[#F0F4FF]">
      {/* Header */}
      <div className="bg-white shadow-sm">
        <div className="max-w-md mx-auto px-6 py-5 flex items-center justify-between">
          <Link to="/" className="p-2 -ml-2 hover:bg-gray-100 rounded-full transition-colors">
            <ArrowLeft className="w-6 h-6 text-gray-700" />
          </Link>
          <h1 className="text-xl font-bold text-gray-900">
            Crear viaje
          </h1>
          <div className="w-10"></div>
        </div>
      </div>

      <div className="max-w-md mx-auto px-6 py-8 space-y-8">
        {/* Progress Dots */}
        <div className="flex items-center justify-center gap-3">
          <div className={`w-3 h-3 rounded-full ${step >= 1 ? 'bg-[#2B4EFF]' : 'bg-gray-300'}`}></div>
          <div className={`w-3 h-3 rounded-full ${step >= 2 ? 'bg-[#2B4EFF]' : 'bg-gray-300'}`}></div>
          <div className={`w-3 h-3 rounded-full ${step >= 3 ? 'bg-[#2B4EFF]' : 'bg-gray-300'}`}></div>
        </div>

        {/* Step 1: Location */}
        {step === 1 && (
          <div className="space-y-6">
            <h2 className="text-4xl font-extrabold text-gray-900 leading-tight">
              ¿A dónde vas?
            </h2>

            <div className="space-y-4">
              {/* From Field */}
              <button
                className="w-full bg-white rounded-[20px] p-6 shadow-md hover:shadow-lg transition-shadow text-left"
                onClick={() => setFrom("Córdoba, Argentina")}
              >
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 bg-[#E3EBFF] rounded-full flex items-center justify-center flex-shrink-0">
                    <Navigation className="w-6 h-6 text-[#2B4EFF]" />
                  </div>
                  <div className="flex-1">
                    <div className="text-sm font-semibold text-gray-500 mb-1">
                      Origen
                    </div>
                    <div className="text-lg font-bold text-gray-900">
                      {from || "Seleccionar ubicación"}
                    </div>
                  </div>
                </div>
              </button>

              {/* To Field */}
              <button
                className="w-full bg-white rounded-[20px] p-6 shadow-md hover:shadow-lg transition-shadow text-left"
                onClick={() => setTo("Buenos Aires, Argentina")}
              >
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 bg-[#FFE8E0] rounded-full flex items-center justify-center flex-shrink-0">
                    <MapPin className="w-6 h-6 text-[#FF6B35]" />
                  </div>
                  <div className="flex-1">
                    <div className="text-sm font-semibold text-gray-500 mb-1">
                      Destino
                    </div>
                    <div className="text-lg font-bold text-gray-900">
                      {to || "Seleccionar ubicación"}
                    </div>
                  </div>
                </div>
              </button>
            </div>

            {/* Map Preview */}
            {from && to && (
              <div className="bg-white rounded-[20px] p-4 shadow-md">
                <div className="aspect-video bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl relative overflow-hidden">
                  {/* Simplified map illustration */}
                  <div className="absolute inset-0 flex items-center justify-center">
                    <div className="w-full px-12">
                      <div className="flex items-center justify-between">
                        <div className="w-4 h-4 rounded-full bg-[#2B4EFF] ring-4 ring-blue-200"></div>
                        <div className="flex-1 h-1 border-t-2 border-dashed border-blue-400 mx-4"></div>
                        <div className="w-4 h-4 rounded-full bg-[#FF6B35] ring-4 ring-orange-200"></div>
                      </div>
                    </div>
                  </div>
                  <div className="absolute top-4 left-4 bg-white px-3 py-1.5 rounded-lg shadow-sm">
                    <span className="text-sm font-bold text-gray-700">~710 km</span>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Continue Button */}
        <button
          disabled={!from || !to}
          className={`w-full py-4 rounded-xl font-bold text-lg flex items-center justify-center gap-2 transition-all ${
            from && to
              ? 'bg-[#2B4EFF] text-white hover:bg-[#1a3acc] shadow-lg hover:shadow-xl'
              : 'bg-gray-200 text-gray-400 cursor-not-allowed'
          }`}
        >
          Continuar
          <span className="text-xl">→</span>
        </button>
      </div>
    </div>
  );
}
