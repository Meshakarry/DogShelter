import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import '../../postavke/data/lookup_api.dart';
import '../../postavke/domain/lookup_item.dart';
import '../data/pocetna_api.dart';
import '../domain/pocetna_dashboard_data.dart';

const _statusPsaConfig = LookupTableConfig(path: '/api/StatusPsa', idKey: 'statusPsaId', label: 'status psa');
const _statusZahtjevaConfig =
    LookupTableConfig(path: '/api/StatusZahtjeva', idKey: 'statusZahtjevaId', label: 'status zahtjeva');

const _statusPsaDostupan = 'Dostupan';
const _statusZahtjevaNaCekanju = 'Na čekanju';

final pocetnaApiProvider = Provider<PocetnaApi>((ref) => PocetnaApi(ref.watch(apiClientProvider)));

final pocetnaDashboardProvider = FutureProvider.autoDispose<PocetnaDashboardData>((ref) async {
  final api = ref.watch(pocetnaApiProvider);
  final client = ref.watch(apiClientProvider);
  final statusPsaApi = LookupApi(client, _statusPsaConfig);
  final statusZahtjevaApi = LookupApi(client, _statusZahtjevaConfig);

  // Every call below is independent, so each future is started immediately and only
  // awaited once its result is actually needed - this keeps them all running concurrently
  // instead of paying for each round-trip sequentially.
  final statusPsaFuture = statusPsaApi.search();
  final statusZahtjevaFuture = statusZahtjevaApi.search();
  final ukupnoPasaFuture = api.countPas();
  final danasnjePosjeteFuture = api.countPosjeteToday();
  final nedavniZahtjeviFuture = api.recentZahtjevi();
  final reportFuture = api.udomljavanjeReport();

  const missing = LookupItem(id: 0, naziv: '');
  final statusPsaList = (await statusPsaFuture).items;
  final statusZahtjevaList = (await statusZahtjevaFuture).items;
  final dostupanId = statusPsaList.firstWhere((item) => item.naziv == _statusPsaDostupan, orElse: () => missing).id;
  final naCekanjuId =
      statusZahtjevaList.firstWhere((item) => item.naziv == _statusZahtjevaNaCekanju, orElse: () => missing).id;

  final dostupnihPasaFuture = api.countPas(statusPsaId: dostupanId);
  final zahtjevaNaCekanjuFuture = api.countZahtjevi(statusZahtjevaId: naCekanjuId);

  return PocetnaDashboardData(
    ukupnoPasa: await ukupnoPasaFuture,
    dostupnihPasa: await dostupnihPasaFuture,
    zahtjevaNaCekanju: await zahtjevaNaCekanjuFuture,
    danasnjePosjete: await danasnjePosjeteFuture,
    nedavniZahtjevi: await nedavniZahtjeviFuture,
    udomljavanjaPoMjesecima: await reportFuture,
  );
});
