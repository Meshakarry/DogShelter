class AktivnostVolontera {
  AktivnostVolontera({
    required this.aktivnostVolonteraId,
    required this.volonterId,
    required this.korisnikId,
    this.volonterIme,
    this.volonterPrezime,
    required this.tipAktivnostiId,
    this.tipAktivnostiNaziv,
    required this.datumAktivnosti,
    required this.brojSati,
    this.opis,
  });

  final int aktivnostVolonteraId;
  final int volonterId;
  final int korisnikId;
  final String? volonterIme;
  final String? volonterPrezime;
  final int tipAktivnostiId;
  final String? tipAktivnostiNaziv;
  final DateTime datumAktivnosti;
  final double brojSati;
  final String? opis;

  factory AktivnostVolontera.fromJson(Map<String, dynamic> json) {
    return AktivnostVolontera(
      aktivnostVolonteraId: json['aktivnostVolonteraId'] as int,
      volonterId: json['volonterId'] as int,
      korisnikId: json['korisnikId'] as int,
      volonterIme: json['volonterIme'] as String?,
      volonterPrezime: json['volonterPrezime'] as String?,
      tipAktivnostiId: json['tipAktivnostiId'] as int,
      tipAktivnostiNaziv: json['tipAktivnostiNaziv'] as String?,
      datumAktivnosti: DateTime.parse(json['datumAktivnosti'] as String),
      brojSati: (json['brojSati'] as num).toDouble(),
      opis: json['opis'] as String?,
    );
  }
}
