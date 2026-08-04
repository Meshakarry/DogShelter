import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import '../../news/application/news_providers.dart';
import 'package:dogshelter_shared/obavijest/domain/obavijest_list_item.dart';
import 'package:dogshelter_shared/volonter/domain/volonter.dart';
import '../data/home_api.dart';

final Provider<HomeApi> homeApiProvider = Provider<HomeApi>((ref) => HomeApi(ref.watch(apiClientProvider)));

final latestObavijestiProvider = FutureProvider<List<ObavijestListItem>>((ref) async {
  final result = await ref.watch(newsApiProvider).getObavijesti(page: 1, pageSize: 3);
  return result.items;
});

typedef VolonterDashboard = ({Volonter? profile, int activityCount});

final volonterDashboardProvider = FutureProvider<VolonterDashboard>((ref) async {
  final api = ref.watch(homeApiProvider);
  // Issued together via Future.wait rather than sequentially, since the two calls are
  // independent.
  final results = await Future.wait([api.getMyVolonterProfile(), api.getMyActivityCount()]);
  return (profile: results[0] as Volonter?, activityCount: results[1] as int);
});
