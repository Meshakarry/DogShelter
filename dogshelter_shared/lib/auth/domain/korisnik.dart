class Uloga {
  Uloga({required this.ulogaId, required this.naziv});

  final int ulogaId;
  final String naziv;

  factory Uloga.fromJson(Map<String, dynamic> json) {
    return Uloga(ulogaId: json['ulogaId'] as int, naziv: json['naziv'] as String);
  }

  Map<String, dynamic> toJson() => {'ulogaId': ulogaId, 'naziv': naziv};
}

class KorisnikUloga {
  KorisnikUloga({required this.korisnikUlogaId, required this.korisnikId, required this.ulogaId, this.uloga});

  final int korisnikUlogaId;
  final int korisnikId;
  final int ulogaId;
  final Uloga? uloga;

  factory KorisnikUloga.fromJson(Map<String, dynamic> json) {
    return KorisnikUloga(
      korisnikUlogaId: json['korisnikUlogaId'] as int,
      korisnikId: json['korisnikId'] as int,
      ulogaId: json['ulogaId'] as int,
      uloga: json['uloga'] == null ? null : Uloga.fromJson(json['uloga'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'korisnikUlogaId': korisnikUlogaId,
        'korisnikId': korisnikId,
        'ulogaId': ulogaId,
        'uloga': uloga?.toJson(),
      };
}

class Korisnik {
  Korisnik({
    required this.korisnikId,
    required this.ime,
    required this.prezime,
    required this.email,
    this.telefon,
    this.gradId,
    this.adresa,
    required this.korisnickoIme,
    required this.aktivan,
    this.slikaPutanja,
    required this.datumRegistracije,
    required this.korisnikUloge,
  });

  final int korisnikId;
  final String ime;
  final String prezime;
  final String email;
  final String? telefon;
  final int? gradId;
  final String? adresa;
  final String korisnickoIme;
  final bool aktivan;
  final String? slikaPutanja;
  final DateTime datumRegistracije;
  final List<KorisnikUloga> korisnikUloge;

  List<String> get roles =>
      korisnikUloge.map((ku) => ku.uloga?.naziv).whereType<String>().toList();

  bool hasRole(String role) => roles.any((r) => r.toLowerCase() == role.toLowerCase());

  factory Korisnik.fromJson(Map<String, dynamic> json) {
    return Korisnik(
      korisnikId: json['korisnikId'] as int,
      ime: json['ime'] as String,
      prezime: json['prezime'] as String,
      email: json['email'] as String,
      telefon: json['telefon'] as String?,
      gradId: json['gradId'] as int?,
      adresa: json['adresa'] as String?,
      korisnickoIme: json['korisnickoIme'] as String,
      aktivan: json['aktivan'] as bool,
      slikaPutanja: json['slikaPutanja'] as String?,
      datumRegistracije: DateTime.parse(json['datumRegistracije'] as String),
      korisnikUloge: (json['korisnikUloge'] as List<dynamic>? ?? [])
          .map((e) => KorisnikUloga.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'korisnikId': korisnikId,
        'ime': ime,
        'prezime': prezime,
        'email': email,
        'telefon': telefon,
        'gradId': gradId,
        'adresa': adresa,
        'korisnickoIme': korisnickoIme,
        'aktivan': aktivan,
        'slikaPutanja': slikaPutanja,
        'datumRegistracije': datumRegistracije.toIso8601String(),
        'korisnikUloge': korisnikUloge.map((ku) => ku.toJson()).toList(),
      };
}
