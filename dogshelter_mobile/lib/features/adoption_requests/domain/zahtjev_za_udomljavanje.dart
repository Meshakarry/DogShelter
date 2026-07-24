class ZahtjevZaUdomljavanje {
  ZahtjevZaUdomljavanje({
    required this.zahtjevZaUdomljavanjeId,
    required this.korisnikId,
    this.korisnikIme,
    this.korisnikPrezime,
    required this.pasId,
    this.pasNaziv,
    this.pasSlikaNaslovna,
    required this.statusZahtjevaId,
    this.statusZahtjevaNaziv,
    required this.datumPodnosenja,
    this.napomena,
    this.datumObrade,
    this.obradioKorisnikId,
    this.obradioKorisnikIme,
    this.obradioKorisnikPrezime,
    this.razlogOdbijanja,
  });

  final int zahtjevZaUdomljavanjeId;
  final int korisnikId;
  final String? korisnikIme;
  final String? korisnikPrezime;
  final int pasId;
  final String? pasNaziv;
  final String? pasSlikaNaslovna;
  final int statusZahtjevaId;
  final String? statusZahtjevaNaziv;
  final DateTime datumPodnosenja;
  final String? napomena;
  final DateTime? datumObrade;
  final int? obradioKorisnikId;
  final String? obradioKorisnikIme;
  final String? obradioKorisnikPrezime;
  final String? razlogOdbijanja;

  factory ZahtjevZaUdomljavanje.fromJson(Map<String, dynamic> json) {
    return ZahtjevZaUdomljavanje(
      zahtjevZaUdomljavanjeId: json['zahtjevZaUdomljavanjeId'] as int,
      korisnikId: json['korisnikId'] as int,
      korisnikIme: json['korisnikIme'] as String?,
      korisnikPrezime: json['korisnikPrezime'] as String?,
      pasId: json['pasId'] as int,
      pasNaziv: json['pasNaziv'] as String?,
      pasSlikaNaslovna: json['pasSlikaNaslovna'] as String?,
      statusZahtjevaId: json['statusZahtjevaId'] as int,
      statusZahtjevaNaziv: json['statusZahtjevaNaziv'] as String?,
      datumPodnosenja: DateTime.parse(json['datumPodnosenja'] as String),
      napomena: json['napomena'] as String?,
      datumObrade: json['datumObrade'] == null ? null : DateTime.parse(json['datumObrade'] as String),
      obradioKorisnikId: json['obradioKorisnikId'] as int?,
      obradioKorisnikIme: json['obradioKorisnikIme'] as String?,
      obradioKorisnikPrezime: json['obradioKorisnikPrezime'] as String?,
      razlogOdbijanja: json['razlogOdbijanja'] as String?,
    );
  }
}
