import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/core/constants/screen_origins.dart';
import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/domain/models/price_observation.dart';
import 'package:app_ihc/presentation/navigation/detail_edit_args.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

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

    try {
      final items = await _repository.getObservations();
      if (!mounted) {
        return;
      }

      setState(() {
        _allItems = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar historico local.')),
      );
    }
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
        sourceScreen: ScreenOrigins.screen2,
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
              child: filteredItems.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text('Nenhum item encontrado no historico.'),
                        ),
                      ],
                    )
                  : ListView.separated(
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _HistoryObservationTile(
                          observation: item,
                          onTap: () => _openDetail(item),
                        );
                      },
                    ),
            ),
    );
  }
}

class _HistoryObservationTile extends StatelessWidget {
  const _HistoryObservationTile({
    required this.observation,
    required this.onTap,
  });

  final PriceObservation observation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final productName = observation.product.name ?? 'Produto sem nome';
    final brand = observation.product.brand ?? 'Marca nao informada';
    final category = observation.product.category ?? 'Categoria nao informada';
    final storeName = observation.store.name;
    final date = observation.observedAt.toLocal().toString().split('.').first;
    final price = (observation.priceCents / 100).toStringAsFixed(2);

    return ListTile(
      onTap: onTap,
      title: Text(productName),
      subtitle: Text(
        '$brand - $category\n$storeName - $date',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text('R\$ $price'),
      isThreeLine: true,
    );
  }
}
