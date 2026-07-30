class PagedResult<T> {
  PagedResult({required this.items, required this.totalCount, required this.page, required this.pageSize});

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < totalCount;

  factory PagedResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonItem) {
    return PagedResult<T>(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => fromJsonItem(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }
}
