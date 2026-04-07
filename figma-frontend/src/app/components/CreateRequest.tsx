import { useState } from "react";
import { useNavigate } from "react-router";
import { ArrowLeft, MapPin, Plus, X } from "lucide-react";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Switch } from "./ui/switch";
import { Textarea } from "./ui/textarea";
import { Button } from "./ui/button";

export function CreateRequest() {
  const navigate = useNavigate();
  const [stops, setStops] = useState<string[]>([]);
  const [newStop, setNewStop] = useState("");
  const [seats, setSeats] = useState(1);
  const [flexible, setFlexible] = useState(false);
  const [hasPet, setHasPet] = useState(false);
  const [isSmoker, setIsSmoker] = useState(false);

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
        <button onClick={() => navigate("/passenger")} className="p-1">
          <ArrowLeft className="w-6 h-6" />
        </button>
        <h1 className="text-xl font-semibold">Publicar pedido</h1>
      </div>

      {/* Scrollable Content */}
      <div className="px-6 py-6 pb-32 overflow-y-auto">
        <div className="max-w-md mx-auto space-y-6">
          {/* Route Section */}
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-800">Ruta deseada</h2>

            <div className="space-y-2">
              <Label htmlFor="origin">Origen</Label>
              <div className="relative">
                <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <Input id="origin" placeholder="Buenos Aires" className="pl-11 h-12 border-2" />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="destination">Destino</Label>
              <div className="relative">
                <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <Input id="destination" placeholder="Córdoba" className="pl-11 h-12 border-2" />
              </div>
            </div>

            <div className="space-y-2">
              <Label>Paradas deseadas (opcional)</Label>
              <div className="flex gap-2">
                <Input
                  placeholder="Agregar parada"
                  value={newStop}
                  onChange={(e) => setNewStop(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && addStop()}
                  className="h-12 border-2"
                />
                <Button onClick={addStop} size="icon" className="h-12 w-12 bg-[#1A73E8] hover:bg-[#1557b0]">
                  <Plus className="w-5 h-5" />
                </Button>
              </div>
              {stops.length > 0 && (
                <div className="flex flex-wrap gap-2 mt-2">
                  {stops.map((stop, index) => (
                    <div key={index} className="bg-[#E8F0FE] text-[#1A73E8] px-3 py-1.5 rounded-full flex items-center gap-2 text-sm">
                      <span>{stop}</span>
                      <button onClick={() => removeStop(index)}><X className="w-4 h-4" /></button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Date and Time Section */}
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-800">Fecha y horario</h2>

            <div className="space-y-2">
              <Label htmlFor="date">Fecha preferida</Label>
              <Input id="date" type="date" className="h-12 border-2" />
            </div>

            <div className="space-y-2">
              <Label htmlFor="time">Hora aproximada (opcional)</Label>
              <Input id="time" type="time" className="h-12 border-2" />
            </div>

            <div className="flex items-center justify-between py-3">
              <Label htmlFor="flexible" className="cursor-pointer">Soy flexible con el horario</Label>
              <Switch id="flexible" checked={flexible} onCheckedChange={setFlexible} />
            </div>
          </div>

          {/* Seats Section */}
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-800">Asientos</h2>

            <div className="space-y-2">
              <Label>Cantidad de asientos necesarios</Label>
              <div className="flex items-center gap-4">
                <Button onClick={() => setSeats(Math.max(1, seats - 1))} variant="outline" size="icon" className="h-12 w-12 border-2">-</Button>
                <span className="text-2xl font-semibold text-gray-800 w-12 text-center">{seats}</span>
                <Button onClick={() => setSeats(seats + 1)} variant="outline" size="icon" className="h-12 w-12 border-2">+</Button>
              </div>
            </div>
          </div>

          {/* Preferences Section */}
          <div className="space-y-4">
            <h2 className="text-lg font-semibold text-gray-800">Mis preferencias</h2>

            <div className="flex items-center justify-between py-3">
              <Label htmlFor="pet" className="cursor-pointer">Viajo con mascota</Label>
              <Switch id="pet" checked={hasPet} onCheckedChange={setHasPet} />
            </div>

            <div className="flex items-center justify-between py-3">
              <Label htmlFor="smoker" className="cursor-pointer">Soy fumador</Label>
              <Switch id="smoker" checked={isSmoker} onCheckedChange={setIsSmoker} />
            </div>
          </div>

          {/* Description Section */}
          <div className="space-y-2">
            <Label htmlFor="description">Descripción (opcional)</Label>
            <Textarea id="description" placeholder="Ej: Necesito llegar antes de las 18hs" className="min-h-24 border-2" />
          </div>
        </div>
      </div>

      {/* Fixed Bottom Button */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 px-6 py-4">
        <Button
          className="w-full h-14 bg-[#1A73E8] hover:bg-[#1557b0] text-lg font-semibold"
          onClick={() => {
            alert("¡Pedido publicado con éxito!");
            navigate("/passenger");
          }}
        >
          Publicar pedido
        </Button>
      </div>
    </div>
  );
}
