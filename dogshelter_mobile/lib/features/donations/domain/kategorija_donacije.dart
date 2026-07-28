import 'jedinica_mjere.dart';

class KategorijaDonacije {
  KategorijaDonacije({
    required this.kategorijaDonacijeId,
    required this.naziv,
    required this.ikonaKljuc,
    required this.podrazumijevanaJedinicaMjereId,
    required this.dozvoljeneJedinice,
  });

  final int kategorijaDonacijeId;
  final String naziv;
  final String ikonaKljuc;
  final int? podrazumijevanaJedinicaMjereId;

  // Empty means unrestricted (e.g. "Ostalo") - the form then falls back to showing every unit.
  final List<JedinicaMjere> dozvoljeneJedinice;

  bool get isOstalo => naziv == 'Ostalo';

  factory KategorijaDonacije.fromJson(Map<String, dynamic> json) {
    return KategorijaDonacije(
      kategorijaDonacijeId: json['kategorijaDonacijeId'] as int,
      naziv: json['naziv'] as String,
      ikonaKljuc: json['ikonaKljuc'] as String,
      podrazumijevanaJedinicaMjereId: json['podrazumijevanaJedinicaMjereId'] as int?,
      dozvoljeneJedinice: (json['dozvoljeneJedinice'] as List<dynamic>? ?? [])
          .map((e) => JedinicaMjere.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
