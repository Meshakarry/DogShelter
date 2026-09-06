class Rasa {
  Rasa({required this.rasaId, required this.naziv});

  final int rasaId;
  final String naziv;

  factory Rasa.fromJson(Map<String, dynamic> json) {
    return Rasa(rasaId: json['rasaId'] as int, naziv: json['naziv'] as String);
  }
}

class StatusPsa {
  StatusPsa({required this.statusPsaId, required this.naziv});

  final int statusPsaId;
  final String naziv;

  factory StatusPsa.fromJson(Map<String, dynamic> json) {
    return StatusPsa(statusPsaId: json['statusPsaId'] as int, naziv: json['naziv'] as String);
  }
}

class VelicinaPsa {
  VelicinaPsa({required this.velicinaPsaId, required this.naziv});

  final int velicinaPsaId;
  final String naziv;

  factory VelicinaPsa.fromJson(Map<String, dynamic> json) {
    return VelicinaPsa(velicinaPsaId: json['velicinaPsaId'] as int, naziv: json['naziv'] as String);
  }
}

class NivoAktivnosti {
  NivoAktivnosti({required this.nivoAktivnostiId, required this.naziv});

  final int nivoAktivnostiId;
  final String naziv;

  factory NivoAktivnosti.fromJson(Map<String, dynamic> json) {
    return NivoAktivnosti(nivoAktivnostiId: json['nivoAktivnostiId'] as int, naziv: json['naziv'] as String);
  }
}
