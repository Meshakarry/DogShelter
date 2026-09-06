import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import '../data/preporuke_api.dart';
import '../domain/preporuceni_pas.dart';

final preporukeApiProvider = Provider<PreporukeApi>((ref) => PreporukeApi(ref.watch(apiClientProvider)));

// autoDispose so returning to Početna always refetches - the recommender's signals (pregledi,
// favoriti, zahtjevi, posjete, pretrage) change with nearly everything the user does elsewhere
// in the app, so a cached-forever result would go stale almost immediately.
final preporuceniPsiProvider = FutureProvider.autoDispose<List<PreporuceniPas>>((ref) async {
  return ref.watch(preporukeApiProvider).getPreporuceniPsi(take: 5);
});
