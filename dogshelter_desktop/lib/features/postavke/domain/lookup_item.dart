class LookupItem {
  const LookupItem({required this.id, required this.naziv});

  final int id;
  final String naziv;

  factory LookupItem.fromJson(Map<String, dynamic> json, String idKey) {
    return LookupItem(id: json[idKey] as int, naziv: json['naziv'] as String);
  }
}

/// Describes one Postavke lookup table so the generic CRUD screen/API/providers
/// can be reused across all of them instead of writing one file per table.
class LookupTableConfig {
  const LookupTableConfig({required this.path, required this.idKey, required this.label});

  final String path;
  final String idKey;
  final String label;

  @override
  bool operator ==(Object other) => other is LookupTableConfig && other.path == path && other.idKey == idKey;

  @override
  int get hashCode => Object.hash(path, idKey);
}
