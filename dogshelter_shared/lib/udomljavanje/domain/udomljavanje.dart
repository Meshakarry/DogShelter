class Udomljavanje {
  Udomljavanje({
    required this.udomljavanjeId,
    required this.zahtjevZaUdomljavanjeId,
    required this.datumUdomljavanja,
    this.napomena,
    required this.pasId,
    this.pasNaziv,
    this.pasSlikaNaslovna,
    required this.korisnikId,
    this.korisnikIme,
    this.korisnikPrezime,
  });

  final int udomljavanjeId;
  final int zahtjevZaUdomljavanjeId;
  final DateTime datumUdomljavanja;
  final String? napomena;
  final int pasId;
  final String? pasNaziv;
  final String? pasSlikaNaslovna;
  final int korisnikId;
  final String? korisnikIme;
  final String? korisnikPrezime;

  factory Udomljavanje.fromJson(Map<String, dynamic> json) {
    return Udomljavanje(
      udomljavanjeId: json['udomljavanjeId'] as int,
      zahtjevZaUdomljavanjeId: json['zahtjevZaUdomljavanjeId'] as int,
      datumUdomljavanja: DateTime.parse(json['datumUdomljavanja'] as String),
      napomena: json['napomena'] as String?,
      pasId: json['pasId'] as int,
      pasNaziv: json['pasNaziv'] as String?,
      pasSlikaNaslovna: json['pasSlikaNaslovna'] as String?,
      korisnikId: json['korisnikId'] as int,
      korisnikIme: json['korisnikIme'] as String?,
      korisnikPrezime: json['korisnikPrezime'] as String?,
    );
  }
}
