import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:dogshelter_shared/core/api_client.dart';
import 'package:dogshelter_shared/core/paged_result.dart';
import '../domain/lookups.dart';
import '../domain/pas.dart';
import '../domain/pas_list_item.dart';
import '../domain/slika_psa.dart';
import '../domain/spol.dart';

class PasFormData {
  const PasFormData({
    required this.naziv,
    required this.rasaId,
    required this.spol,
    this.datumRodjenja,
    this.opis,
    required this.statusPsaId,
    required this.velicinaPsaId,
    this.tezina,
    required this.datumPrijema,
    required this.vakcinisan,
    required this.sterilizovan,
    this.aktivan,
  });

  final String naziv;
  final int rasaId;
  final Spol spol;
  final DateTime? datumRodjenja;
  final String? opis;
  final int statusPsaId;
  final int velicinaPsaId;
  final double? tezina;
  final DateTime datumPrijema;
  final bool vakcinisan;
  final bool sterilizovan;

  /// Only sent on update - a brand-new Pas always defaults to active server-side.
  final bool? aktivan;

  Map<String, String> toFields() {
    final fields = <String, String>{
      'Naziv': naziv,
      'RasaId': rasaId.toString(),
      'Spol': spol.toJson(),
      'StatusPsaId': statusPsaId.toString(),
      'VelicinaPsaId': velicinaPsaId.toString(),
      'DatumPrijema': datumPrijema.toIso8601String(),
      'Vakcinisan': vakcinisan.toString(),
      'Sterilizovan': sterilizovan.toString(),
    };
    if (datumRodjenja != null) fields['DatumRodjenja'] = datumRodjenja!.toIso8601String();
    if (opis != null && opis!.isNotEmpty) fields['Opis'] = opis!;
    if (tezina != null) fields['Tezina'] = tezina!.toString();
    if (aktivan != null) fields['Aktivan'] = aktivan!.toString();
    return fields;
  }
}

class PasApi {
  PasApi(this._client);

  final ApiClient _client;

  Future<PagedResult<PasListItem>> getDogs({
    required int page,
    int pageSize = 20,
    String? naziv,
    int? rasaId,
    int? statusPsaId,
    int? velicinaPsaId,
    Spol? spol,
    bool? aktivan,
  }) async {
    final json = await _client.get('/api/Pas', query: {
      'page': page,
      'pageSize': pageSize,
      'naziv': (naziv == null || naziv.isEmpty) ? null : naziv,
      'rasaId': rasaId,
      'statusPsaId': statusPsaId,
      'velicinaPsaId': velicinaPsaId,
      'spol': spol?.toJson(),
      'aktivan': aktivan,
    });
    return PagedResult.fromJson(
      json as Map<String, dynamic>,
      (item) => PasListItem.fromJson(item),
    );
  }

  Future<Pas> getDogById(int id) async {
    final json = await _client.get('/api/Pas/$id');
    return Pas.fromJson(json as Map<String, dynamic>);
  }

  // Lookup tables are small (well under the server's 100-row page cap), so a single
  // pageSize=100 request is enough to get the full list for a dropdown - no pagination UI needed here.
  Future<List<Rasa>> getRase() async {
    final json = await _client.get('/api/Rasa', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => Rasa.fromJson(item));
    return result.items;
  }

  Future<List<StatusPsa>> getStatusi() async {
    final json = await _client.get('/api/StatusPsa', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => StatusPsa.fromJson(item));
    return result.items;
  }

  Future<List<VelicinaPsa>> getVelicine() async {
    final json = await _client.get('/api/VelicinaPsa', query: {'pageSize': 100});
    final result = PagedResult.fromJson(json as Map<String, dynamic>, (item) => VelicinaPsa.fromJson(item));
    return result.items;
  }

  Future<Pas> insert(PasFormData data, File coverImage) async {
    final json = await _client.multipart(
      'POST',
      '/api/Pas',
      fields: data.toFields(),
      files: [await http.MultipartFile.fromPath('slikaNaslovna', coverImage.path)],
    );
    return Pas.fromJson(json as Map<String, dynamic>);
  }

  Future<Pas> update(int id, PasFormData data, {File? coverImage}) async {
    final files = <http.MultipartFile>[
      if (coverImage != null) await http.MultipartFile.fromPath('slikaNaslovna', coverImage.path),
    ];
    final json = await _client.multipart('PUT', '/api/Pas/$id', fields: data.toFields(), files: files);
    return Pas.fromJson(json as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete('/api/Pas/$id');

  Future<SlikaPsa> addGalleryImage(int pasId, File image, int redniBroj) async {
    final json = await _client.multipart(
      'POST',
      '/api/Pas/$pasId/slike',
      fields: {'redniBroj': redniBroj.toString()},
      files: [await http.MultipartFile.fromPath('slika', image.path)],
    );
    return SlikaPsa.fromJson(json as Map<String, dynamic>);
  }

  Future<void> deleteGalleryImage(int pasId, int slikaId) => _client.delete('/api/Pas/$pasId/slike/$slikaId');
}
