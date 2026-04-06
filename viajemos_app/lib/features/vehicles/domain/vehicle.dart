class Vehicle {
  const Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.color,
    required this.colorHex,
  });

  final String id;
  final String brand;
  final String model;
  final String color;
  final int colorHex;

  String get displayName => '$brand $model';
}
