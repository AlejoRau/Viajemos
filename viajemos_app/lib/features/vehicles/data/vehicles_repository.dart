import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/vehicle.dart';

class VehiclesRepository {
  final _client = Supabase.instance.client;

  static const _colorHexMap = <String, int>{
    'Blanco': 0xFFFFFFFF,
    'Negro': 0xFF1A1A1A,
    'Gris': 0xFF6B7280,
    'Plateado': 0xFFCBD5E1,
    'Rojo': 0xFFDC2626,
    'Azul': 0xFF1A73E8,
    'Verde': 0xFF15803D,
    'Amarillo': 0xFFEAB308,
    'Naranja': 0xFFEA580C,
    'Marrón': 0xFF92400E,
    'Beige': 0xFFD4B896,
    'Bordó': 0xFF881337,
    'Celeste': 0xFF0EA5E9,
    'Dorado': 0xFFD97706,
    'Violeta': 0xFF7C3AED,
  };

  static int hexForColor(String color) =>
      _colorHexMap[color] ?? 0xFF6B7280;

  Future<List<Vehicle>> fetchMyVehicles() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];
    final data = await _client
        .from('vehicles')
        .select('id, brand, model, color')
        .eq('owner_id', user.id)
        .order('created_at');
    return (data as List)
        .map((row) => Vehicle(
              id: row['id'] as String,
              brand: row['brand'] as String,
              model: row['model'] as String,
              color: row['color'] as String,
              colorHex: hexForColor(row['color'] as String),
            ))
        .toList();
  }

  Future<void> updateVehicle({
    required String id,
    required String brand,
    required String model,
    required String color,
    required int colorHex,
  }) async {
    await _client.from('vehicles').update({
      'brand': brand,
      'model': model,
      'color': color,
    }).eq('id', id);
  }

  Future<void> deleteVehicle(String id) async {
    await _client.from('vehicles').delete().eq('id', id);
  }

  Future<Vehicle> addVehicle({
    required String brand,
    required String model,
    required String color,
    required int colorHex,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    final response = await _client
        .from('vehicles')
        .insert({
          'owner_id': user.id,
          'brand': brand,
          'model': model,
          'color': color,
        })
        .select('id')
        .single();
    return Vehicle(
      id: response['id'] as String,
      brand: brand,
      model: model,
      color: color,
      colorHex: colorHex,
    );
  }
}
