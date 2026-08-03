import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../domain/dogadjaj.dart';

class DogadjajFormData {
  const DogadjajFormData({
    required this.naziv,
    this.opis,
    required this.datum,
    required this.lokacija,
    required this.aktivan,
  });

  final String naziv;
  final String? opis;
  final DateTime datum;
  final String lokacija;
  final bool aktivan;

  Map<String, String> toFields() {
    return {
      'Naziv': naziv,
      if (opis != null && opis!.isNotEmpty) 'Opis': opis!,
      'Datum': datum.toIso8601String(),
      'Lokacija': lokacija,
      'Aktivan': aktivan.toString(),
    };
  }
}

class DogadjajApi {
  DogadjajApi(this._client);

  final ApiClient _client;

  Future<PagedResult<Dogadjaj>> getDogadjaji({
    required int page,
    int pageSize = 20,
    String? naziv,
    bool? aktivan,
    DateTime? datumOd,
    DateTime? datumDo,
  }) async {
    final json = await _client.get('/api/Dogadjaj', query: {
      'page': page,
      'pageSize': pageSize,
      'naziv': (naziv == null || naziv.isEmpty) ? null : naziv,
      'aktivan': aktivan,
      'datumOd': datumOd?.toIso8601String(),
      'datumDo': datumDo?.toIso8601String(),
    });
    return PagedResult.fromJson(json as Map<String, dynamic>, (item) => Dogadjaj.fromJson(item));
  }

  Future<Dogadjaj> getDogadjajById(int id) async {
    final json = await _client.get('/api/Dogadjaj/$id');
    return Dogadjaj.fromJson(json as Map<String, dynamic>);
  }

  /// Whether the current volunteer is assigned ("zadužen") to the given event - the backend
  /// auto-scopes GET /api/DogadjajVolonter to the caller's own VolonterId for non-admins, so a
  /// non-empty result for this dogadjajId means "yes, I'm assigned".
  Future<bool> isZaduzen(int dogadjajId) async {
    final json = await _client.get('/api/DogadjajVolonter', query: {
      'dogadjajId': dogadjajId,
      'page': 1,
      'pageSize': 1,
    });
    return ((json as Map<String, dynamic>)['totalCount'] as int) > 0;
  }

  /// Admin-only: cover image is required, same as Obavijest.
  Future<Dogadjaj> insert(DogadjajFormData data, File slika) async {
    final json = await _client.multipart(
      'POST',
      '/api/Dogadjaj',
      fields: data.toFields(),
      files: [await http.MultipartFile.fromPath('slika', slika.path)],
    );
    return Dogadjaj.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only: omitting [slika] preserves the existing image server-side.
  Future<Dogadjaj> update(int id, DogadjajFormData data, {File? slika}) async {
    final files = <http.MultipartFile>[
      if (slika != null) await http.MultipartFile.fromPath('slika', slika.path),
    ];
    final json = await _client.multipart('PUT', '/api/Dogadjaj/$id', fields: data.toFields(), files: files);
    return Dogadjaj.fromJson(json as Map<String, dynamic>);
  }

  /// Admin-only: soft-cancel (sets Aktivan=false), not a hard delete - blocked server-side if
  /// already cancelled.
  Future<void> otkazi(int id) => _client.delete('/api/Dogadjaj/$id');
}
