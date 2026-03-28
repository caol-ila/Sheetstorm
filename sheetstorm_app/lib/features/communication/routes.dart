import 'package:go_router/go_router.dart';
import 'package:sheetstorm/features/communication/presentation/screens/board_screen.dart';
import 'package:sheetstorm/features/communication/presentation/screens/post_detail_screen.dart';
import 'package:sheetstorm/features/communication/presentation/screens/poll_detail_screen.dart';
import 'package:sheetstorm/features/communication/presentation/screens/create_poll_screen.dart';

/// Named routes for Communication module
abstract final class CommunicationRoutes {
  static const String board = '/app/board';
  static String postDetail({required String bandId, required String postId}) =>
      '/app/board/$bandId/posts/$postId';
  static String pollDetail({required String bandId, required String pollId}) =>
      '/app/board/$bandId/polls/$pollId';
  static String createPoll({required String bandId}) =>
      '/app/board/$bandId/polls/create';
}

/// GoRoute definitions for communication screens
/// DO NOT modify app_router.dart — add these routes via shell branch
final communicationRoutes = [
  GoRoute(
    path: '/board',
    builder: (context, state) => const BoardScreen(),
    routes: [
      GoRoute(
        path: ':bandId/posts/:postId',
        builder: (context, state) => PostDetailScreen(
          bandId: state.pathParameters['bandId']!,
          postId: state.pathParameters['postId']!,
        ),
      ),
      GoRoute(
        path: ':bandId/polls/:pollId',
        builder: (context, state) => PollDetailScreen(
          bandId: state.pathParameters['bandId']!,
          pollId: state.pathParameters['pollId']!,
        ),
      ),
      GoRoute(
        path: ':bandId/polls/create',
        builder: (context, state) => CreatePollScreen(
          bandId: state.pathParameters['bandId']!,
        ),
      ),
    ],
  ),
];
