import 'package:go_router/go_router.dart';
import 'package:sheetstorm/features/substitute/presentation/screens/substitute_management_screen.dart';
import 'package:sheetstorm/features/substitute/presentation/screens/substitute_link_screen.dart';

/// Route definitions for Substitute Access feature.
/// DO NOT modify app_router.dart — these routes are registered separately.

final substituteRoutes = [
  GoRoute(
    path: 'substitutes',
    builder: (context, state) {
      final bandId = state.uri.queryParameters['bandId'] ?? '';
      return SubstituteManagementScreen(bandId: bandId);
    },
  ),
  GoRoute(
    path: 'substitute/link',
    builder: (context, state) {
      final link = state.extra; // SubstituteLink passed as argument
      return SubstituteLinkScreen(link: link as dynamic);
    },
  ),
];
