import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/aktivnost_volontera/domain/aktivnost_volontera.dart';
import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/widgets/status_pill.dart';
import '../application/activities_providers.dart';

class AktivnostiListScreen extends ConsumerStatefulWidget {
  const AktivnostiListScreen({super.key});

  @override
  ConsumerState<AktivnostiListScreen> createState() => _AktivnostiListScreenState();
}

class _AktivnostiListScreenState extends ConsumerState<AktivnostiListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    ref.read(tipoviAktivnostiProvider);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(aktivnostiListProvider.notifier).loadMore();
    }
  }

  Future<void> _logActivity() async {
    final saved = await context.push<bool>('/aktivnosti/nova');
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aktivnost je evidentirana.')));
      ref.read(aktivnostiListProvider.notifier).loadFirstPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aktivnostiListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _logActivity,
        icon: const Icon(Icons.add),
        label: const Text('Evidentiraj'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text('Moje aktivnosti', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ErrorBanner(error: state.error),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(aktivnostiListProvider.notifier).loadFirstPage(),
              child: state.items.isEmpty && !state.isLoading
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Još niste evidentirali nijednu aktivnost.')),
                      ],
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: state.items.length + (state.hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _AktivnostListTile(aktivnost: state.items[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AktivnostListTile extends StatelessWidget {
  const _AktivnostListTile({required this.aktivnost});

  final AktivnostVolontera aktivnost;

  @override
  Widget build(BuildContext context) {
    final greyText = Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFEDE9FE),
              child: Icon(Icons.timer, color: Color(0xFF7C3AED), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          aktivnost.tipAktivnostiNaziv ?? 'Aktivnost',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      StatusPill(label: '${aktivnost.brojSati} h'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(formatDate(aktivnost.datumAktivnosti), style: greyText),
                  if (aktivnost.opis != null && aktivnost.opis!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(aktivnost.opis!, maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
