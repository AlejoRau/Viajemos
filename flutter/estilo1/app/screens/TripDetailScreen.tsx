import { ArrowLeft, Star, MapPin, Calendar, Clock, Users, DollarSign, MessageCircle, Phone } from "lucide-react";
import { Link, useParams } from "react-router";

export default function TripDetailScreen() {
  const { id } = useParams();

  const trip = {
    driver: {
      name: "Martín López",
      rating: 4.9,
      trips: 23,
      image: "https://i.pravatar.cc/150?img=11",
      verified: true,
    },
    origin: "Córdoba Capital",
    destination: "Buenos Aires",
    date: "28 de marzo",
    time: "08:00",
    seatsTotal: 4,
    seatsTaken: 1,
    price: 2500,
    description: "Viaje directo por autopista, salgo puntual. Acepto mascotas pequeñas.",
    passengers: [
      {
        id: 1,
        name: "Ana",
        image: "https://i.pravatar.cc/150?img=9",
      },
    ],
  };

  const seatsAvailable = trip.seatsTotal - trip.seatsTaken;

  return (
    <div className="min-h-screen bg-[#F9FAF7]">
      {/* Map Header */}
      <div className="relative h-[40vh] bg-gradient-to-br from-[#4CAF7D]/30 to-[#1B6B3A]/30">
        <Link
          to="/search"
          className="absolute top-12 left-6 z-10 bg-white/90 backdrop-blur-sm rounded-full p-2 shadow-lg"
        >
          <ArrowLeft className="w-6 h-6 text-gray-900" />
        </Link>
        
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="w-full px-12">
            <div className="h-2 bg-[#1B6B3A] rounded-full relative">
              <div className="absolute left-0 top-1/2 -translate-y-1/2 w-6 h-6 bg-[#1B6B3A] rounded-full border-4 border-white shadow-lg"></div>
              <div className="absolute right-0 top-1/2 -translate-y-1/2 w-6 h-6 bg-[#F4A228] rounded-full border-4 border-white shadow-lg"></div>
            </div>
          </div>
        </div>
      </div>

      <div className="px-6 -mt-8 pb-8">
        {/* Driver Card */}
        <div className="bg-white rounded-2xl shadow-lg p-5 mb-6">
          <div className="flex items-start gap-4 mb-4">
            <img
              src={trip.driver.image}
              alt={trip.driver.name}
              className="w-20 h-20 rounded-full border-4 border-[#4CAF7D]/20"
            />
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-1">
                <h2 className="text-xl font-semibold text-gray-900">
                  {trip.driver.name}
                </h2>
                {trip.driver.verified && (
                  <div className="w-5 h-5 bg-[#1B6B3A] rounded-full flex items-center justify-center">
                    <span className="text-white text-xs">✓</span>
                  </div>
                )}
              </div>
              <div className="flex items-center gap-3 text-sm">
                <div className="flex items-center gap-1">
                  <Star className="w-4 h-4 fill-[#F4A228] text-[#F4A228]" />
                  <span className="font-semibold">{trip.driver.rating}</span>
                </div>
                <span className="text-gray-400">•</span>
                <span className="text-gray-600">{trip.driver.trips} viajes</span>
              </div>
            </div>
            <div className="flex gap-2">
              <button className="w-10 h-10 rounded-full bg-[#4CAF7D]/10 flex items-center justify-center">
                <MessageCircle className="w-5 h-5 text-[#1B6B3A]" />
              </button>
              <button className="w-10 h-10 rounded-full bg-[#4CAF7D]/10 flex items-center justify-center">
                <Phone className="w-5 h-5 text-[#1B6B3A]" />
              </button>
            </div>
          </div>

          <p className="text-sm text-gray-600 bg-gray-50 rounded-xl p-3">
            {trip.description}
          </p>
        </div>

        {/* Trip Details */}
        <div className="bg-white rounded-2xl shadow-sm p-5 mb-6">
          <h3 className="font-semibold text-gray-900 mb-4">Detalles del viaje</h3>
          
          <div className="space-y-4">
            <div className="flex items-start gap-3">
              <MapPin className="w-5 h-5 text-[#1B6B3A] mt-0.5" />
              <div className="flex-1">
                <p className="text-sm text-gray-600 mb-1">Origen</p>
                <p className="font-semibold text-gray-900">{trip.origin}</p>
              </div>
            </div>

            <div className="w-0.5 h-8 bg-gray-300 ml-2"></div>

            <div className="flex items-start gap-3">
              <MapPin className="w-5 h-5 text-[#F4A228] mt-0.5" />
              <div className="flex-1">
                <p className="text-sm text-gray-600 mb-1">Destino</p>
                <p className="font-semibold text-gray-900">{trip.destination}</p>
              </div>
            </div>

            <div className="h-px bg-gray-100"></div>

            <div className="grid grid-cols-2 gap-4">
              <div className="flex items-center gap-3">
                <Calendar className="w-5 h-5 text-[#4CAF7D]" />
                <div>
                  <p className="text-xs text-gray-600">Fecha</p>
                  <p className="font-semibold text-gray-900 text-sm">
                    {trip.date}
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <Clock className="w-5 h-5 text-[#4CAF7D]" />
                <div>
                  <p className="text-xs text-gray-600">Hora</p>
                  <p className="font-semibold text-gray-900 text-sm">
                    {trip.time}
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <Users className="w-5 h-5 text-[#4CAF7D]" />
                <div>
                  <p className="text-xs text-gray-600">Asientos</p>
                  <p className="font-semibold text-gray-900 text-sm">
                    {seatsAvailable} disponibles
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-3">
                <DollarSign className="w-5 h-5 text-[#F4A228]" />
                <div>
                  <p className="text-xs text-gray-600">Precio</p>
                  <p className="font-semibold text-gray-900 text-sm">
                    ${trip.price}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Confirmed Passengers */}
        <div className="bg-white rounded-2xl shadow-sm p-5 mb-6">
          <h3 className="font-semibold text-gray-900 mb-4">
            Pasajeros confirmados ({trip.passengers.length})
          </h3>
          
          <div className="flex gap-3">
            {trip.passengers.map((passenger) => (
              <div key={passenger.id} className="flex flex-col items-center">
                <img
                  src={passenger.image}
                  alt={passenger.name}
                  className="w-14 h-14 rounded-full border-2 border-[#4CAF7D]"
                />
                <span className="text-xs text-gray-600 mt-2">
                  {passenger.name}
                </span>
              </div>
            ))}
            {Array.from({ length: seatsAvailable }).map((_, i) => (
              <div key={`empty-${i}`} className="flex flex-col items-center">
                <div className="w-14 h-14 rounded-full border-2 border-dashed border-gray-300 flex items-center justify-center">
                  <Users className="w-6 h-6 text-gray-300" />
                </div>
                <span className="text-xs text-gray-400 mt-2">Libre</span>
              </div>
            ))}
          </div>
        </div>

        {/* Request Button */}
        <button className="w-full bg-[#F4A228] text-white py-4 rounded-2xl font-semibold shadow-lg hover:bg-[#e09520] transition-colors">
          Pedir unirse al viaje
        </button>
      </div>
    </div>
  );
}
