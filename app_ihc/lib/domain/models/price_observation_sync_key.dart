class PriceObservationSyncKey {
  const PriceObservationSyncKey({required this.barcode, required this.workId});

  final String barcode;
  final String workId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PriceObservationSyncKey &&
            other.barcode == barcode &&
            other.workId == workId;
  }

  @override
  int get hashCode => Object.hash(barcode, workId);

  @override
  String toString() {
    return 'PriceObservationSyncKey(barcode: $barcode, workId: $workId)';
  }
}
