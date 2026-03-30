import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/features/substitute/application/pending_substitute_link_provider.dart';
import 'package:sheetstorm/features/substitute/presentation/screens/substitute_management_screen.dart';
import 'package:sheetstorm/features/substitute/presentation/screens/substitute_link_screen.dart';
import 'package:sheetstorm/features/substitute/presentation/screens/substitute_qr_screen.dart';

/// Route definitions for Substitute Access feature.
/// DO NOT modify app_router.dart — these routes are registered separately.

final substituteRoutes = [
  GoRoute(
    path: 'substitutes',
    builder: (context, state) {
      final bandId = state.pathParameters['bandId'] ?? '';
      return SubstituteManagementScreen(bandId: bandId);
    },
  ),
  GoRoute(
    path: 'substitute/link',
    builder: (context, state) {
      // Link is stored in pendingSubstituteLinkProvider after creation.
      // If null (e.g., direct navigation), pop back to avoid broken state.
      return Consumer(
        builder: (context, ref, _) {
          final link = ref.watch(pendingSubstituteLinkProvider);
          if (link == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.pop();
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return SubstituteLinkScreen(link: link);
        },
      );
    },
  ),
  GoRoute(
    path: 'substitute/qr/:accessId',
    builder: (context, state) {
      final bandId = state.pathParameters['bandId'] ?? '';
      final accessId = state.pathParameters['accessId'] ?? '';
      return SubstituteQrScreen(bandId: bandId, accessId: accessId);
    },
  ),
];
