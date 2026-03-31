// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transport_detector.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TransportDetector)
final transportDetectorProvider = TransportDetectorProvider._();

final class TransportDetectorProvider
    extends $NotifierProvider<TransportDetector, TransportType> {
  TransportDetectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transportDetectorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transportDetectorHash();

  @$internal
  @override
  TransportDetector create() => TransportDetector();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransportType value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransportType>(value),
    );
  }
}

String _$transportDetectorHash() => r'73781151c54d3c501c9259185dfdb536db3d94b9';

abstract class _$TransportDetector extends $Notifier<TransportType> {
  TransportType build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TransportType, TransportType>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TransportType, TransportType>,
              TransportType,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
