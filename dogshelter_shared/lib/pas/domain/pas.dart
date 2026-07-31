import 'age_label.dart';
import 'slika_psa.dart';
import 'spol.dart';

class Pas with AgeLabel {
  Pas({
    required this.pasId,
    required this.naziv,
    required this.rasaId,
    this.rasaNaziv,
    required this.spol,
    this.datumRodjenja,
    this.opis,
    required this.statusPsaId,
    this.statusNaziv,
    required this.velicinaPsaId,
    this.velicinaNaziv,
    this.tezina,
    required this.datumPrijema,
    this.slikaNaslovna,
    required this.vakcinisan,
    required this.sterilizovan,
    required this.aktivan,
    required this.slike,
  });

  final int pasId;
  final String naziv;
  final int rasaId;
  final String? rasaNaziv;
  final Spol spol;
  @override
  final DateTime? datumRodjenja;
  final String? opis;
  final int statusPsaId;
  final String? statusNaziv;
  final int velicinaPsaId;
  final String? velicinaNaziv;
  final double? tezina;
  final DateTime datumPrijema;
  final String? slikaNaslovna;
  final bool vakcinisan;
  final bool sterilizovan;
  final bool aktivan;
  final List<SlikaPsa> slike;

  factory Pas.fromJson(Map<String, dynamic> json) {
    return Pas(
      pasId: json['pasId'] as int,
      naziv: json['naziv'] as String,
      rasaId: json['rasaId'] as int,
      rasaNaziv: json['rasaNaziv'] as String?,
      spol: Spol.fromJson(json['spol'] as String),
      datumRodjenja: json['datumRodjenja'] == null ? null : DateTime.parse(json['datumRodjenja'] as String),
      opis: json['opis'] as String?,
      statusPsaId: json['statusPsaId'] as int,
      statusNaziv: json['statusNaziv'] as String?,
      velicinaPsaId: json['velicinaPsaId'] as int,
      velicinaNaziv: json['velicinaNaziv'] as String?,
      tezina: (json['tezina'] as num?)?.toDouble(),
      datumPrijema: DateTime.parse(json['datumPrijema'] as String),
      slikaNaslovna: json['slikaNaslovna'] as String?,
      vakcinisan: json['vakcinisan'] as bool,
      sterilizovan: json['sterilizovan'] as bool,
      aktivan: json['aktivan'] as bool,
      slike: (json['slike'] as List<dynamic>? ?? [])
          .map((e) => SlikaPsa.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
