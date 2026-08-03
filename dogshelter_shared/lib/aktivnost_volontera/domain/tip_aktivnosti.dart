class TipAktivnosti {
  TipAktivnosti({required this.tipAktivnostiId, required this.naziv});

  final int tipAktivnostiId;
  final String naziv;

  factory TipAktivnosti.fromJson(Map<String, dynamic> json) {
    return TipAktivnosti(tipAktivnostiId: json['tipAktivnostiId'] as int, naziv: json['naziv'] as String);
  }
}
