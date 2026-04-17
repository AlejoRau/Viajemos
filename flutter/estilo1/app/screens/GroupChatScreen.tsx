import { ArrowLeft, Send, MessageCircle } from "lucide-react";
import { Link } from "react-router";
import { useState } from "react";

export default function GroupChatScreen() {
  const [message, setMessage] = useState("");

  const messages = [
    {
      id: 1,
      sender: "Martín López",
      text: "¡Hola a todos! Nos vemos mañana a las 8 en punto.",
      time: "10:30",
      isOwn: false,
      avatar: "https://i.pravatar.cc/150?img=11",
    },
    {
      id: 2,
      sender: "Tú",
      text: "Perfecto, estaré listo. ¿Pasás a buscarme por el centro?",
      time: "10:32",
      isOwn: true,
      avatar: "https://i.pravatar.cc/150?img=33",
    },
    {
      id: 3,
      sender: "Ana García",
      text: "Yo también! Voy con una valija pequeña, hay espacio?",
      time: "10:35",
      isOwn: false,
      avatar: "https://i.pravatar.cc/150?img=9",
    },
    {
      id: 4,
      sender: "Martín López",
      text: "Sí, no hay problema. Puedo pasar por el centro sin drama.",
      time: "10:38",
      isOwn: false,
      avatar: "https://i.pravatar.cc/150?img=11",
    },
    {
      id: 5,
      sender: "Tú",
      text: "Genial, nos vemos entonces 👍",
      time: "10:40",
      isOwn: true,
      avatar: "https://i.pravatar.cc/150?img=33",
    },
  ];

  const participants = [
    { name: "Martín López", avatar: "https://i.pravatar.cc/150?img=11" },
    { name: "Ana García", avatar: "https://i.pravatar.cc/150?img=9" },
    { name: "Tú", avatar: "https://i.pravatar.cc/150?img=33" },
  ];

  const handleSend = () => {
    if (message.trim()) {
      // Handle send logic here
      setMessage("");
    }
  };

  return (
    <div className="min-h-screen bg-[#F9FAF7] flex flex-col">
      {/* Header */}
      <div className="bg-[#1B6B3A] text-white px-6 pt-12 pb-4 sticky top-0 z-10">
        <div className="flex items-center gap-4 mb-3">
          <Link to="/" className="p-2 -ml-2">
            <ArrowLeft className="w-6 h-6" />
          </Link>
          <div className="flex-1">
            <h1 className="text-lg font-semibold">Viaje Córdoba - Buenos Aires</h1>
            <p className="text-white/80 text-xs">{participants.length} participantes</p>
          </div>
        </div>

        {/* Participants Avatars */}
        <div className="flex gap-2 items-center pb-2">
          {participants.map((participant, index) => (
            <img
              key={index}
              src={participant.avatar}
              alt={participant.name}
              className="w-8 h-8 rounded-full border-2 border-white/20"
              style={{ marginLeft: index > 0 ? "-8px" : "0" }}
            />
          ))}
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 px-6 py-4 space-y-4 overflow-y-auto pb-32">
        {messages.map((msg) => (
          <div
            key={msg.id}
            className={`flex gap-3 ${msg.isOwn ? "flex-row-reverse" : ""}`}
          >
            <img
              src={msg.avatar}
              alt={msg.sender}
              className="w-10 h-10 rounded-full flex-shrink-0"
            />
            <div className={`flex-1 ${msg.isOwn ? "items-end" : ""}`}>
              {!msg.isOwn && (
                <p className="text-xs text-gray-600 mb-1 font-medium">
                  {msg.sender}
                </p>
              )}
              <div
                className={`rounded-2xl px-4 py-3 inline-block max-w-[80%] ${
                  msg.isOwn
                    ? "bg-[#4CAF7D] text-white rounded-br-sm"
                    : "bg-white text-gray-900 rounded-bl-sm shadow-sm"
                }`}
              >
                <p className="text-sm">{msg.text}</p>
              </div>
              <p className="text-xs text-gray-500 mt-1">{msg.time}</p>
            </div>
          </div>
        ))}
      </div>

      {/* WhatsApp Banner */}
      <div className="px-6 py-3 bg-white border-t border-gray-200">
        <button className="w-full bg-[#25D366] text-white py-3 rounded-xl font-semibold flex items-center justify-center gap-2 hover:bg-[#20ba5a] transition-colors">
          <MessageCircle className="w-5 h-5" />
          ¿Querés seguir la conversación? Abrir WhatsApp →
        </button>
      </div>

      {/* Input Area */}
      <div className="px-6 py-4 bg-white border-t border-gray-200 sticky bottom-0">
        <div className="flex gap-3 items-center">
          <input
            type="text"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            onKeyPress={(e) => e.key === "Enter" && handleSend()}
            placeholder="Escribí un mensaje..."
            className="flex-1 bg-gray-100 rounded-full px-5 py-3 outline-none focus:ring-2 focus:ring-[#1B6B3A]/20"
          />
          <button
            onClick={handleSend}
            className="w-12 h-12 bg-[#1B6B3A] rounded-full flex items-center justify-center hover:bg-[#155a30] transition-colors"
          >
            <Send className="w-5 h-5 text-white" />
          </button>
        </div>
      </div>
    </div>
  );
}