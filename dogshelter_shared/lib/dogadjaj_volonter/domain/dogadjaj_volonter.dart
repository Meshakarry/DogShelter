class DogadjajVolonter {
  DogadjajVolonter({
    required this.dogadjajVolonterId,
    required this.dogadjajId,
    this.dogadjajNaziv,
    this.dogadjajDatum,
    this.dogadjajLokacija,
    required this.volonterId,
    required this.korisnikId,
    this.volonterIme,
    this.volonterPrezime,
  });

  final int dogadjajVolonterId;
  final int dogadjajId;
  final String? dogadjajNaziv;
  final DateTime? dogadjajDatum;
  final String? dogadjajLokacija;
  final int volonterId;
  final int korisnikId;
  final String? volonterIme;
  final String? volonterPrezime;

  factory DogadjajVolonter.fromJson(Map<String, dynamic> json) {
    return DogadjajVolonter(
      dogadjajVolonterId: json['dogadjajVolonterId'] as int,
      dogadjajId: json['dogadjajId'] as int,
      dogadjajNaziv: json['dogadjajNaziv'] as String?,
      dogadjajDatum: json['dogadjajDatum'] == null ? null : DateTime.parse(json['dogadjajDatum'] as String),
      dogadjajLokacija: json['dogadjajLokacija'] as String?,
      volonterId: json['volonterId'] as int,
      korisnikId: json['korisnikId'] as int,
      volonterIme: json['volonterIme'] as String?,
      volonterPrezime: json['volonterPrezime'] as String?,
    );
  }
}
