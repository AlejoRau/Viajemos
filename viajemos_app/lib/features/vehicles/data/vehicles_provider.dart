import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vehicles_repository.dart';
import '../domain/vehicle.dart';

final vehiclesRepositoryProvider =
    Provider<VehiclesRepository>((_) => VehiclesRepository());

final vehiclesProvider = FutureProvider<List<Vehicle>>((ref) {
  return ref.read(vehiclesRepositoryProvider).fetchMyVehicles();
});
