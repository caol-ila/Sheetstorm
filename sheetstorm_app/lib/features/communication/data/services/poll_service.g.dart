// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poll_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pollService)
final pollServiceProvider = PollServiceProvider._();

final class PollServiceProvider
    extends $FunctionalProvider<PollService, PollService, PollService>
    with $Provider<PollService> {
  PollServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pollServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pollServiceHash();

  @$internal
  @override
  $ProviderElement<PollService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PollService create(Ref ref) {
    return pollService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PollService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PollService>(value),
    );
  }
}

String _$pollServiceHash() => r'587a1efcd600ffbbf660068f0257a95e9fb728e4';
