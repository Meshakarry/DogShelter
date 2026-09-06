class Favorit {
  Favorit({
    required this.favoritId,
    required this.korisnikId,
    required this.pasId,
    required this.datumDodavanja,
    required this.pasNaziv,
    this.rasaNaziv,
    this.velicinaNaziv,
    required this.slikaNaslovna,
    this.statusNaziv,
    required this.pasAktivan,
  });

  final int favoritId;
  final int korisnikId;
  final int pasId;
  final DateTime datumDodavanja;
  final String pasNaziv;
  final String? rasaNaziv;
  final String? velicinaNaziv;
  final String slikaNaslovna;
  final String? statusNaziv;
  final bool pasAktivan;

  factory Favorit.fromJson(Map<String, dynamic> json) {
    return Favorit(
      favoritId: json['favoritId'] as int,
      korisnikId: json['korisnikId'] as int,
      pasId: json['pasId'] as int,
      datumDodavanja: DateTime.parse(json['datumDodavanja'] as String),
      pasNaziv: json['pasNaziv'] as String,
      rasaNaziv: json['rasaNaziv'] as String?,
      velicinaNaziv: json['velicinaNaziv'] as String?,
      slikaNaslovna: json['slikaNaslovna'] as String,
      statusNaziv: json['statusNaziv'] as String?,
      pasAktivan: json['pasAktivan'] as bool,
    );
  }
}
