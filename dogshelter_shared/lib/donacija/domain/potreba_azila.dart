class PotrebaAzila {
  PotrebaAzila({
    required this.potrebaAzilaId,
    required this.naziv,
    required this.opis,
    required this.prioritetPotrebeId,
    this.prioritetPotrebeNaziv,
    required this.ikonaKljuc,
    required this.aktivna,
    required this.datumKreiranja,
  });

  final int potrebaAzilaId;
  final String naziv;
  final String opis;
  final int prioritetPotrebeId;
  final String? prioritetPotrebeNaziv;
  final String ikonaKljuc;
  final bool aktivna;
  final DateTime datumKreiranja;

  factory PotrebaAzila.fromJson(Map<String, dynamic> json) {
    return PotrebaAzila(
      potrebaAzilaId: json['potrebaAzilaId'] as int,
      naziv: json['naziv'] as String,
      opis: json['opis'] as String,
      prioritetPotrebeId: json['prioritetPotrebeId'] as int,
      prioritetPotrebeNaziv: json['prioritetPotrebeNaziv'] as String?,
      ikonaKljuc: json['ikonaKljuc'] as String,
      aktivna: json['aktivna'] as bool,
      datumKreiranja: DateTime.parse(json['datumKreiranja'] as String),
    );
  }
}
