class Donacija {
  Donacija({
    required this.donacijaId,
    required this.korisnikId,
    this.korisnikIme,
    this.korisnikPrezime,
    required this.tipDonacijeId,
    this.tipDonacijeNaziv,
    required this.statusDonacijeId,
    this.statusDonacijeNaziv,
    this.iznos,
    required this.datumDonacije,
    this.napomena,
    this.obradioKorisnikId,
    this.obradioKorisnikIme,
    this.obradioKorisnikPrezime,
    this.datumObrade,
    this.razlogOdbijanja,
    this.razlogVracanja,
    required this.isPaid,
    this.kategorijaDonacijeId,
    this.kategorijaDonacijeNaziv,
    this.prilagodjenNaziv,
    this.kolicina,
    this.jedinicaMjereId,
    this.jedinicaMjereNaziv,
    required this.trebaPreuzimanje,
    this.adresaPreuzimanja,
    this.telefonPreuzimanja,
    this.datumPreuzimanja,
    this.zeljeniDatumDostave,
  });

  final int donacijaId;
  final int korisnikId;
  final String? korisnikIme;
  final String? korisnikPrezime;
  final int tipDonacijeId;
  final String? tipDonacijeNaziv;
  final int statusDonacijeId;
  final String? statusDonacijeNaziv;
  final double? iznos;
  final DateTime datumDonacije;
  final String? napomena;
  final int? obradioKorisnikId;
  final String? obradioKorisnikIme;
  final String? obradioKorisnikPrezime;
  final DateTime? datumObrade;
  final String? razlogOdbijanja;
  final String? razlogVracanja;
  final bool isPaid;

  // --- Materijalna donacija details (null/false for Novčana) ---
  final int? kategorijaDonacijeId;
  final String? kategorijaDonacijeNaziv;
  final String? prilagodjenNaziv;
  final double? kolicina;
  final int? jedinicaMjereId;
  final String? jedinicaMjereNaziv;
  final bool trebaPreuzimanje;
  final String? adresaPreuzimanja;
  final String? telefonPreuzimanja;
  final DateTime? datumPreuzimanja;
  final DateTime? zeljeniDatumDostave;

  bool get isNovcana => tipDonacijeNaziv == 'Novčana';

  /// The category name shown to the user - when the category is the generic "Ostalo", the
  /// donor's own custom item name is shown instead.
  String? get prikazNazivStavke =>
      (kategorijaDonacijeNaziv == 'Ostalo' && prilagodjenNaziv != null && prilagodjenNaziv!.isNotEmpty)
          ? prilagodjenNaziv
          : kategorijaDonacijeNaziv;

  factory Donacija.fromJson(Map<String, dynamic> json) {
    return Donacija(
      donacijaId: json['donacijaId'] as int,
      korisnikId: json['korisnikId'] as int,
      korisnikIme: json['korisnikIme'] as String?,
      korisnikPrezime: json['korisnikPrezime'] as String?,
      tipDonacijeId: json['tipDonacijeId'] as int,
      tipDonacijeNaziv: json['tipDonacijeNaziv'] as String?,
      statusDonacijeId: json['statusDonacijeId'] as int,
      statusDonacijeNaziv: json['statusDonacijeNaziv'] as String?,
      iznos: (json['iznos'] as num?)?.toDouble(),
      datumDonacije: DateTime.parse(json['datumDonacije'] as String),
      napomena: json['napomena'] as String?,
      obradioKorisnikId: json['obradioKorisnikId'] as int?,
      obradioKorisnikIme: json['obradioKorisnikIme'] as String?,
      obradioKorisnikPrezime: json['obradioKorisnikPrezime'] as String?,
      datumObrade: json['datumObrade'] == null ? null : DateTime.parse(json['datumObrade'] as String),
      razlogOdbijanja: json['razlogOdbijanja'] as String?,
      razlogVracanja: json['razlogVracanja'] as String?,
      isPaid: json['isPaid'] as bool,
      kategorijaDonacijeId: json['kategorijaDonacijeId'] as int?,
      kategorijaDonacijeNaziv: json['kategorijaDonacijeNaziv'] as String?,
      prilagodjenNaziv: json['prilagodjenNaziv'] as String?,
      kolicina: (json['kolicina'] as num?)?.toDouble(),
      jedinicaMjereId: json['jedinicaMjereId'] as int?,
      jedinicaMjereNaziv: json['jedinicaMjereNaziv'] as String?,
      trebaPreuzimanje: json['trebaPreuzimanje'] as bool? ?? false,
      adresaPreuzimanja: json['adresaPreuzimanja'] as String?,
      telefonPreuzimanja: json['telefonPreuzimanja'] as String?,
      datumPreuzimanja: json['datumPreuzimanja'] == null ? null : DateTime.parse(json['datumPreuzimanja'] as String),
      zeljeniDatumDostave:
          json['zeljeniDatumDostave'] == null ? null : DateTime.parse(json['zeljeniDatumDostave'] as String),
    );
  }
}

class DonacijaPaymentResponse {
  DonacijaPaymentResponse({required this.donacija, this.clientSecret});

  final Donacija donacija;
  final String? clientSecret;

  factory DonacijaPaymentResponse.fromJson(Map<String, dynamic> json) {
    return DonacijaPaymentResponse(
      donacija: Donacija.fromJson(json['donacija'] as Map<String, dynamic>),
      clientSecret: json['clientSecret'] as String?,
    );
  }
}
