import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dogshelter_shared/auth/application/auth_notifier.dart';
import '../../news/application/news_providers.dart';
import 'package:dogshelter_shared/obavijest/domain/obavijest_list_item.dart';
import 'package:dogshelter_shared/volonter/domain/volonter.dart';
import '../data/home_api.dart';

final Provider<HomeApi> homeApiProvider = Provider<HomeApi>((ref) => HomeApi(ref.watch(apiClientProvider)));

// autoDispose for the same reason as volonterDashboardProvider below - a newly-posted Obavijest
// should show up next time the user lands on Početna, not just after a full app restart.
final latestObavijestiProvider = FutureProvider.autoDispose<List<ObavijestListItem>>((ref) async {
  final result = await ref.watch(newsApiProvider).getObavijesti(page: 1, pageSize: 3);
  return result.items;
});

typedef VolonterDashboard = ({Volonter? profile, int activityCount});

// autoDispose so returning to Početna always refetches instead of showing a cached "Ukupno
// sati"/"Aktivnosti" total from whenever this screen was first visited this session - logging a
// new activity (or an admin editing one on desktop) changes this data from a completely
// different screen, with no shared state this provider would otherwise pick up.
final volonterDashboardProvider = FutureProvider.autoDispose<VolonterDashboard>((ref) async {
  final api = ref.watch(homeApiProvider);
  // Issued together via Future.wait rather than sequentially, since the two calls are
  // independent.
  final results = await Future.wait([api.getMyVolonterProfile(), api.getMyActivityCount()]);
  return (profile: results[0] as Volonter?, activityCount: results[1] as int);
});
