// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PostListNotifier)
final postListProvider = PostListNotifierFamily._();

final class PostListNotifierProvider
    extends $AsyncNotifierProvider<PostListNotifier, List<Post>> {
  PostListNotifierProvider._({
    required PostListNotifierFamily super.from,
    required (String, {bool? pinnedOnly}) super.argument,
  }) : super(
         retry: null,
         name: r'postListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postListNotifierHash();

  @override
  String toString() {
    return r'postListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PostListNotifier create() => PostListNotifier();

  @override
  bool operator ==(Object other) {
    return other is PostListNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postListNotifierHash() => r'773d4e72f3ff140fe82d8f078bcede5b5eea5997';

final class PostListNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PostListNotifier,
          AsyncValue<List<Post>>,
          List<Post>,
          FutureOr<List<Post>>,
          (String, {bool? pinnedOnly})
        > {
  PostListNotifierFamily._()
    : super(
        retry: null,
        name: r'postListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PostListNotifierProvider call(String bandId, {bool? pinnedOnly}) =>
      PostListNotifierProvider._(
        argument: (bandId, pinnedOnly: pinnedOnly),
        from: this,
      );

  @override
  String toString() => r'postListProvider';
}

abstract class _$PostListNotifier extends $AsyncNotifier<List<Post>> {
  late final _$args = ref.$arg as (String, {bool? pinnedOnly});
  String get bandId => _$args.$1;
  bool? get pinnedOnly => _$args.pinnedOnly;

  FutureOr<List<Post>> build(String bandId, {bool? pinnedOnly});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Post>>, List<Post>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Post>>, List<Post>>,
              AsyncValue<List<Post>>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(_$args.$1, pinnedOnly: _$args.pinnedOnly),
    );
  }
}

@ProviderFor(PostDetailNotifier)
final postDetailProvider = PostDetailNotifierFamily._();

final class PostDetailNotifierProvider
    extends $AsyncNotifierProvider<PostDetailNotifier, Post> {
  PostDetailNotifierProvider._({
    required PostDetailNotifierFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'postDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postDetailNotifierHash();

  @override
  String toString() {
    return r'postDetailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PostDetailNotifier create() => PostDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is PostDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postDetailNotifierHash() =>
    r'5c4c04f01f7789ee13eb1d0f4f91d827471a5d6d';

final class PostDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PostDetailNotifier,
          AsyncValue<Post>,
          Post,
          FutureOr<Post>,
          (String, String)
        > {
  PostDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'postDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PostDetailNotifierProvider call(String bandId, String postId) =>
      PostDetailNotifierProvider._(argument: (bandId, postId), from: this);

  @override
  String toString() => r'postDetailProvider';
}

abstract class _$PostDetailNotifier extends $AsyncNotifier<Post> {
  late final _$args = ref.$arg as (String, String);
  String get bandId => _$args.$1;
  String get postId => _$args.$2;

  FutureOr<Post> build(String bandId, String postId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Post>, Post>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Post>, Post>,
              AsyncValue<Post>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

@ProviderFor(PostCommentsNotifier)
final postCommentsProvider = PostCommentsNotifierFamily._();

final class PostCommentsNotifierProvider
    extends $AsyncNotifierProvider<PostCommentsNotifier, List<Comment>> {
  PostCommentsNotifierProvider._({
    required PostCommentsNotifierFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'postCommentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$postCommentsNotifierHash();

  @override
  String toString() {
    return r'postCommentsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PostCommentsNotifier create() => PostCommentsNotifier();

  @override
  bool operator ==(Object other) {
    return other is PostCommentsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$postCommentsNotifierHash() =>
    r'6f15ea79569e2f783f46417a08bf764274a6e4fe';

final class PostCommentsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PostCommentsNotifier,
          AsyncValue<List<Comment>>,
          List<Comment>,
          FutureOr<List<Comment>>,
          (String, String)
        > {
  PostCommentsNotifierFamily._()
    : super(
        retry: null,
        name: r'postCommentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PostCommentsNotifierProvider call(String bandId, String postId) =>
      PostCommentsNotifierProvider._(argument: (bandId, postId), from: this);

  @override
  String toString() => r'postCommentsProvider';
}

abstract class _$PostCommentsNotifier extends $AsyncNotifier<List<Comment>> {
  late final _$args = ref.$arg as (String, String);
  String get bandId => _$args.$1;
  String get postId => _$args.$2;

  FutureOr<List<Comment>> build(String bandId, String postId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Comment>>, List<Comment>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Comment>>, List<Comment>>,
              AsyncValue<List<Comment>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
