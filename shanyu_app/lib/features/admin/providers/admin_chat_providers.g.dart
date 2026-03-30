// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adminChatRepositoryHash() =>
    r'25acb4982b9d8b257f99ff7304e9907da2e72329';

/// See also [adminChatRepository].
@ProviderFor(adminChatRepository)
final adminChatRepositoryProvider = Provider<AdminChatRepository>.internal(
  adminChatRepository,
  name: r'adminChatRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminChatRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminChatRepositoryRef = ProviderRef<AdminChatRepository>;
String _$allChatsHash() => r'2a0c497d2f175f9a5b4388c43dc5187df755beaf';

/// See also [allChats].
@ProviderFor(allChats)
final allChatsProvider = AutoDisposeStreamProvider<List<ChatSummary>>.internal(
  allChats,
  name: r'allChatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allChatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllChatsRef = AutoDisposeStreamProviderRef<List<ChatSummary>>;
String _$adminChatMessagesHash() => r'd41a7af81a6c2b65140957627a9a46ea4c493ef6';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [adminChatMessages].
@ProviderFor(adminChatMessages)
const adminChatMessagesProvider = AdminChatMessagesFamily();

/// See also [adminChatMessages].
class AdminChatMessagesFamily extends Family<AsyncValue<List<ChatMessage>>> {
  /// See also [adminChatMessages].
  const AdminChatMessagesFamily();

  /// See also [adminChatMessages].
  AdminChatMessagesProvider call(String userId) {
    return AdminChatMessagesProvider(userId);
  }

  @override
  AdminChatMessagesProvider getProviderOverride(
    covariant AdminChatMessagesProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'adminChatMessagesProvider';
}

/// See also [adminChatMessages].
class AdminChatMessagesProvider
    extends AutoDisposeStreamProvider<List<ChatMessage>> {
  /// See also [adminChatMessages].
  AdminChatMessagesProvider(String userId)
    : this._internal(
        (ref) => adminChatMessages(ref as AdminChatMessagesRef, userId),
        from: adminChatMessagesProvider,
        name: r'adminChatMessagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$adminChatMessagesHash,
        dependencies: AdminChatMessagesFamily._dependencies,
        allTransitiveDependencies:
            AdminChatMessagesFamily._allTransitiveDependencies,
        userId: userId,
      );

  AdminChatMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    Stream<List<ChatMessage>> Function(AdminChatMessagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdminChatMessagesProvider._internal(
        (ref) => create(ref as AdminChatMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ChatMessage>> createElement() {
    return _AdminChatMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminChatMessagesProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AdminChatMessagesRef on AutoDisposeStreamProviderRef<List<ChatMessage>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _AdminChatMessagesProviderElement
    extends AutoDisposeStreamProviderElement<List<ChatMessage>>
    with AdminChatMessagesRef {
  _AdminChatMessagesProviderElement(super.provider);

  @override
  String get userId => (origin as AdminChatMessagesProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
