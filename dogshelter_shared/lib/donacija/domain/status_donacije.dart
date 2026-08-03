class StatusDonacije {
  StatusDonacije({required this.statusDonacijeId, required this.naziv});

  final int statusDonacijeId;
  final String naziv;

  factory StatusDonacije.fromJson(Map<String, dynamic> json) {
    return StatusDonacije(statusDonacijeId: json['statusDonacijeId'] as int, naziv: json['naziv'] as String);
  }
}
