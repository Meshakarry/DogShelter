import 'age_label.dart';
import 'spol.dart';

class PasListItem with AgeLabel {
  PasListItem({
    required this.pasId,
    required this.naziv,
    required this.rasaId,
    this.rasaNaziv,
    required this.spol,
    this.datumRodjenja,
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
  });

  final int pasId;
  final String naziv;
  final int rasaId;
  final String? rasaNaziv;
  final Spol spol;
  @override
  final DateTime? datumRodjenja;
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

  factory PasListItem.fromJson(Map<String, dynamic> json) {
    return PasListItem(
      pasId: json['pasId'] as int,
      naziv: json['naziv'] as String,
      rasaId: json['rasaId'] as int,
      rasaNaziv: json['rasaNaziv'] as String?,
      spol: Spol.fromJson(json['spol'] as String),
      datumRodjenja: json['datumRodjenja'] == null ? null : DateTime.parse(json['datumRodjenja'] as String),
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
    );
  }
}
