class ObavijestPreview {
  ObavijestPreview({
    required this.obavijestId,
    required this.naslov,
    required this.slikaPutanja,
    required this.datumObjave,
  });

  final int obavijestId;
  final String naslov;
  final String slikaPutanja;
  final DateTime datumObjave;

  factory ObavijestPreview.fromJson(Map<String, dynamic> json) {
    return ObavijestPreview(
      obavijestId: json['obavijestId'] as int,
      naslov: json['naslov'] as String,
      slikaPutanja: json['slikaPutanja'] as String,
      datumObjave: DateTime.parse(json['datumObjave'] as String),
    );
  }
}
