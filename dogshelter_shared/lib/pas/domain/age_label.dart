/// Shared age computation for any dog model exposing `datumRodjenja`.
mixin AgeLabel {
  DateTime? get datumRodjenja;

  int? get ageYears {
    final born = datumRodjenja;
    if (born == null) return null;
    final now = DateTime.now();
    var years = now.year - born.year;
    if (now.month < born.month || (now.month == born.month && now.day < born.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
  }

  /// Avoids the misleading "0 god." for puppies under a year old.
  String? get ageLabel {
    final years = ageYears;
    if (years == null) return null;
    return years == 0 ? '<1 god.' : '$years god.';
  }
}
