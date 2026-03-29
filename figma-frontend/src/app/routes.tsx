import { createBrowserRouter } from "react-router";
import { Home } from "./components/Home";
import { DriverHome } from "./components/DriverHome";
import { CreateTrip } from "./components/CreateTrip";
import { PassengerRequests } from "./components/PassengerRequests";
import { PassengerHome } from "./components/PassengerHome";
import { SearchTrips } from "./components/SearchTrips";
import { CreateRequest } from "./components/CreateRequest";

export const router = createBrowserRouter([
  {
    path: "/",
    element: <Home />,
  },
  {
    path: "/driver",
    element: <DriverHome />,
  },
  {
    path: "/driver/create-trip",
    element: <CreateTrip />,
  },
  {
    path: "/driver/passenger-requests",
    element: <PassengerRequests />,
  },
  {
    path: "/passenger",
    element: <PassengerHome />,
  },
  {
    path: "/passenger/search-trips",
    element: <SearchTrips />,
  },
  {
    path: "/passenger/create-request",
    element: <CreateRequest />,
  },
]);
