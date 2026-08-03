import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../domain/obavijest.dart';
import '../domain/obavijest_list_item.dart';

class ObavijestFormData {
  const ObavijestFormData({required this.naslov, required this.sadrzaj, required this.aktivna});

  final String naslov;
  final String sadrzaj;
  final bool aktivna;

  Map<String, String> toFields() {
    return {'Naslov': naslov, 'Sadrzaj': sadrzaj, 'Aktivna': aktivna.toString()};
  }
}

class ObavijestApi {
  ObavijestApi(this._client);

  final ApiClient _client;

  Future<PagedResult<ObavijestListItem>> getObavijesti({
    required int page,
    int pageSize = 20,
    String? naslov,
    bool? aktivna,
    int? autorId,
    DateTime? datumOd,
    DateTime? datumDo,
  }) async {
    final json = await _client.get('/api/Obavijest', query: {
      'page': page,
      'pageSize': pageSize,
      'naslov': (naslov == null || naslov.isEmpty) ? null : naslov,
      'aktivna': aktivna,
      'autorId': autorId,
      'datumOd': datumOd?.toIso8601String(),
      'datumDo': datumDo?.toIso8601String(),
    });
    return PagedResult.fromJson(
      json as Map<String, dynamic>,
      (item) => ObavijestListItem.fromJson(item),
    );
  }

  Future<Obavijest> getObavijestById(int id) async {
    final json = await _client.get('/api/Obavijest/$id');
    return Obavijest.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only: cover image is required on insert - the backend rejects a missing file.
  Future<Obavijest> insert(ObavijestFormData data, File slika) async {
    final json = await _client.multipart(
      'POST',
      '/api/Obavijest',
      fields: data.toFields(),
      files: [await http.MultipartFile.fromPath('slika', slika.path)],
    );
    return Obavijest.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only: omitting [slika] preserves the existing image server-side.
  Future<Obavijest> update(int id, ObavijestFormData data, {File? slika}) async {
    final files = <http.MultipartFile>[
      if (slika != null) await http.MultipartFile.fromPath('slika', slika.path),
    ];
    final json = await _client.multipart('PUT', '/api/Obavijest/$id', fields: data.toFields(), files: files);
    return Obavijest.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only: hard delete - Obavijest has no soft-delete flag (Aktivna is publish status).
  Future<void> delete(int id) => _client.delete('/api/Obavijest/$id');
}
