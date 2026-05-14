import 'product.dart';
import 'store.dart';

class PriceObservation {
  const PriceObservation({
    this.id,
    required this.product,
    required this.store,
    required this.priceCents,
    required this.latitude,
    required this.longitude,
    required this.observedAt,
    this.createdAt,
  });

  final int? id;
  final Product product;
  final Store store;
  final int priceCents;
  final double latitude;
  final double longitude;
  final DateTime observedAt;
  final DateTime? createdAt;

  double get price => priceCents / 100.0;

  PriceObservation copyWith({
    int? id,
    Product? product,
    Store? store,
    int? priceCents,
    double? latitude,
    double? longitude,
    DateTime? observedAt,
    DateTime? createdAt,
  }) {
    return PriceObservation(
      id: id ?? this.id,
      product: product ?? this.product,
      store: store ?? this.store,
      priceCents: priceCents ?? this.priceCents,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      observedAt: observedAt ?? this.observedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
