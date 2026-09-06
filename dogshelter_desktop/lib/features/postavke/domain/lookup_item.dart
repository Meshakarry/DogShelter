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
  const LookupTableConfig({
    required this.path,
    required this.idKey,
    required this.label,
    this.protectedNazivi = const {},
  });

  final String path;
  final String idKey;
  final String label;

  /// Naziv values the backend refuses to rename or delete because business logic looks them up
  /// by exact name (mirrors each service's own `CanonicalNazivi` - see e.g. `StatusPsaService`,
  /// `UlogaService`). Rows matching one of these have their edit/delete actions disabled here
  /// instead of only failing after a round-trip to the API.
  final Set<String> protectedNazivi;

  bool isProtected(String naziv) => protectedNazivi.any((p) => p.toLowerCase() == naziv.toLowerCase());

  @override
  bool operator ==(Object other) => other is LookupTableConfig && other.path == path && other.idKey == idKey;

  @override
  int get hashCode => Object.hash(path, idKey);
}
