import 'package:app_ihc/core/constants/app_routes.dart';
import 'package:app_ihc/core/di/service_locator.dart';
import 'package:app_ihc/domain/models/price_observation.dart';
import 'package:app_ihc/presentation/navigation/detail_edit_args.dart';
import 'package:app_ihc/presentation/widgets/observation_tile.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _repository = ServiceLocator.instance.priceObservationRepository;
  late Future<List<PriceObservation>> _futureObservations;

  @override
  void initState() {
    super.initState();
    _futureObservations = _repository.getObservations();
  }

  Future<void> _reload() async {
    setState(() {
      _futureObservations = _repository.getObservations();
    });
  }

  Future<void> _openDetail(PriceObservation observation) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.detailEdit,
      arguments: DetailEditArgs(observation: observation),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historico')),
      body: FutureBuilder<List<PriceObservation>>(
        future: _futureObservations,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final observations = snapshot.data ?? const <PriceObservation>[];
          if (observations.isEmpty) {
            return const Center(
              child: Text('Nenhuma observacao registrada ainda.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              itemCount: observations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = observations[index];
                return ObservationTile(
                  observation: item,
                  onTap: () => _openDetail(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
