import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import '../data/reports_api.dart';
import '../domain/report_models.dart';

class IzvjestajFilter {
  const IzvjestajFilter({this.datumOd, this.datumDo});

  final DateTime? datumOd;
  final DateTime? datumDo;

  IzvjestajFilter copyWith({DateTime? datumOd, bool clearDatumOd = false, DateTime? datumDo, bool clearDatumDo = false}) {
    return IzvjestajFilter(
      datumOd: clearDatumOd ? null : (datumOd ?? this.datumOd),
      datumDo: clearDatumDo ? null : (datumDo ?? this.datumDo),
    );
  }
}

final izvjestajFilterProvider = StateProvider<IzvjestajFilter>((ref) => const IzvjestajFilter());

final reportsApiProvider = Provider<ReportsApi>((ref) => ReportsApi(ref.watch(apiClientProvider)));

final udomljavanjeIzvjestajProvider = FutureProvider.autoDispose<UdomljavanjeIzvjestaj>((ref) {
  final filter = ref.watch(izvjestajFilterProvider);
  return ref.watch(reportsApiProvider).getUdomljavanjeReport(datumOd: filter.datumOd, datumDo: filter.datumDo);
});

final aktivnostVolonteraIzvjestajProvider = FutureProvider.autoDispose<AktivnostVolonteraIzvjestaj>((ref) {
  final filter = ref.watch(izvjestajFilterProvider);
  return ref.watch(reportsApiProvider).getAktivnostVolonteraReport(datumOd: filter.datumOd, datumDo: filter.datumDo);
});

final donacijaIzvjestajProvider = FutureProvider.autoDispose<DonacijaIzvjestaj>((ref) {
  final filter = ref.watch(izvjestajFilterProvider);
  return ref.watch(reportsApiProvider).getDonacijaReport(datumOd: filter.datumOd, datumDo: filter.datumDo);
});
