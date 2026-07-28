class Dogadjaj {
  Dogadjaj({
    required this.dogadjajId,
    required this.naziv,
    this.opis,
    required this.datum,
    required this.lokacija,
    this.slikaPutanja,
    required this.aktivan,
    required this.brojZaduzenihVolontera,
  });

  final int dogadjajId;
  final String naziv;
  final String? opis;
  final DateTime datum;
  final String lokacija;
  final String? slikaPutanja;
  final bool aktivan;
  final int brojZaduzenihVolontera;

  factory Dogadjaj.fromJson(Map<String, dynamic> json) {
    return Dogadjaj(
      dogadjajId: json['dogadjajId'] as int,
      naziv: json['naziv'] as String,
      opis: json['opis'] as String?,
      datum: DateTime.parse(json['datum'] as String),
      lokacija: json['lokacija'] as String,
      slikaPutanja: json['slikaPutanja'] as String?,
      aktivan: json['aktivan'] as bool,
      brojZaduzenihVolontera: json['brojZaduzenihVolontera'] as int,
    );
  }
}
