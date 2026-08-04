class PreporuceniPas {
  PreporuceniPas({
    required this.pasId,
    required this.naziv,
    required this.rasaNaziv,
    required this.velicinaNaziv,
    required this.slikaNaslovna,
    this.datumRodjenja,
    required this.skor,
    required this.razlog,
    required this.personalizovano,
  });

  final int pasId;
  final String naziv;
  final String rasaNaziv;
  final String velicinaNaziv;
  final String slikaNaslovna;
  final DateTime? datumRodjenja;
  final double skor;
  final String razlog;
  final bool personalizovano;

  factory PreporuceniPas.fromJson(Map<String, dynamic> json) {
    return PreporuceniPas(
      pasId: json['pasId'] as int,
      naziv: json['naziv'] as String,
      rasaNaziv: json['rasaNaziv'] as String,
      velicinaNaziv: json['velicinaNaziv'] as String,
      slikaNaslovna: json['slikaNaslovna'] as String,
      datumRodjenja: json['datumRodjenja'] == null ? null : DateTime.parse(json['datumRodjenja'] as String),
      skor: (json['skor'] as num).toDouble(),
      razlog: json['razlog'] as String,
      personalizovano: json['personalizovano'] as bool,
    );
  }
}
