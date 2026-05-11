class HistoryArgs {
  const HistoryArgs({
    required this.workGroupId,
    this.storeName,
    this.storeAddress,
  });

  final String workGroupId;
  final String? storeName;
  final String? storeAddress;
}
