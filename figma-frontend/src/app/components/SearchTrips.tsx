import { useState } from "react";
import { useNavigate } from "react-router";
import { ArrowLeft, Star, PawPrint, Cigarette, MapPin } from "lucide-react";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Slider } from "./ui/slider";
import { Button } from "./ui/button";

interface Participant {
  name: string;
}

interface Trip {
  id: string;
  driverName: string;
  rating: number;
  origin: string;
  destination: string;
  stops: number;
  date: string;
  time: string;
  totalSeats: number;
  availableSeats: number;
  participants: Participant[];
  pricePerSeat: number;
  acceptsPets: boolean;
  acceptsSmokers: boolean;
}

const mockTrips: Trip[] = [
  {
    id: "1",
    driverName: "Carlos Rodríguez",
    rating: 4.8,
    origin: "Buenos Aires",
    destination: "Córdoba",
    stops: 2,
    date: "2026-04-05",
    time: "08:00",
    totalSeats: 4,
    availableSeats: 2,
    participants: [{ name: "Carlos Rodríguez" }, { name: "María G." }],
    pricePerSeat: 6500,
    acceptsPets: true,
    acceptsSmokers: false,
  },
  {
    id: "2",
    driverName: "Ana López",
    rating: 4.9,
    origin: "Rosario",
    destination: "Buenos Aires",
    stops: 0,
    date: "2026-04-06",
    time: "14:30",
    totalSeats: 3,
    availableSeats: 2,
    participants: [{ name: "Ana López" }],
    pricePerSeat: 4000,
    acceptsPets: false,
    acceptsSmokers: false,
  },
  {
    id: "3",
    driverName: "Diego Fernández",
    rating: 4.7,
    origin: "Mendoza",
    destination: "San Luis",
    stops: 1,
    date: "2026-04-08",
    time: "10:00",
    totalSeats: 5,
    availableSeats: 3,
    participants: [{ name: "Diego Fernández" }, { name: "Laura M." }],
    pricePerSeat: 5500,
    acceptsPets: true,
    acceptsSmokers: true,
  },
];

