enum Spol {
  zenka,
  muzjak;

  static Spol fromJson(String value) {
    switch (value) {
      case 'Muzjak':
        return Spol.muzjak;
      case 'Zenka':
        return Spol.zenka;
      default:
        throw ArgumentError('Nepoznat spol: $value');
    }
  }

  String toJson() => this == Spol.muzjak ? 'Muzjak' : 'Zenka';

  String get label => this == Spol.muzjak ? 'Mužjak' : 'Ženka';
}
