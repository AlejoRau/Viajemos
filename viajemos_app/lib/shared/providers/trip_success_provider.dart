import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef TripSuccess = ({
  String originCity,
  String originAddress,
  String destinationCity,
  String destinationAddress,
  String tripId,
  DateTime departureDate,
  String departureTime,
  int seats,
  int price,
  String? vehicle,
  int? vehicleColor,
  bool acceptsPets,
  bool picksUpAtDoor,
  bool dropsOffAtDoor,
  List<String> routes,
  List<String> stops,
});

final tripSuccessProvider = StateProvider<TripSuccess?>((ref) => null);
