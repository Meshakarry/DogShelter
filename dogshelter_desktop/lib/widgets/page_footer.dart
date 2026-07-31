import 'package:flutter/material.dart';

/// "Ukupno: N" + prev/next page controls, shared by every paginated admin list screen.
class PageFooter extends StatelessWidget {
  const PageFooter({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Ukupno: $totalCount'),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Prethodna stranica',
              onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
            ),
            Text('Stranica $page od $totalPages'),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Sljedeća stranica',
              onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}
