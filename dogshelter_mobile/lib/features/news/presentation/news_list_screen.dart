import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dogshelter_shared/core/date_format.dart';
import 'package:dogshelter_shared/core/image_url.dart';
import '../../../environment.dart';
import 'package:dogshelter_shared/widgets/error_banner.dart';
import 'package:dogshelter_shared/obavijest/domain/obavijest_list_item.dart';
import '../application/news_providers.dart';

class NewsListScreen extends ConsumerStatefulWidget {
  const NewsListScreen({super.key});

  @override
  ConsumerState<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends ConsumerState<NewsListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(newsListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text('Obavijesti', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ErrorBanner(error: state.error),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(newsListProvider.notifier).loadFirstPage(),
            child: state.items.isEmpty && !state.isLoading
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Trenutno nema obavijesti.')),
                    ],
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _ObavijestListTile(obavijest: state.items[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _ObavijestListTile extends StatelessWidget {
  const _ObavijestListTile({required this.obavijest});

  final ObavijestListItem obavijest;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(obavijest.slikaPutanja, Environment.apiBaseUrl);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/obavijesti/${obavijest.obavijestId}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: imageUrl == null
                      ? const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.campaign))
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) =>
                              const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.campaign)),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      obavijest.naslov,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(obavijest.datumObjave),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
