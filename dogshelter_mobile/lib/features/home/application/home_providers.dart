import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import 'package:dogshelter_shared/pas/domain/pas_list_item.dart';
import '../../dogs/application/dogs_providers.dart';
import '../../news/application/news_providers.dart';
import '../../news/domain/obavijest_list_item.dart';
import '../data/home_api.dart';
import '../domain/volonter_summary.dart';

final Provider<HomeApi> homeApiProvider = Provider<HomeApi>((ref) => HomeApi(ref.watch(apiClientProvider)));

final latestObavijestiProvider = FutureProvider<List<ObavijestListItem>>((ref) async {
  final result = await ref.watch(newsApiProvider).getObavijesti(page: 1, pageSize: 3);
  return result.items;
});

final recommendedDogsProvider = FutureProvider<List<PasListItem>>((ref) async {
  final result = await ref.watch(dogsApiProvider).getDogs(page: 1, pageSize: 3);
  return result.items;
});

typedef VolonterDashboard = ({VolonterSummary? profile, int activityCount});

final volonterDashboardProvider = FutureProvider<VolonterDashboard>((ref) async {
  final api = ref.watch(homeApiProvider);
  // Issued together via Future.wait rather than sequentially, since the two calls are
  // independent.
  final results = await Future.wait([api.getMyVolonterProfile(), api.getMyActivityCount()]);
  return (profile: results[0] as VolonterSummary?, activityCount: results[1] as int);
});
