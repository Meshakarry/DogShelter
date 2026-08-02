class Posjeta {
  Posjeta({
    required this.posjetaId,
    required this.korisnikId,
    this.korisnikIme,
    this.korisnikPrezime,
    this.pasId,
    this.pasNaziv,
    this.pasSlikaNaslovna,
    required this.datumVrijeme,
    required this.statusPosjeteId,
    this.statusPosjeteNaziv,
    this.napomena,
    required this.datumKreiranja,
    this.datumObrade,
    this.obradioKorisnikId,
    this.obradioKorisnikIme,
    this.obradioKorisnikPrezime,
    this.razlogOtkazivanja,
  });

  final int posjetaId;
  final int korisnikId;
  final String? korisnikIme;
  final String? korisnikPrezime;
  final int? pasId;
  final String? pasNaziv;
  final String? pasSlikaNaslovna;
  final DateTime datumVrijeme;
  final int statusPosjeteId;
  final String? statusPosjeteNaziv;
  final String? napomena;
  final DateTime datumKreiranja;
  final DateTime? datumObrade;
  final int? obradioKorisnikId;
  final String? obradioKorisnikIme;
  final String? obradioKorisnikPrezime;
  final String? razlogOtkazivanja;

  factory Posjeta.fromJson(Map<String, dynamic> json) {
    return Posjeta(
      posjetaId: json['posjetaId'] as int,
      korisnikId: json['korisnikId'] as int,
      korisnikIme: json['korisnikIme'] as String?,
      korisnikPrezime: json['korisnikPrezime'] as String?,
      pasId: json['pasId'] as int?,
      pasNaziv: json['pasNaziv'] as String?,
      pasSlikaNaslovna: json['pasSlikaNaslovna'] as String?,
      datumVrijeme: DateTime.parse(json['datumVrijeme'] as String),
      statusPosjeteId: json['statusPosjeteId'] as int,
      statusPosjeteNaziv: json['statusPosjeteNaziv'] as String?,
      napomena: json['napomena'] as String?,
      datumKreiranja: DateTime.parse(json['datumKreiranja'] as String),
      datumObrade: json['datumObrade'] == null ? null : DateTime.parse(json['datumObrade'] as String),
      obradioKorisnikId: json['obradioKorisnikId'] as int?,
      obradioKorisnikIme: json['obradioKorisnikIme'] as String?,
      obradioKorisnikPrezime: json['obradioKorisnikPrezime'] as String?,
      razlogOtkazivanja: json['razlogOtkazivanja'] as String?,
    );
  }
}
