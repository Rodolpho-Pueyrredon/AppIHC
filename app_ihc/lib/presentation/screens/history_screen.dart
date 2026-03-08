import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/domain/models/price_observation.dart';
import 'package:app_ihc/presentation/navigation/detail_edit_args.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  static const String sourceName = 'history_screen';

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repository = ServiceLocator.instance.priceObservationRepository;
  final _searchController = TextEditingController();

  List<PriceObservation> _allItems = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    final items = await _repository.getObservations();
    if (!mounted) {
      return;
    }

    setState(() {
      _allItems = items;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    setState(() {
      // Rebuild para aplicar filtro local.
    });
  }

  void _goToScanner() {
    Navigator.pushReplacementNamed(context, AppRoutes.scanner);
  }

  Future<void> _openDetail(PriceObservation observation) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.detailEdit,
      arguments: DetailEditArgs(
        observation: observation,
        sourceScreen: HistoryScreen.sourceName,
      ),
    );
    await _loadItems();
  }

  List<PriceObservation> _filteredItems() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _allItems;
    }

    return _allItems.where((item) {
      final productName = (item.product.name ?? '').toLowerCase();
      return productName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Buscar produto...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _goToScanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Ler'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadItems,
              child: ListView.separated(
                itemCount: filteredItems.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  final productName = item.product.name ?? 'Produto sem nome';

                  return ListTile(
                    title: Text(productName),
                    onTap: () => _openDetail(item),
                  );
                },
              ),
            ),
    );
  }
}
