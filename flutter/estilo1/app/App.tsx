import { RouterProvider } from "react-router";
import { router } from "./routes";

export default function App() {
  return (
    <div className="min-h-screen bg-[#F9FAF7] max-w-md mx-auto relative shadow-2xl">
      <RouterProvider router={router} />
    </div>
  );
}