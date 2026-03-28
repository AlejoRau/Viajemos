import { Search, SlidersHorizontal, Star, ArrowRight, Users } from "lucide-react";
import { Link } from "react-router";
import BottomNav from "../components/BottomNav";

export default function SearchResultsScreen() {
  const trips = [
    {
      id: 1,
      driver: {
        name: "Martín López",
        rating: 4.9,
        image: "https://i.pravatar.cc/150?img=11",
      },
      origin: "Córdoba",
      destination: "Buenos Aires",
      time: "08:00",
      date: "Mañana",
      seatsTotal: 4,
      seatsTaken: 1,
      price: 2500,
    },
    {
      id: 2,
      driver: {
        name: "Laura Fernández",
        rating: 4.7,
        image: "https://i.pravatar.cc/150?img=20",
      },
      origin: "Córdoba",
      destination: "Buenos Aires",
      time: "10:30",
      date: "Mañana",
      seatsTotal: 3,
      seatsTaken: 0,
      price: 2800,
    },
    {
      id: 3,
      driver: {
        name: "Diego Romero",
        rating: 4.6,
        image: "https://i.pravatar.cc/150?img=14",
      },
      origin: "Córdoba",
      destination: "Buenos Aires",
      time: "14:00",
      date: "Mañana",
      seatsTotal: 4,
      seatsTaken: 2,
      price: 2300,
    },
  ];

  const filters = ["Hoy", "Precio ↑", "Con foto"];

  return (
    <div className="min-h-screen bg-[#F9FAF7] pb-20">
      {/* Header */}
      <div className="bg-[#1B6B3A] text-white px-6 pt-12 pb-6 sticky top-0 z-10">
        <h1 className="text-xl font-semibold mb-4">Buscar viajes</h1>
        
        {/* Search Bar */}
        <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-3 mb-4">
          <div className="flex items-center gap-3 text-white/90 mb-2">
            <Search className="w-5 h-5" />
            <input
              type="text"
              placeholder="Desde"
              className="flex-1 bg-transparent border-none outline-none placeholder-white/60"
              defaultValue="Córdoba"
            />
          </div>
          <div className="h-px bg-white/20 my-2"></div>
          <div className="flex items-center gap-3 text-white/90">
            <ArrowRight className="w-5 h-5" />
            <input
              type="text"
              placeholder="Hasta"
              className="flex-1 bg-transparent border-none outline-none placeholder-white/60"
              defaultValue="Buenos Aires"
            />
          </div>
        </div>

        {/* Filter Chips */}
        <div className="flex gap-2 overflow-x-auto pb-2 -mx-6 px-6">
          {filters.map((filter) => (
            <button
              key={filter}
              className="bg-white/20 backdrop-blur-sm text-white px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap hover:bg-white/30 transition-colors"
            >
              {filter}
            </button>
          ))}
          <button className="bg-white/20 backdrop-blur-sm text-white p-2 rounded-full hover:bg-white/30 transition-colors">
            <SlidersHorizontal className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Results */}
      <div className="px-6 py-6 space-y-4">
        {trips.map((trip) => {
          const seatsAvailable = trip.seatsTotal - trip.seatsTaken;
          
          return (
            <Link
              key={trip.id}
              to={`/trip/${trip.id}`}
              className="block bg-white rounded-2xl shadow-sm p-5 hover:shadow-md transition-shadow"
            >
              {/* Driver Info */}
              <div className="flex items-center gap-3 mb-4">
                <img
                  src={trip.driver.image}
                  alt={trip.driver.name}
                  className="w-12 h-12 rounded-full border-2 border-[#4CAF7D]/20"
                />
                <div className="flex-1">
                  <h3 className="font-semibold text-gray-900">
                    {trip.driver.name}
                  </h3>
                  <div className="flex items-center gap-1 text-sm">
                    <Star className="w-4 h-4 fill-[#F4A228] text-[#F4A228]" />
                    <span className="text-gray-600 font-medium">
                      {trip.driver.rating}
                    </span>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-2xl font-bold text-[#1B6B3A]">
                    ${trip.price}
                  </div>
                  <div className="text-xs text-gray-500">por asiento</div>
                </div>
              </div>

              {/* Route */}
              <div className="flex items-center gap-3 mb-4">
                <div className="flex-1">
                  <div className="flex items-center gap-3">
                    <div className="w-3 h-3 rounded-full bg-[#1B6B3A]"></div>
                    <span className="font-semibold text-gray-900">
                      {trip.origin}
                    </span>
                  </div>
                  <div className="w-0.5 h-8 bg-gray-300 ml-1.5 my-1"></div>
                  <div className="flex items-center gap-3">
                    <div className="w-3 h-3 rounded-full bg-[#F4A228]"></div>
                    <span className="font-semibold text-gray-900">
                      {trip.destination}
                    </span>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-sm text-gray-600">{trip.date}</div>
                  <div className="text-lg font-semibold text-gray-900">
                    {trip.time}
                  </div>
                </div>
              </div>

              {/* Seats */}
              <div className="flex items-center justify-between pt-4 border-t border-gray-100">
                <div className="flex items-center gap-2">
                  <Users className="w-4 h-4 text-gray-500" />
                  <span className="text-sm text-gray-600">
                    {seatsAvailable} {seatsAvailable === 1 ? 'asiento' : 'asientos'}
                  </span>
                </div>
                <div className="flex gap-1">
                  {Array.from({ length: trip.seatsTotal }).map((_, i) => (
                    <div
                      key={i}
                      className={`w-2.5 h-2.5 rounded-full ${
                        i < trip.seatsTaken ? "bg-gray-400" : "bg-[#4CAF7D]"
                      }`}
                    />
                  ))}
                </div>
                <button className="bg-[#1B6B3A] text-white px-4 py-2 rounded-xl text-sm font-semibold hover:bg-[#155a30] transition-colors">
                  Ver viaje
                </button>
              </div>
            </Link>
          );
        })}
      </div>

      <BottomNav />
    </div>
  );
}
