class StatusZahtjeva {
  StatusZahtjeva({required this.statusZahtjevaId, required this.naziv});

  final int statusZahtjevaId;
  final String naziv;

  factory StatusZahtjeva.fromJson(Map<String, dynamic> json) {
    return StatusZahtjeva(statusZahtjevaId: json['statusZahtjevaId'] as int, naziv: json['naziv'] as String);
  }
}
