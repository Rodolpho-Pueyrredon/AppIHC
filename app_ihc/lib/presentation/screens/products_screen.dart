import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/domain/models/price_observation.dart';
import 'package:app_ihc/domain/models/session_work_group.dart';
import 'package:app_ihc/presentation/navigation/history_args.dart';
import 'package:app_ihc/presentation/widgets/android_back_to_background.dart';
import 'package:app_ihc/presentation/widgets/session_app_bar.dart';
import 'package:flutter/material.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _workGroupsService = ServiceLocator.instance.sessionWorkGroupsService;
  final _productRepository = ServiceLocator.instance.productRepository;
  final _observationRepository =
      ServiceLocator.instance.priceObservationRepository;

  List<SessionWorkGroup> _workGroups = const [];
  Map<String, _TaskCollectionSummary> _summariesByWorkGroupId = const {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkGroups();
  }

  Future<void> _loadWorkGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final workGroups = await _workGroupsService.getWorkGroupsFromSession();
      final summariesByWorkGroupId = <String, _TaskCollectionSummary>{};

      for (final workGroup in workGroups) {
        final products = await _productRepository.findByWorkId(
          workGroup.workGroupId,
        );
        final observations = await _observationRepository
            .getObservationsByWorkId(workGroup.workGroupId);

        summariesByWorkGroupId[workGroup.workGroupId] =
            _TaskCollectionSummary.fromCounts(
              totalProducts: products.length,
              collectedProducts: _collectedProductsCount(observations),
            );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _workGroups = workGroups;
        _summariesByWorkGroupId = summariesByWorkGroupId;
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
        const SnackBar(content: Text('Erro ao carregar trabalhos.')),
      );
    }
  }

  int _collectedProductsCount(List<PriceObservation> observations) {
    return observations
        .map((observation) => observation.product.barcode.trim())
        .where((barcode) => barcode.isNotEmpty)
        .toSet()
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return AndroidBackToBackground(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 112,
          backgroundColor: Colors.red.shade50,
          surfaceTintColor: Colors.red.shade50,
          iconTheme: const IconThemeData(size: 48),
          title: const SessionAppBarTitle(
            child: Text('Tarefas', style: TextStyle(fontSize: 24)),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadWorkGroups,
                child: _workGroups.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('Nenhum trabalho encontrado.')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _workGroups.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final workGroup = _workGroups[index];
                          return _WorkGroupButton(
                            workGroup: workGroup,
                            summary:
                                _summariesByWorkGroupId[workGroup.workGroupId],
                            onPressed: () {
                              ServiceLocator.instance.authSession
                                  .selectWorkGroup(
                                    workGroupId: workGroup.workGroupId,
                                    storeName: workGroup.storeName,
                                    storeAddress: workGroup.storeAddress,
                                  );
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.history,
                                arguments: HistoryArgs(
                                  workGroupId: workGroup.workGroupId,
                                  storeName: workGroup.storeName,
                                  storeAddress: workGroup.storeAddress,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
      ),
    );
  }
}

class _WorkGroupButton extends StatelessWidget {
  const _WorkGroupButton({
    required this.workGroup,
    required this.summary,
    required this.onPressed,
  });

  final SessionWorkGroup workGroup;
  final _TaskCollectionSummary? summary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            workGroup.storeName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            workGroup.storeAddress,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (summary != null) ...[
            const SizedBox(height: 8),
            _TaskSummaryText(
              label: 'Produtos coletados',
              value: summary!.collectedProducts,
            ),
            _TaskSummaryText(
              label: 'Ainda a coletar',
              value: summary!.pendingProducts,
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskSummaryText extends StatelessWidget {
  const _TaskSummaryText({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _TaskCollectionSummary {
  const _TaskCollectionSummary({
    required this.collectedProducts,
    required this.pendingProducts,
  });

  final int collectedProducts;
  final int pendingProducts;

  factory _TaskCollectionSummary.fromCounts({
    required int totalProducts,
    required int collectedProducts,
  }) {
    return _TaskCollectionSummary(
      collectedProducts: collectedProducts,
      pendingProducts: totalProducts - collectedProducts,
    );
  }
}
