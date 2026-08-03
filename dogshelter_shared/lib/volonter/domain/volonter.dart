class Volonter {
  Volonter({
    required this.volonterId,
    required this.korisnikId,
    this.korisnikIme,
    this.korisnikPrezime,
    this.korisnikEmail,
    this.korisnikTelefon,
    required this.datumPridruzivanja,
    required this.aktivan,
    this.napomena,
    required this.ukupnoSati,
  });

  final int volonterId;
  final int korisnikId;
  final String? korisnikIme;
  final String? korisnikPrezime;
  final String? korisnikEmail;
  final String? korisnikTelefon;
  final DateTime datumPridruzivanja;
  final bool aktivan;
  final String? napomena;
  final double ukupnoSati;

  factory Volonter.fromJson(Map<String, dynamic> json) {
    return Volonter(
      volonterId: json['volonterId'] as int,
      korisnikId: json['korisnikId'] as int,
      korisnikIme: json['korisnikIme'] as String?,
      korisnikPrezime: json['korisnikPrezime'] as String?,
      korisnikEmail: json['korisnikEmail'] as String?,
      korisnikTelefon: json['korisnikTelefon'] as String?,
      datumPridruzivanja: DateTime.parse(json['datumPridruzivanja'] as String),
      aktivan: json['aktivan'] as bool,
      napomena: json['napomena'] as String?,
      ukupnoSati: (json['ukupnoSati'] as num).toDouble(),
    );
  }
}
