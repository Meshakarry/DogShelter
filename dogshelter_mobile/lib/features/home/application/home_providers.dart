import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_notifier.dart';
import '../../dogs/application/dogs_providers.dart';
import '../../dogs/domain/pas_list_item.dart';
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
  // Issued together, not sequentially, per the parallelizable-HTTP-calls rule.
  final results = await Future.wait([api.getMyVolonterProfile(), api.getMyActivityCount()]);
  return (profile: results[0] as VolonterSummary?, activityCount: results[1] as int);
});
