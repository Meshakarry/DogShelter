class StatusPosjete {
  StatusPosjete({required this.statusPosjeteId, required this.naziv});

  final int statusPosjeteId;
  final String naziv;

  factory StatusPosjete.fromJson(Map<String, dynamic> json) {
    return StatusPosjete(statusPosjeteId: json['statusPosjeteId'] as int, naziv: json['naziv'] as String);
  }
}