export function SearchTrips() {
  const navigate = useNavigate();
  const [originRadius, setOriginRadius] = useState([50]);
  const [destinationRadius, setDestinationRadius] = useState([50]);
  const [seatsNeeded, setSeatsNeeded] = useState(1);
  const [showResults, setShowResults] = useState(false);

  const getInitials = (name: string) => {
    const parts = name.split(" ");
    if (parts.length >= 2) return parts[0][0] + parts[1][0];
    return name.substring(0, 2).toUpperCase();
  };

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <div className="bg-[#1A73E8] text-white px-6 py-4 flex items-center gap-4 shadow-md">
        <button onClick={() => navigate("/passenger")} className="p-1">
          <ArrowLeft className="w-6 h-6" />
        </button>
        <h1 className="text-xl font-semibold">Buscar viajes</h1>
      </div>

      {/* Search Form */}
      <div className="px-6 py-6 bg-gray-50 border-b border-gray-200 space-y-5">
        <div className="space-y-2">
          <Label htmlFor="searchOrigin" className="flex items-center gap-1">
            Origen <span className="text-red-500">*</span>
          </Label>
          <div className="relative">
            <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <Input id="searchOrigin" placeholder="Buenos Aires" required className="pl-11 h-12 border-2" />
          </div>
        </div>

        <div className="space-y-2">
          <Label>Radio de búsqueda (origen): {originRadius[0]} km</Label>
          <Slider value={originRadius} onValueChange={setOriginRadius} min={10} max={500} step={10} className="w-full" />
        </div>

        <div className="space-y-2">
          <Label htmlFor="searchDestination">Destino (opcional)</Label>
          <div className="relative">
            <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <Input id="searchDestination" placeholder="Córdoba" className="pl-11 h-12 border-2" />
          </div>
        </div>

        <div className="space-y-2">
          <Label>Radio de búsqueda (destino): {destinationRadius[0]} km</Label>
          <Slider value={destinationRadius} onValueChange={setDestinationRadius} min={10} max={500} step={10} className="w-full" />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div className="space-y-2">
            <Label htmlFor="dateFrom">Fecha desde</Label>
            <Input id="dateFrom" type="date" className="h-12 border-2" />
          </div>
          <div className="space-y-2">
            <Label htmlFor="dateTo">Fecha hasta</Label>
            <Input id="dateTo" type="date" className="h-12 border-2" />
          </div>
        </div>

        <div className="space-y-2">
          <Label>Cantidad de lugares que busco</Label>
          <div className="flex items-center gap-4">
            <Button onClick={() => setSeatsNeeded(Math.max(1, seatsNeeded - 1))} variant="outline" size="icon" className="h-12 w-12 border-2">-</Button>
            <span className="text-2xl font-semibold text-gray-800 w-12 text-center">{seatsNeeded}</span>
            <Button onClick={() => setSeatsNeeded(seatsNeeded + 1)} variant="outline" size="icon" className="h-12 w-12 border-2">+</Button>
          </div>
        </div>

        <Button className="w-full h-12 bg-[#1A73E8] hover:bg-[#1557b0] text-base font-semibold" onClick={() => setShowResults(true)}>
          Buscar
        </Button>
      </div>

      {/* Results List */}
      {showResults && (
        <div className="px-6 py-6 space-y-4">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">
            Viajes disponibles ({mockTrips.length})
          </h2>

          {mockTrips.map((trip) => (
            <div key={trip.id} className="bg-white border-2 border-gray-200 rounded-2xl p-5 shadow-sm hover:shadow-md transition-shadow">
              <div className="space-y-3">
                {/* Driver Info */}
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-[#E8F0FE] rounded-full flex items-center justify-center">
                    <span className="text-[#1A73E8] font-semibold text-sm">{getInitials(trip.driverName)}</span>
                  </div>
                  <div className="flex-1">
                    <div className="font-semibold text-gray-800">{trip.driverName}</div>
                    <div className="flex items-center gap-1 text-sm text-gray-600">
                      <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                      <span>{trip.rating}</span>
                    </div>
                  </div>
                </div>

                {/* Route */}
                <div className="flex items-center gap-2 text-gray-700">
                  <span className="font-medium">{trip.origin}</span>
                  <span className="text-[#1A73E8]">→</span>
                  <span className="font-medium">{trip.destination}</span>
                  {trip.stops > 0 && (
                    <span className="bg-[#E8F0FE] text-[#1A73E8] px-2 py-0.5 rounded-full text-xs">
                      {trip.stops} parada{trip.stops > 1 ? "s" : ""}
                    </span>
                  )}
                </div>

                {/* Date & Time */}
                <div className="text-sm text-gray-600">
                  📅 {new Date(trip.date).toLocaleDateString("es-AR")} • 🕐 {trip.time}
                </div>

                {/* Participants */}
                <div className="flex items-center gap-2">
                  <span className="text-sm text-gray-600">Viajeros:</span>
                  <div className="flex -space-x-2">
                    {trip.participants.map((p, idx) => (
                      <div key={idx} className="w-8 h-8 bg-[#1A73E8] text-white rounded-full flex items-center justify-center text-xs font-semibold border-2 border-white" title={p.name}>
                        {getInitials(p.name)}
                      </div>
                    ))}
                    {Array.from({ length: trip.availableSeats }).map((_, idx) => (
                      <div key={`empty-${idx}`} className="w-8 h-8 bg-gray-200 rounded-full border-2 border-white" title="Lugar disponible" />
                    ))}
                  </div>
                  <span className="text-xs text-gray-500 ml-1">{trip.availableSeats}/{trip.totalSeats} disponibles</span>
                </div>

                {/* Price */}
                <div className="text-lg font-bold text-[#1A73E8]">
                  ${trip.pricePerSeat.toLocaleString("es-AR")}
                </div>

                {/* Preferences */}
                {(trip.acceptsPets || trip.acceptsSmokers) && (
                  <div className="flex gap-2">
                    {trip.acceptsPets && (
                      <div className="bg-green-100 text-green-700 px-3 py-1 rounded-full flex items-center gap-1 text-xs">
                        <PawPrint className="w-3 h-3" /><span>Mascotas</span>
                      </div>
                    )}
                    {trip.acceptsSmokers && (
                      <div className="bg-orange-100 text-orange-700 px-3 py-1 rounded-full flex items-center gap-1 text-xs">
                        <Cigarette className="w-3 h-3" /><span>Fumadores</span>
                      </div>
                    )}
                  </div>
                )}

                <Button className="w-full bg-[#1A73E8] hover:bg-[#1557b0] mt-2" onClick={() => alert(`Ver detalles del viaje con ${trip.driverName}`)}>
                  Ver detalles
                </Button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
