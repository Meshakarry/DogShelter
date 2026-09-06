class ZahtjevZaUdomljavanje {
  ZahtjevZaUdomljavanje({
    required this.zahtjevZaUdomljavanjeId,
    required this.korisnikId,
    this.korisnikIme,
    this.korisnikPrezime,
    required this.pasId,
    this.pasNaziv,
    this.pasSlikaNaslovna,
    this.pasAktivan = true,
    this.pasStatusNaziv,
    required this.statusZahtjevaId,
    this.statusZahtjevaNaziv,
    required this.datumPodnosenja,
    this.napomena,
    this.datumObrade,
    this.obradioKorisnikId,
    this.obradioKorisnikIme,
    this.obradioKorisnikPrezime,
    this.razlogOdbijanja,
    this.udomljenjeFinalizovano = false,
  });

  final int zahtjevZaUdomljavanjeId;
  final int korisnikId;
  final String? korisnikIme;
  final String? korisnikPrezime;
  final int pasId;
  final String? pasNaziv;
  final String? pasSlikaNaslovna;

  // Whether the dog is still adoptable *right now* - may have changed since the request was
  // submitted (deactivated, or reserved/adopted via a different request). Used to disable
  // "Odobri" instead of letting the click round-trip to the backend's own re-check.
  final bool pasAktivan;
  final String? pasStatusNaziv;
  final int statusZahtjevaId;
  final String? statusZahtjevaNaziv;
  final DateTime datumPodnosenja;
  final String? napomena;
  final DateTime? datumObrade;
  final int? obradioKorisnikId;
  final String? obradioKorisnikIme;
  final String? obradioKorisnikPrezime;
  final String? razlogOdbijanja;

  // True once the adoption has actually been finalized (an Udomljavanje row exists) - a request
  // stays "Odobren" forever after approval, so this is what tells an old, already-completed
  // adoption apart from one still waiting on FinalizirajUdomljenje.
  final bool udomljenjeFinalizovano;

  factory ZahtjevZaUdomljavanje.fromJson(Map<String, dynamic> json) {
    return ZahtjevZaUdomljavanje(
      zahtjevZaUdomljavanjeId: json['zahtjevZaUdomljavanjeId'] as int,
      korisnikId: json['korisnikId'] as int,
      korisnikIme: json['korisnikIme'] as String?,
      korisnikPrezime: json['korisnikPrezime'] as String?,
      pasId: json['pasId'] as int,
      pasNaziv: json['pasNaziv'] as String?,
      pasSlikaNaslovna: json['pasSlikaNaslovna'] as String?,
      pasAktivan: json['pasAktivan'] as bool? ?? true,
      pasStatusNaziv: json['pasStatusNaziv'] as String?,
      statusZahtjevaId: json['statusZahtjevaId'] as int,
      statusZahtjevaNaziv: json['statusZahtjevaNaziv'] as String?,
      datumPodnosenja: DateTime.parse(json['datumPodnosenja'] as String),
      napomena: json['napomena'] as String?,
      datumObrade: json['datumObrade'] == null ? null : DateTime.parse(json['datumObrade'] as String),
      obradioKorisnikId: json['obradioKorisnikId'] as int?,
      obradioKorisnikIme: json['obradioKorisnikIme'] as String?,
      obradioKorisnikPrezime: json['obradioKorisnikPrezime'] as String?,
      razlogOdbijanja: json['razlogOdbijanja'] as String?,
      udomljenjeFinalizovano: json['udomljenjeFinalizovano'] as bool? ?? false,
    );
  }
}
