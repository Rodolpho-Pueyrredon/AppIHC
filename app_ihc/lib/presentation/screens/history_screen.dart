import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/core/constants/screen_origins.dart';
import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/core/utils/price_parser.dart';
import 'package:app_ihc/domain/models/price_observation.dart';
import 'package:app_ihc/domain/models/product.dart';
import 'package:app_ihc/domain/models/store.dart';
import 'package:app_ihc/presentation/navigation/detail_edit_args.dart';
import 'package:app_ihc/presentation/navigation/history_args.dart';
import 'package:app_ihc/presentation/widgets/android_back_to_background.dart';
import 'package:app_ihc/presentation/widgets/session_app_bar.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.args});

  final HistoryArgs? args;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _observationRepository =
      ServiceLocator.instance.priceObservationRepository;
  final _productRepository = ServiceLocator.instance.productRepository;
  final _searchController = TextEditingController();

  List<PriceObservation> _allObservations = const [];
  List<Product> _allProducts = const [];
  Map<String, PriceObservation> _observationsByProductKey = const {};
  bool _isLoading = true;

  HistoryArgs? get _currentArgs {
    if (widget.args != null) {
      return widget.args;
    }

    final session = ServiceLocator.instance.authSession;
    final workGroupId = session.workGroupId;
    if (workGroupId == null || workGroupId.trim().isEmpty) {
      return null;
    }

    return HistoryArgs(
      workGroupId: workGroupId,
      storeName: session.storeName,
      storeAddress: session.storeAddress,
    );
  }

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
      final workGroupId = _currentArgs?.workGroupId;
      final observations = workGroupId == null
          ? await _observationRepository.getObservations()
          : await _observationRepository.getObservationsByWorkId(workGroupId);
      final products = workGroupId == null
          ? const <Product>[]
          : await _productRepository.findByWorkId(workGroupId);
      if (!mounted) {
        return;
      }

      setState(() {
        _allObservations = observations;
        _allProducts = products;
        _observationsByProductKey = _latestObservationsByProduct(observations);
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

  Map<String, PriceObservation> _latestObservationsByProduct(
    List<PriceObservation> observations,
  ) {
    final byProductKey = <String, PriceObservation>{};

    for (final observation in observations) {
      final workId = observation.product.workId;
      if (workId == null || workId.trim().isEmpty) {
        continue;
      }

      final key = _productKey(
        barcode: observation.product.barcode,
        workId: workId,
      );
      byProductKey.putIfAbsent(key, () => observation);
    }

    return byProductKey;
  }

  String _productKey({required String barcode, required String workId}) {
    return '${workId.trim()}|${barcode.trim()}';
  }

  void _onSearchChanged() {
    setState(() {
      // Rebuild para aplicar filtro local.
    });
  }

  void _goToTasks() {
    Navigator.pushReplacementNamed(context, AppRoutes.products);
  }

  Future<void> _openDetail(PriceObservation observation) async {
    await Navigator.pushReplacementNamed(
      context,
      AppRoutes.detailEdit,
      arguments: DetailEditArgs(
        observation: observation,
        sourceScreen: ScreenOrigins.screen2,
        workGroupId: _currentArgs?.workGroupId,
        storeName: _currentArgs?.storeName,
        storeAddress: _currentArgs?.storeAddress,
      ),
    );
  }

  Future<void> _openProductDetail(Product product) async {
    final args = _currentArgs;
    final observation = _observationForProduct(product);

    await Navigator.pushReplacementNamed(
      context,
      AppRoutes.detailEdit,
      arguments: DetailEditArgs(
        observation:
            observation ??
            PriceObservation(
              product: product,
              store: Store(
                name: args?.storeName ?? '',
                address: args?.storeAddress,
              ),
              priceCents: 0,
              latitude: 0,
              longitude: 0,
              observedAt: DateTime.now().toUtc(),
            ),
        sourceScreen: ScreenOrigins.screen2,
        workGroupId: args?.workGroupId,
        storeName: args?.storeName,
        storeAddress: args?.storeAddress,
      ),
    );
  }

  PriceObservation? _observationForProduct(Product product) {
    final workId = product.workId;
    if (workId == null || workId.trim().isEmpty) {
      return null;
    }

    return _observationsByProductKey[_productKey(
      barcode: product.barcode,
      workId: workId,
    )];
  }

  List<PriceObservation> _filteredObservations() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _allObservations;
    }

    return _allObservations.where((item) {
      final productLabel = ((item.product.brand ?? item.product.name) ?? '')
          .toLowerCase();
      return productLabel.contains(query);
    }).toList();
  }

  List<Product> _filteredProducts() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _allProducts;
    }

    return _allProducts.where((product) {
      final productLabel = [
        product.name,
        product.brand,
        product.category,
        product.barcode,
      ].whereType<String>().join(' ').toLowerCase();
      return productLabel.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isCollectingProducts = _currentArgs != null;
    final filteredObservations = _filteredObservations();
    final filteredProducts = _filteredProducts();
    final collectedCount = _allProducts
        .where((product) => _observationForProduct(product) != null)
        .length;
    final pendingCount = _allProducts.length - collectedCount;

    return AndroidBackToBackground(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 112,
          backgroundColor: Colors.red.shade50,
          surfaceTintColor: Colors.red.shade50,
          iconTheme: const IconThemeData(size: 48),
          title: SessionAppBarTitle(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isCollectingProducts) ...[
                  _CollectionSummary(
                    collectedCount: collectedCount,
                    pendingCount: pendingCount,
                  ),
                  const SizedBox(height: 4),
                ],
                TextField(
                  style: const TextStyle(fontSize: 24),
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintStyle: TextStyle(fontSize: 24),
                    hintText: 'Buscar produto...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Tarefas',
              onPressed: _goToTasks,
              icon: const Icon(Icons.assignment, size: 48),
            ),
            const LogoutActionButton(),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadItems,
                child: isCollectingProducts
                    ? _ProductsToCollectList(
                        products: filteredProducts,
                        observationsByProductKey: _observationsByProductKey,
                        onOpenDetail: _openProductDetail,
                      )
                    : _ObservationsList(
                        observations: filteredObservations,
                        onOpenDetail: _openDetail,
                      ),
              ),
      ),
    );
  }
}

