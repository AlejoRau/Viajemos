import { useState } from "react";
import { useNavigate } from "react-router";
import { ArrowLeft, Users, PawPrint, Cigarette } from "lucide-react";
import { Label } from "./ui/label";
import { Slider } from "./ui/slider";
import { Input } from "./ui/input";
import { Button } from "./ui/button";

interface PassengerRequest {
  id: string;
  name: string;
  origin: string;
  destination: string;
  date: string;
  seats: number;
  pets: boolean;
  smoker: boolean;
}

const mockRequests: PassengerRequest[] = [
  {
    id: "1",
    name: "María González",
    origin: "Rosario",
    destination: "Buenos Aires",
    date: "2026-04-05",
    seats: 2,
    pets: true,
    smoker: false,
  },
  {
    id: "2",
    name: "Juan Pérez",
    origin: "Mendoza",
    destination: "San Juan",
    date: "2026-04-10",
    seats: 1,
    pets: false,
    smoker: false,
  },
  {
    id: "3",
    name: "Sofía Martínez",
    origin: "Córdoba",
    destination: "Buenos Aires",
    date: "2026-04-08",
    seats: 3,
    pets: false,
    smoker: true,
  },
];

export function PassengerRequests() {
  const navigate = useNavigate();
  const [radius, setRadius] = useState([100]);
  const [filterDate, setFilterDate] = useState("");

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <div className="bg-[#1A73E8] text-white px-6 py-4 flex items-center gap-4 shadow-md">
        <button onClick={() => navigate("/driver")} className="p-1">
          <ArrowLeft className="w-6 h-6" />
        </button>
        <h1 className="text-xl font-semibold">Pedidos de pasajeros</h1>
      </div>

      {/* Filters */}
      <div className="px-6 py-6 bg-gray-50 border-b border-gray-200 space-y-4">
        <div className="space-y-2">
          <Label>Radio de búsqueda: {radius[0]} km</Label>
          <Slider
            value={radius}
            onValueChange={setRadius}
            min={10}
            max={500}
            step={10}
            className="w-full"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="filterDate">Fecha</Label>
          <Input
            id="filterDate"
            type="date"
            value={filterDate}
            onChange={(e) => setFilterDate(e.target.value)}
            className="h-12 border-2"
          />
        </div>
      </div>

      {/* Results List */}
      <div className="px-6 py-6 space-y-4">
        {mockRequests.map((request) => (
          <div
            key={request.id}
            className="bg-white border-2 border-gray-200 rounded-2xl p-5 shadow-sm hover:shadow-md transition-shadow"
          >
            <div className="space-y-3">
              {/* Passenger Name */}
              <div className="flex items-center gap-2">
                <div className="w-10 h-10 bg-[#E8F0FE] rounded-full flex items-center justify-center">
                  <span className="text-[#1A73E8] font-semibold text-sm">
                    {request.name.charAt(0)}
                  </span>
                </div>
                <span className="font-semibold text-gray-800">{request.name}</span>
              </div>

              {/* Route */}
              <div className="flex items-center gap-2 text-gray-700">
                <span className="font-medium">{request.origin}</span>
                <span className="text-[#1A73E8]">→</span>
                <span className="font-medium">{request.destination}</span>
              </div>

              {/* Date and Seats */}
              <div className="flex items-center gap-4 text-sm text-gray-600">
                <span>📅 {new Date(request.date).toLocaleDateString("es-AR")}</span>
                <div className="flex items-center gap-1">
                  <Users className="w-4 h-4" />
                  <span>{request.seats} asiento{request.seats > 1 ? "s" : ""}</span>
                </div>
              </div>

              {/* Preferences */}
              {(request.pets || request.smoker) && (
                <div className="flex gap-2">
                  {request.pets && (
                    <div className="bg-green-100 text-green-700 px-3 py-1 rounded-full flex items-center gap-1 text-xs">
                      <PawPrint className="w-3 h-3" />
                      <span>Mascota</span>
                    </div>
                  )}
                  {request.smoker && (
                    <div className="bg-orange-100 text-orange-700 px-3 py-1 rounded-full flex items-center gap-1 text-xs">
                      <Cigarette className="w-3 h-3" />
                      <span>Fumador</span>
                    </div>
                  )}
                </div>
              )}

              {/* Action Button */}
              <Button
                className="w-full bg-[#1A73E8] hover:bg-[#1557b0] mt-2"
                onClick={() => alert(`Ofreciendo viaje a ${request.name}`)}
              >
                Ofrecer viaje
              </Button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
