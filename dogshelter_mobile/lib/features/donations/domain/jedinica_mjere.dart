class JedinicaMjere {
  JedinicaMjere({required this.jedinicaMjereId, required this.naziv});

  final int jedinicaMjereId;
  final String naziv;

  factory JedinicaMjere.fromJson(Map<String, dynamic> json) {
    return JedinicaMjere(jedinicaMjereId: json['jedinicaMjereId'] as int, naziv: json['naziv'] as String);
  }
}
