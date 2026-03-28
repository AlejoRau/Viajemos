import { Link, useParams } from "react-router";
import { ArrowLeft, Star, Clock, Users, DollarSign, Shield, MessageCircle } from "lucide-react";
import { mockTrips } from "../data/mockData";

export function TripDetailScreen() {
  const { id } = useParams();
  const trip = mockTrips.find(t => t.id === id) || mockTrips[0];

  const filledSeats = trip.totalSeats - trip.availableSeats;
  const remainingPassengers = trip.passengers.length - 2;

  return (
    <div className="min-h-screen bg-[#F0F4FF]">
      {/* Header with Driver Photo */}
      <div className="relative">
        {/* Driver Hero Image */}
        <div className="relative h-80">
          <img
            src={trip.driver.avatar}
            alt={trip.driver.name}
            className="w-full h-full object-cover"
          />
          {/* Gradient Overlay */}
          <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-black/60"></div>
          
          {/* Back Button */}
          <Link
            to="/buscar"
            className="absolute top-6 left-6 w-10 h-10 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center shadow-lg hover:bg-white transition-colors"
          >
            <ArrowLeft className="w-5 h-5 text-gray-700" />
          </Link>

          {/* Route Badge */}
          <div className="absolute bottom-6 left-6 right-6">
            <div className="bg-white/95 backdrop-blur-sm rounded-2xl px-5 py-3 shadow-xl">
              <div className="flex items-center gap-3">
                <div className="flex items-center gap-2 flex-1">
                  <div className="w-3 h-3 rounded-full bg-[#2B4EFF]"></div>
                  <span className="font-bold text-lg text-gray-900">
                    {trip.from}
                  </span>
                </div>
                <span className="text-gray-400 font-bold text-xl">→</span>
                <div className="flex items-center gap-2 flex-1">
                  <div className="w-3 h-3 rounded-full bg-[#FF6B35]"></div>
                  <span className="font-bold text-lg text-gray-900">
                    {trip.to}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Content Sheet */}
      <div className="max-w-md mx-auto">
        <div className="bg-white rounded-t-[32px] -mt-6 relative z-10 shadow-2xl">
          <div className="px-6 py-6 space-y-6">
            {/* Driver Info Row */}
            <div className="flex items-center justify-between pb-6 border-b border-gray-100">
              <div className="flex items-center gap-3">
                <img
                  src={trip.driver.avatar}
                  alt={trip.driver.name}
                  className="w-16 h-16 rounded-full object-cover ring-4 ring-white shadow-lg -mt-12"
                />
                <div>
                  <h2 className="text-2xl font-extrabold text-gray-900">
                    {trip.driver.name}
                  </h2>
                  <div className="flex items-center gap-2 text-sm">
                    <div className="flex items-center gap-1">
                      <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
                      <span className="font-bold text-gray-700">{trip.driver.rating}</span>
                    </div>
                    <span className="text-gray-400">·</span>
                    <span className="text-gray-600">{trip.driver.tripCount} viajes</span>
                  </div>
                </div>
              </div>

              {/* Badges */}
              <div className="flex gap-2">
                <div className="w-10 h-10 bg-blue-50 rounded-full flex items-center justify-center">
                  <Shield className="w-5 h-5 text-[#2B4EFF]" />
                </div>
                <div className="w-10 h-10 bg-green-50 rounded-full flex items-center justify-center">
                  <span className="text-lg">✓</span>
                </div>
              </div>
            </div>

            {/* Trip Stats Grid */}
            <div className="grid grid-cols-3 gap-4">
              <div className="bg-blue-50 rounded-2xl p-4 text-center">
                <Clock className="w-6 h-6 text-[#2B4EFF] mx-auto mb-2" />
                <div className="text-sm text-gray-600 mb-1">Hora</div>
                <div className="font-extrabold text-lg text-gray-900">
                  {trip.time}
                </div>
              </div>

              <div className="bg-orange-50 rounded-2xl p-4 text-center">
                <Users className="w-6 h-6 text-[#FF6B35] mx-auto mb-2" />
                <div className="text-sm text-gray-600 mb-1">Plazas</div>
                <div className="font-extrabold text-lg text-gray-900">
                  {trip.availableSeats}/{trip.totalSeats}
                </div>
              </div>

              <div className="bg-green-50 rounded-2xl p-4 text-center">
                <DollarSign className="w-6 h-6 text-[#10B981] mx-auto mb-2" />
                <div className="text-sm text-gray-600 mb-1">Precio</div>
                <div className="font-extrabold text-lg text-gray-900">
                  ${trip.price}
                </div>
              </div>
            </div>

            {/* Passengers Section */}
            {trip.passengers.length > 0 && (
              <div>
                <h3 className="font-bold text-gray-900 mb-3">
                  Pasajeros confirmados
                </h3>
                <div className="flex items-center gap-2">
                  {trip.passengers.slice(0, 3).map((passenger, index) => (
                    <img
                      key={passenger.id}
                      src={passenger.avatar}
                      alt={passenger.name}
                      className="w-12 h-12 rounded-full object-cover ring-2 ring-white shadow-md"
                      style={{ marginLeft: index > 0 ? "-8px" : "0" }}
                    />
                  ))}
                  {remainingPassengers > 0 && (
                    <div className="w-12 h-12 rounded-full bg-gray-200 flex items-center justify-center font-bold text-sm text-gray-700 -ml-2 ring-2 ring-white shadow-md">
                      +{remainingPassengers}
                    </div>
                  )}
                </div>
              </div>
            )}

            {/* Trip Info */}
            <div className="bg-gray-50 rounded-2xl p-4">
              <h3 className="font-bold text-gray-900 mb-2">
                Información del viaje
              </h3>
              <div className="space-y-2 text-sm text-gray-600">
                <div className="flex justify-between">
                  <span>Fecha de salida:</span>
                  <span className="font-semibold text-gray-900">
                    {new Date(trip.date).toLocaleDateString('es-AR', { 
                      weekday: 'long', 
                      year: 'numeric', 
                      month: 'long', 
                      day: 'numeric' 
                    })}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span>Duración aprox:</span>
                  <span className="font-semibold text-gray-900">8-9 horas</span>
                </div>
                <div className="flex justify-between">
                  <span>Distancia:</span>
                  <span className="font-semibold text-gray-900">~710 km</span>
                </div>
              </div>
            </div>

            {/* About Driver */}
            <div className="bg-blue-50 rounded-2xl p-4">
              <h3 className="font-bold text-gray-900 mb-2">
                Sobre el conductor
              </h3>
              <p className="text-sm text-gray-700">
                Conductor verificado con más de {trip.driver.tripCount} viajes completados exitosamente. 
                Me gusta la música tranquila y hacer paradas cada 2 horas.
              </p>
            </div>
          </div>
        </div>

        {/* Sticky Bottom Bar */}
        <div className="bg-white border-t border-gray-200 shadow-2xl">
          <div className="max-w-md mx-auto px-6 py-4">
            <div className="flex items-center justify-between gap-4">
              <div>
                <div className="text-sm text-gray-600">Precio por persona</div>
                <div className="text-3xl font-extrabold text-[#2B4EFF]">
                  ${trip.price}
                </div>
              </div>

              <div className="flex gap-2">
                <button className="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center hover:bg-blue-100 transition-colors">
                  <MessageCircle className="w-5 h-5 text-[#2B4EFF]" />
                </button>
                <button className="bg-[#2B4EFF] text-white font-bold px-8 py-3 rounded-xl hover:bg-[#1a3acc] transition-colors shadow-lg">
                  Solicitar unirse
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
