import { useState } from "react";
import { useNavigate } from "react-router";
import { ArrowLeft, MapPin, Plus, X } from "lucide-react";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Switch } from "./ui/switch";
import { Textarea } from "./ui/textarea";
import { Button } from "./ui/button";

export function CreateTrip() {
  const navigate = useNavigate();
  const [stops, setStops] = useState<string[]>([]);
  const [newStop, setNewStop] = useState("");
  const [seats, setSeats] = useState(1);
  const [acceptsPets, setAcceptsPets] = useState(false);
  const [acceptsSmokers, setAcceptsSmokers] = useState(false);

  const addStop = () => {
    if (newStop.trim()) {
      setStops([...stops, newStop.trim()]);
      setNewStop("");
    }
  };

  const removeStop = (index: number) => {
    setStops(stops.filter((_, i) => i !== index));
  };

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <div className="bg-[#1A73E8] text-white px-6 py-4 flex items-center gap-4 shadow-md">
        <button onClick={() => navigate("/driver")} className="p-1">
          <ArrowLeft className="w-6 h-6" />
        </button>
        <h1 className="text-xl font-semibold">Crear un viaje</h1>
      </div>

      {/* Scrollable Content */}
      <div className="px-6 py-6 pb-32 overflow-y-auto">
        <div className="max-w-md mx-auto space-y-6">
          {/* Route Section */}
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-800">Ruta</h2>

            <div className="space-y-2">
              <Label htmlFor="origin">Origen</Label>
              <div className="relative">
                <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <Input
                  id="origin"
                  placeholder="Buenos Aires"
                  className="pl-11 h-12 border-2"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="destination">Destino</Label>
              <div className="relative">
                <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <Input
                  id="destination"
                  placeholder="Córdoba"
                  className="pl-11 h-12 border-2"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label>Paradas intermedias</Label>
              <div className="flex gap-2">
                <Input
                  placeholder="Agregar parada"
                  value={newStop}
                  onChange={(e) => setNewStop(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && addStop()}
                  className="h-12 border-2"
                />
                <Button
                  onClick={addStop}
                  size="icon"
                  className="h-12 w-12 bg-[#1A73E8] hover:bg-[#1557b0]"
                >
                  <Plus className="w-5 h-5" />
                </Button>
              </div>
              {stops.length > 0 && (
                <div className="flex flex-wrap gap-2 mt-2">
                  {stops.map((stop, index) => (
                    <div
                      key={index}
                      className="bg-[#E8F0FE] text-[#1A73E8] px-3 py-1.5 rounded-full flex items-center gap-2 text-sm"
                    >
                      <span>{stop}</span>
                      <button onClick={() => removeStop(index)}>
                        <X className="w-4 h-4" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Date and Time Section */}
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-800">Fecha y hora</h2>

            <div className="space-y-2">
              <Label htmlFor="date">Fecha de salida</Label>
              <Input id="date" type="date" className="h-12 border-2" />
            </div>

            <div className="space-y-2">
              <Label htmlFor="time">Hora de salida</Label>
              <Input id="time" type="time" className="h-12 border-2" />
            </div>
          </div>

          {/* Seats and Price Section */}
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-800">Asientos y precio</h2>

            <div className="space-y-2">
              <Label htmlFor="seats">Asientos disponibles</Label>
              <div className="flex items-center gap-4">
                <Button
                  onClick={() => setSeats(Math.max(1, seats - 1))}
                  variant="outline"
                  size="icon"
                  className="h-12 w-12 border-2"
                >
                  -
                </Button>
                <span className="text-2xl font-semibold text-gray-800 w-12 text-center">
                  {seats}
                </span>
                <Button
                  onClick={() => setSeats(seats + 1)}
                  variant="outline"
                  size="icon"
                  className="h-12 w-12 border-2"
                >
                  +
                </Button>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="price">Precio por asiento (ARS)</Label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-600 font-semibold">
                  $
                </span>
                <Input
                  id="price"
                  type="number"
                  placeholder="5000"
                  className="pl-8 h-12 border-2"
                />
              </div>
            </div>
          </div>

          {/* Preferences Section */}
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-800">Preferencias del conductor</h2>

            <div className="flex items-center justify-between py-3">
              <Label htmlFor="pets" className="cursor-pointer">
                Acepta mascotas
              </Label>
              <Switch id="pets" checked={acceptsPets} onCheckedChange={setAcceptsPets} />
            </div>

            <div className="flex items-center justify-between py-3">
              <Label htmlFor="smokers" className="cursor-pointer">
                Acepta fumadores
              </Label>
              <Switch id="smokers" checked={acceptsSmokers} onCheckedChange={setAcceptsSmokers} />
            </div>
          </div>

          {/* Description Section */}
          <div className="space-y-2">
            <Label htmlFor="description">Descripción (opcional)</Label>
            <Textarea
              id="description"
              placeholder="Información adicional sobre el viaje..."
              className="min-h-24 border-2"
            />
          </div>
        </div>
      </div>

      {/* Fixed Bottom Button */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 px-6 py-4">
        <Button
          className="w-full h-14 bg-[#1A73E8] hover:bg-[#1557b0] text-lg font-semibold"
          onClick={() => {
            alert("¡Viaje publicado con éxito!");
            navigate("/driver");
          }}
        >
          Publicar viaje
        </Button>
      </div>
    </div>
  );
}
