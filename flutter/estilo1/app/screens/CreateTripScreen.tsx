import { useState } from "react";
import { MapPin, Calendar, Clock, Users, DollarSign, ArrowLeft, Minus, Plus } from "lucide-react";
import { Link, useNavigate } from "react-router";

export default function CreateTripScreen() {
  const navigate = useNavigate();
  const [seats, setSeats] = useState(3);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    navigate("/");
  };

  return (
    <div className="min-h-screen bg-[#F9FAF7] pb-8">
      {/* Header */}
      <div className="bg-[#1B6B3A] text-white px-6 pt-12 pb-6 sticky top-0 z-10">
        <div className="flex items-center gap-4 mb-2">
          <Link to="/" className="p-2 -ml-2">
            <ArrowLeft className="w-6 h-6" />
          </Link>
          <h1 className="text-xl font-semibold">Publicar viaje</h1>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="px-6 -mt-2">
        {/* Map Preview */}
        <div className="bg-white rounded-2xl shadow-lg p-4 mb-6">
          <div className="bg-gradient-to-br from-[#4CAF7D]/20 to-[#1B6B3A]/20 rounded-xl h-48 flex items-center justify-center relative overflow-hidden">
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="w-full px-8">
                <div className="h-1 bg-[#1B6B3A] rounded-full relative">
                  <div className="absolute left-0 top-1/2 -translate-y-1/2 w-4 h-4 bg-[#1B6B3A] rounded-full"></div>
                  <div className="absolute right-0 top-1/2 -translate-y-1/2 w-4 h-4 bg-[#F4A228] rounded-full"></div>
                </div>
              </div>
            </div>
            <MapPin className="w-12 h-12 text-[#1B6B3A]/30" />
          </div>
        </div>

        {/* Form Fields */}
        <div className="space-y-4">
          {/* Origin */}
          <div className="bg-white rounded-2xl shadow-sm p-4">
            <label className="flex items-center gap-3">
              <MapPin className="w-5 h-5 text-[#1B6B3A]" />
              <input
                type="text"
                placeholder="Origen"
                className="flex-1 bg-transparent border-none outline-none text-gray-900 placeholder-gray-400"
                defaultValue="Córdoba"
              />
            </label>
          </div>

          {/* Destination */}
          <div className="bg-white rounded-2xl shadow-sm p-4">
            <label className="flex items-center gap-3">
              <MapPin className="w-5 h-5 text-[#F4A228]" />
              <input
                type="text"
                placeholder="Destino"
                className="flex-1 bg-transparent border-none outline-none text-gray-900 placeholder-gray-400"
                defaultValue="Buenos Aires"
              />
            </label>
          </div>

          {/* Date and Time */}
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-white rounded-2xl shadow-sm p-4">
              <label className="flex items-center gap-3">
                <Calendar className="w-5 h-5 text-[#4CAF7D]" />
                <input
                  type="date"
                  className="flex-1 bg-transparent border-none outline-none text-gray-900 text-sm"
                  defaultValue="2026-03-28"
                />
              </label>
            </div>

            <div className="bg-white rounded-2xl shadow-sm p-4">
              <label className="flex items-center gap-3">
                <Clock className="w-5 h-5 text-[#4CAF7D]" />
                <input
                  type="time"
                  className="flex-1 bg-transparent border-none outline-none text-gray-900 text-sm"
                  defaultValue="08:00"
                />
              </label>
            </div>
          </div>

          {/* Seats Selector */}
          <div className="bg-white rounded-2xl shadow-sm p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Users className="w-5 h-5 text-[#4CAF7D]" />
                <span className="text-gray-900">Asientos disponibles</span>
              </div>
              <div className="flex items-center gap-4">
                <button
                  type="button"
                  onClick={() => setSeats(Math.max(1, seats - 1))}
                  className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center"
                >
                  <Minus className="w-4 h-4 text-gray-600" />
                </button>
                <span className="text-lg font-semibold text-gray-900 w-8 text-center">
                  {seats}
                </span>
                <button
                  type="button"
                  onClick={() => setSeats(Math.min(8, seats + 1))}
                  className="w-8 h-8 rounded-full bg-[#1B6B3A] flex items-center justify-center"
                >
                  <Plus className="w-4 h-4 text-white" />
                </button>
              </div>
            </div>
          </div>

          {/* Price */}
          <div className="bg-white rounded-2xl shadow-sm p-4">
            <label className="flex items-center gap-3">
              <DollarSign className="w-5 h-5 text-[#F4A228]" />
              <input
                type="number"
                placeholder="Precio por asiento"
                className="flex-1 bg-transparent border-none outline-none text-gray-900 placeholder-gray-400"
                defaultValue="2500"
              />
            </label>
          </div>

          {/* Comment */}
          <div className="bg-white rounded-2xl shadow-sm p-4">
            <textarea
              placeholder="Comentario (opcional)"
              rows={4}
              className="w-full bg-transparent border-none outline-none text-gray-900 placeholder-gray-400 resize-none"
              defaultValue="Salgo temprano, viaje directo sin paradas."
            />
          </div>
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          className="w-full bg-[#1B6B3A] text-white py-4 rounded-2xl font-semibold mt-8 shadow-lg"
        >
          Publicar viaje
        </button>
      </form>
    </div>
  );
}
