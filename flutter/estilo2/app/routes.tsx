import { createBrowserRouter } from "react-router";
import { HomeScreen } from "./screens/HomeScreen";
import { CreateTripScreen } from "./screens/CreateTripScreen";
import { TripRequestsScreen } from "./screens/TripRequestsScreen";
import { SearchResultsScreen } from "./screens/SearchResultsScreen";
import { TripDetailScreen } from "./screens/TripDetailScreen";
import { NotificationsScreen } from "./screens/NotificationsScreen";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: HomeScreen,
  },
  {
    path: "/crear-viaje",
    Component: CreateTripScreen,
  },
  {
    path: "/solicitudes",
    Component: TripRequestsScreen,
  },
  {
    path: "/buscar",
    Component: SearchResultsScreen,
  },
  {
    path: "/viaje/:id",
    Component: TripDetailScreen,
  },
  {
    path: "/notificaciones",
    Component: NotificationsScreen,
  },
]);
