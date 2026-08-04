class MjesecBroj {
  const MjesecBroj({required this.godina, required this.mjesec, required this.mjesecNaziv, required this.broj});

  final int godina;
  final int mjesec;
  final String mjesecNaziv;
  final int broj;

  factory MjesecBroj.fromJson(Map<String, dynamic> json) {
    return MjesecBroj(
      godina: json['godina'] as int,
      mjesec: json['mjesec'] as int,
      mjesecNaziv: json['mjesecNaziv'] as String,
      broj: json['broj'] as int,
    );
  }
}

class RasaBroj {
  const RasaBroj({required this.rasa, required this.broj});

  final String rasa;
  final int broj;

  factory RasaBroj.fromJson(Map<String, dynamic> json) {
    return RasaBroj(
      rasa: json['rasa'] as String? ?? '',
      broj: json['broj'] as int,
    );
  }
}

class UdomljavanjeIzvjestaj {
  const UdomljavanjeIzvjestaj({
    required this.najcescePoRasi,
    required this.poMjesecima,
    required this.ukupno,
  });

  final List<RasaBroj> najcescePoRasi;
  final List<MjesecBroj> poMjesecima;
  final int ukupno;

  factory UdomljavanjeIzvjestaj.fromJson(Map<String, dynamic> json) {
    return UdomljavanjeIzvjestaj(
      najcescePoRasi: (json['najcescePoRasi'] as List<dynamic>? ?? [])
          .map((e) => RasaBroj.fromJson(e as Map<String, dynamic>))
          .toList(),
      poMjesecima: (json['poMjesecima'] as List<dynamic>? ?? [])
          .map((e) => MjesecBroj.fromJson(e as Map<String, dynamic>))
          .toList(),
      ukupno: json['ukupno'] as int,
    );
  }
}

class MjesecSati {
  const MjesecSati({
    required this.godina,
    required this.mjesec,
    required this.mjesecNaziv,
    required this.brojAktivnosti,
    required this.ukupnoSati,
  });

  final int godina;
  final int mjesec;
  final String mjesecNaziv;
  final int brojAktivnosti;
  final double ukupnoSati;

  factory MjesecSati.fromJson(Map<String, dynamic> json) {
    return MjesecSati(
      godina: json['godina'] as int,
      mjesec: json['mjesec'] as int,
      mjesecNaziv: json['mjesecNaziv'] as String? ?? '',
      brojAktivnosti: json['brojAktivnosti'] as int,
      ukupnoSati: (json['ukupnoSati'] as num).toDouble(),
    );
  }
}

class AktivnostVolonteraIzvjestaj {
  const AktivnostVolonteraIzvjestaj({
    required this.poMjesecima,
    required this.ukupnoAktivnosti,
    required this.ukupnoSati,
  });

  final List<MjesecSati> poMjesecima;
  final int ukupnoAktivnosti;
  final double ukupnoSati;

  factory AktivnostVolonteraIzvjestaj.fromJson(Map<String, dynamic> json) {
    return AktivnostVolonteraIzvjestaj(
      poMjesecima: (json['poMjesecima'] as List<dynamic>? ?? [])
          .map((e) => MjesecSati.fromJson(e as Map<String, dynamic>))
          .toList(),
      ukupnoAktivnosti: json['ukupnoAktivnosti'] as int,
      ukupnoSati: (json['ukupnoSati'] as num).toDouble(),
    );
  }
}

class MjesecDonacija {
  const MjesecDonacija({
    required this.godina,
    required this.mjesec,
    required this.mjesecNaziv,
    required this.broj,
    required this.iznos,
  });

  final int godina;
  final int mjesec;
  final String mjesecNaziv;
  final int broj;
  final double iznos;

  factory MjesecDonacija.fromJson(Map<String, dynamic> json) {
    return MjesecDonacija(
      godina: json['godina'] as int,
      mjesec: json['mjesec'] as int,
      mjesecNaziv: json['mjesecNaziv'] as String? ?? '',
      broj: json['broj'] as int,
      iznos: (json['iznos'] as num).toDouble(),
    );
  }
}

class StatusBroj {
  const StatusBroj({required this.status, required this.broj});

  final String status;
  final int broj;

  factory StatusBroj.fromJson(Map<String, dynamic> json) {
    return StatusBroj(
      status: json['status'] as String? ?? '',
      broj: json['broj'] as int,
    );
  }
}

class DonacijaIzvjestaj {
  const DonacijaIzvjestaj({
    required this.novcanePoMjesecima,
    required this.ukupnoBrojNovcanih,
    required this.ukupanIznos,
    required this.poStatusu,
    required this.ukupnoSvih,
  });

  final List<MjesecDonacija> novcanePoMjesecima;
  final int ukupnoBrojNovcanih;
  final double ukupanIznos;
  final List<StatusBroj> poStatusu;
  final int ukupnoSvih;

  factory DonacijaIzvjestaj.fromJson(Map<String, dynamic> json) {
    return DonacijaIzvjestaj(
      novcanePoMjesecima: (json['novcanePoMjesecima'] as List<dynamic>? ?? [])
          .map((e) => MjesecDonacija.fromJson(e as Map<String, dynamic>))
          .toList(),
      ukupnoBrojNovcanih: json['ukupnoBrojNovcanih'] as int,
      ukupanIznos: (json['ukupanIznos'] as num).toDouble(),
      poStatusu: (json['poStatusu'] as List<dynamic>? ?? [])
          .map((e) => StatusBroj.fromJson(e as Map<String, dynamic>))
          .toList(),
      ukupnoSvih: json['ukupnoSvih'] as int,
    );
  }
}
