class KategorijaDonacije {
  KategorijaDonacije({required this.kategorijaDonacijeId, required this.naziv, required this.ikonaKljuc});

  final int kategorijaDonacijeId;
  final String naziv;
  final String ikonaKljuc;

  bool get isOstalo => naziv == 'Ostalo';

  factory KategorijaDonacije.fromJson(Map<String, dynamic> json) {
    return KategorijaDonacije(
      kategorijaDonacijeId: json['kategorijaDonacijeId'] as int,
      naziv: json['naziv'] as String,
      ikonaKljuc: json['ikonaKljuc'] as String,
    );
  }
}