class _CollectionSummary extends StatelessWidget {
  const _CollectionSummary({
    required this.collectedCount,
    required this.pendingCount,
  });

  final int collectedCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Produtos coletados: $collectedCount',
          style: baseStyle?.copyWith(color: Colors.green.shade700),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Ainda a coletar: $pendingCount',
          style: baseStyle?.copyWith(color: Colors.red.shade700),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ProductsToCollectList extends StatelessWidget {
  const _ProductsToCollectList({
    required this.products,
    required this.observationsByProductKey,
    required this.onOpenDetail,
  });

  final List<Product> products;
  final Map<String, PriceObservation> observationsByProductKey;
  final void Function(Product product) onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Nenhum produto encontrado para este trabalho.')),
        ],
      );
    }

    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = products[index];
        final observation = _observationForProduct(product);
        return _ProductToCollectTile(
          product: product,
          observation: observation,
          onTap: () => onOpenDetail(product),
        );
      },
    );
  }

  PriceObservation? _observationForProduct(Product product) {
    final workId = product.workId;
    if (workId == null || workId.trim().isEmpty) {
      return null;
    }

    return observationsByProductKey['${workId.trim()}|${product.barcode.trim()}'];
  }
}

class _ObservationsList extends StatelessWidget {
  const _ObservationsList({
    required this.observations,
    required this.onOpenDetail,
  });

  final List<PriceObservation> observations;
  final void Function(PriceObservation observation) onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (observations.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Nenhum item encontrado no historico.')),
        ],
      );
    }

    return ListView.separated(
      itemCount: observations.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = observations[index];
        return _HistoryObservationTile(
          observation: item,
          onTap: () => onOpenDetail(item),
        );
      },
    );
  }
}

class _ProductToCollectTile extends StatelessWidget {
  const _ProductToCollectTile({
    required this.product,
    required this.observation,
    required this.onTap,
  });

  final Product product;
  final PriceObservation? observation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final productName = product.name ?? 'Produto sem nome';
    final brand = product.brand ?? 'Marca nao informada';
    final category = product.category ?? 'Categoria nao informada';
    final price = observation == null
        ? 'Preco nao coletado'
        : formatPriceFromCents(observation!.priceCents);
    final backgroundColor = observation == null
        ? const Color(0xFFFFD6D6)
        : const Color(0xFFDDF7DF);

    return ColoredBox(
      color: backgroundColor,
      child: ListTile(
        onTap: onTap,
        title: Text(productName),
        subtitle: Text(
          '$brand\n$category - ${product.barcode}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(price, style: Theme.of(context).textTheme.titleMedium),
        isThreeLine: true,
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
    final productName =
        observation.product.brand ??
        observation.product.name ??
        'Marca nao informada';
    final category = observation.product.category ?? 'Categoria nao informada';
    final storeName = observation.store.name;
    final date = observation.observedAt.toLocal().toString().split('.').first;
    final price = formatPriceFromCents(observation.priceCents);

    return ListTile(
      onTap: onTap,
      title: Text(productName),
      subtitle: Text(
        '$category\n$storeName - $date',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(price, style: Theme.of(context).textTheme.titleMedium),
      isThreeLine: true,
    );
  }
}
