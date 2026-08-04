import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import '../data/preporuke_api.dart';
import '../domain/preporuceni_pas.dart';

final preporukeApiProvider = Provider<PreporukeApi>((ref) => PreporukeApi(ref.watch(apiClientProvider)));

final preporuceniPsiProvider = FutureProvider<List<PreporuceniPas>>((ref) async {
  return ref.watch(preporukeApiProvider).getPreporuceniPsi(take: 5);
});
