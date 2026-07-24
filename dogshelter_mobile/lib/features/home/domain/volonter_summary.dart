class VolonterSummary {
  VolonterSummary({
    required this.volonterId,
    required this.datumPridruzivanja,
    required this.aktivan,
    required this.ukupnoSati,
  });

  final int volonterId;
  final DateTime datumPridruzivanja;
  final bool aktivan;
  final double ukupnoSati;

  factory VolonterSummary.fromJson(Map<String, dynamic> json) {
    return VolonterSummary(
      volonterId: json['volonterId'] as int,
      datumPridruzivanja: DateTime.parse(json['datumPridruzivanja'] as String),
      aktivan: json['aktivan'] as bool,
      ukupnoSati: (json['ukupnoSati'] as num).toDouble(),
    );
  }
}
