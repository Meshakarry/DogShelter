class ZahtjevSummary {
  const ZahtjevSummary({
    required this.id,
    required this.korisnikIme,
    required this.korisnikPrezime,
    required this.pasNaziv,
    required this.statusZahtjevaNaziv,
    required this.datumPodnosenja,
  });

  final int id;
  final String korisnikIme;
  final String korisnikPrezime;
  final String pasNaziv;
  final String statusZahtjevaNaziv;
  final DateTime datumPodnosenja;

  factory ZahtjevSummary.fromJson(Map<String, dynamic> json) {
    return ZahtjevSummary(
      id: json['zahtjevZaUdomljavanjeId'] as int,
      korisnikIme: json['korisnikIme'] as String? ?? '',
      korisnikPrezime: json['korisnikPrezime'] as String? ?? '',
      pasNaziv: json['pasNaziv'] as String? ?? '',
      statusZahtjevaNaziv: json['statusZahtjevaNaziv'] as String? ?? '',
      datumPodnosenja: DateTime.parse(json['datumPodnosenja'] as String),
    );
  }
}

class MjesecBroj {
  const MjesecBroj({required this.godina, required this.mjesec, required this.mjesecNaziv, required this.broj});

  final int godina;
  final int mjesec;
  final String mjesecNaziv;
  final int broj;

  factory MjesecBroj.fromJson(Map<String, dynamic> json) {
    return MjesecBroj(
      godina: json['godina'] as int,
      mjesec: json['mjesec'] as int,
      mjesecNaziv: json['mjesecNaziv'] as String,
      broj: json['broj'] as int,
    );
  }
}

class PocetnaDashboardData {
  const PocetnaDashboardData({
    required this.ukupnoPasa,
    required this.dostupnihPasa,
    required this.zahtjevaNaCekanju,
    required this.danasnjePosjete,
    required this.nedavniZahtjevi,
    required this.udomljavanjaPoMjesecima,
  });

  final int ukupnoPasa;
  final int dostupnihPasa;
  final int zahtjevaNaCekanju;
  final int danasnjePosjete;
  final List<ZahtjevSummary> nedavniZahtjevi;
  final List<MjesecBroj> udomljavanjaPoMjesecima;
}
