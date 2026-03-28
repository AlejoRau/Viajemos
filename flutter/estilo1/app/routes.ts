import { createBrowserRouter } from "react-router";
import HomeScreen from "./screens/HomeScreen";
import CreateTripScreen from "./screens/CreateTripScreen";
import TripRequestsScreen from "./screens/TripRequestsScreen";
import SearchResultsScreen from "./screens/SearchResultsScreen";
import TripDetailScreen from "./screens/TripDetailScreen";
import GroupChatScreen from "./screens/GroupChatScreen";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: HomeScreen,
  },
  {
    path: "/create-trip",
    Component: CreateTripScreen,
  },
  {
    path: "/trip-requests",
    Component: TripRequestsScreen,
  },
  {
    path: "/search",
    Component: SearchResultsScreen,
  },
  {
    path: "/trip/:id",
    Component: TripDetailScreen,
  },
  {
    path: "/chat/:tripId",
    Component: GroupChatScreen,
  },
]);
