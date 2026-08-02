class Notifikacija {
  Notifikacija({
    required this.notifikacijaId,
    required this.tip,
    required this.naslov,
    required this.tekst,
    this.vezaniEntitetId,
    required this.procitano,
    required this.datumKreiranja,
  });

  final int notifikacijaId;
  final String tip;
  final String naslov;
  final String tekst;
  final int? vezaniEntitetId;
  final bool procitano;
  final DateTime datumKreiranja;

  Notifikacija copyWith({bool? procitano}) {
    return Notifikacija(
      notifikacijaId: notifikacijaId,
      tip: tip,
      naslov: naslov,
      tekst: tekst,
      vezaniEntitetId: vezaniEntitetId,
      procitano: procitano ?? this.procitano,
      datumKreiranja: datumKreiranja,
    );
  }

  factory Notifikacija.fromJson(Map<String, dynamic> json) {
    return Notifikacija(
      notifikacijaId: json['notifikacijaId'] as int,
      tip: json['tip'] as String,
      naslov: json['naslov'] as String,
      tekst: json['tekst'] as String,
      vezaniEntitetId: json['vezaniEntitetId'] as int?,
      procitano: json['procitano'] as bool,
      datumKreiranja: DateTime.parse(json['datumKreiranja'] as String),
    );
  }
}
