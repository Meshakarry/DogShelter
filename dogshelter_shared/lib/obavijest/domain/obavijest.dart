class Obavijest {
  Obavijest({
    required this.obavijestId,
    required this.naslov,
    required this.sadrzaj,
    required this.slikaPutanja,
    required this.datumObjave,
    required this.autorId,
    this.autorIme,
    this.autorPrezime,
    required this.aktivna,
  });

  final int obavijestId;
  final String naslov;
  final String sadrzaj;
  final String slikaPutanja;
  final DateTime datumObjave;
  final int autorId;
  final String? autorIme;
  final String? autorPrezime;
  final bool aktivna;

  factory Obavijest.fromJson(Map<String, dynamic> json) {
    return Obavijest(
      obavijestId: json['obavijestId'] as int,
      naslov: json['naslov'] as String,
      sadrzaj: json['sadrzaj'] as String,
      slikaPutanja: json['slikaPutanja'] as String,
      datumObjave: DateTime.parse(json['datumObjave'] as String),
      autorId: json['autorId'] as int,
      autorIme: json['autorIme'] as String?,
      autorPrezime: json['autorPrezime'] as String?,
      aktivna: json['aktivna'] as bool,
    );
  }
}
