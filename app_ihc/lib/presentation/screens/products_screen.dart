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
  final _authSession = ServiceLocator.instance.authSession;
  final _collaboratorWorksService =
      ServiceLocator.instance.collaboratorWorksService;
  final _sessionRepository = ServiceLocator.instance.sessionRepository;
  final _sessionProductsSyncService =
      ServiceLocator.instance.sessionProductsSyncService;
  final _workGroupsService = ServiceLocator.instance.sessionWorkGroupsService;
  final _productRepository = ServiceLocator.instance.productRepository;
  final _observationRepository =
      ServiceLocator.instance.priceObservationRepository;
  final _priceObservationSyncService =
      ServiceLocator.instance.priceObservationSyncService;

  List<SessionWorkGroup> _workGroups = const [];
  Map<String, _TaskCollectionSummary> _summariesByWorkGroupId = const {};
  bool _isLoading = true;
  bool _isExporting = false;

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
      await _refreshSessionFromSupabaseIfPossible();
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
    }
  }

  Future<void> _refreshSessionFromSupabaseIfPossible() async {
    final username = _authSession.username?.trim();
    if (username == null || username.isEmpty) {
      return;
    }

    try {
      final works = await _collaboratorWorksService.getWorksForCollaborator(
        username,
      );
      await _sessionRepository.saveSessionWorks(works);
      await _sessionProductsSyncService.syncProductsFromSession();
    } catch (_) {
      // Best-effort refresh: offline users should keep using local SQLite data.
    }
  }

  int _collectedProductsCount(List<PriceObservation> observations) {
    return observations
        .map((observation) => observation.product.barcode.trim())
        .where((barcode) => barcode.isNotEmpty)
        .toSet()
        .length;
  }

  Future<void> _exportCollectedObservations() async {
    if (_isExporting) {
      return;
    }

    final workIds = _workGroups.map((workGroup) => workGroup.workGroupId);
    setState(() {
      _isExporting = true;
    });

    try {
      final insertedKeys = await _priceObservationSyncService
          .syncLocalPriceObservationsForWorkIds(workIds);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            insertedKeys.isEmpty
                ? 'Nenhuma coleta local para exportar.'
                : '${insertedKeys.length} coleta(s) exportada(s).',
          ),
        ),
      );

      await _loadWorkGroups();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_exportErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  String _exportErrorMessage(Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return 'Erro ao exportar coletas.';
    }

    return 'Erro ao exportar coletas: $message';
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
          actions: [
            _isExporting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 32,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: 'Exportar coletas',
                    onPressed: _workGroups.isEmpty
                        ? null
                        : _exportCollectedObservations,
                    icon: const Icon(Icons.file_upload, size: 48),
                  ),
            const LogoutActionButton(),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadWorkGroups,
                child: _workGroups.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('Nenhum trabalho encontrado.')),
                        ],
                      )
                    : Scrollbar(
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _workGroups.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final workGroup = _workGroups[index];
                            return _WorkGroupButton(
                              workGroup: workGroup,
                              summary:
                                  _summariesByWorkGroupId[workGroup
                                      .workGroupId],
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
    final isCompleted = summary?.isCompleted ?? false;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: isCompleted ? const Color(0xFFDDF7DF) : null,
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
              color: Colors.green.shade700,
            ),
            _TaskSummaryText(
              label: 'Ainda a coletar',
              value: summary!.pendingProducts,
              color: Colors.red.shade700,
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskSummaryText extends StatelessWidget {
  const _TaskSummaryText({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: color,
      ),
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

  bool get isCompleted => pendingProducts == 0;

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
