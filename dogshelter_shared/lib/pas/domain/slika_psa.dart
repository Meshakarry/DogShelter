class SlikaPsa {
  SlikaPsa({required this.slikaPsaId, required this.pasId, required this.putanja, required this.redniBroj});

  final int slikaPsaId;
  final int pasId;
  final String putanja;
  final int redniBroj;

  factory SlikaPsa.fromJson(Map<String, dynamic> json) {
    return SlikaPsa(
      slikaPsaId: json['slikaPsaId'] as int,
      pasId: json['pasId'] as int,
      putanja: json['putanja'] as String,
      redniBroj: json['redniBroj'] as int,
    );
  }
}
