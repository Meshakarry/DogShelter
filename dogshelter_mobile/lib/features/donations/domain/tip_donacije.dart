class TipDonacije {
  TipDonacije({required this.tipDonacijeId, required this.naziv});

  final int tipDonacijeId;
  final String naziv;

  factory TipDonacije.fromJson(Map<String, dynamic> json) {
    return TipDonacije(tipDonacijeId: json['tipDonacijeId'] as int, naziv: json['naziv'] as String);
  }
}
