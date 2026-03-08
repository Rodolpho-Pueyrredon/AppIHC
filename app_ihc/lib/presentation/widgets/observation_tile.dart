import 'package:app_ihc/domain/models/price_observation.dart';
import 'package:flutter/material.dart';

class ObservationTile extends StatelessWidget {
  const ObservationTile({
    super.key,
    required this.observation,
    required this.onTap,
  });

  final PriceObservation observation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = observation.observedAt.toIso8601String().split('T').first;
    final productName = observation.product.name ?? 'Produto sem nome';
    return ListTile(
      onTap: onTap,
      title: Text(productName),
      subtitle: Text('${observation.store.name} - $date'),
      trailing: Text('R\$ ${observation.price.toStringAsFixed(2)}'),
    );
  }
}
