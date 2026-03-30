// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ImportNotifier)
final importProvider = ImportNotifierProvider._();

final class ImportNotifierProvider
    extends $NotifierProvider<ImportNotifier, ImportState> {
  ImportNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importNotifierHash();

  @$internal
  @override
  ImportNotifier create() => ImportNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportState>(value),
    );
  }
}

String _$importNotifierHash() => r'61aa9e886e8895ee3a42ea587ef1805d67bf60f5';

abstract class _$ImportNotifier extends $Notifier<ImportState> {
  ImportState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ImportState, ImportState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ImportState, ImportState>,
              ImportState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
