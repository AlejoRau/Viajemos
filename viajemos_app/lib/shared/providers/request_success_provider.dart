import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef RequestSuccess = ({
  String originCity,
  String destinationCity,
  DateTime dateFrom,
  DateTime? dateTo,
  String timeFrom,
  String timeTo,
  int seats,
  int maxPrice,
  bool hasPet,
});

final requestSuccessProvider = StateProvider<RequestSuccess?>((ref) => null);
