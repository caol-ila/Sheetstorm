import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/services/api_client.dart';

final pingProvider = FutureProvider<String>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  return apiClient.ping();
});
