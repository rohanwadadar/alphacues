import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Registry of user-scoped Riverpod providers invalidated on logout / auth failure.
///
/// Add feature repository/controller providers here as they are introduced.
final userScopedProviderKeys = <ProviderOrFamily>[];

void invalidateUserScopedProviders(Ref ref) {
  for (final provider in userScopedProviderKeys) {
    ref.invalidate(provider);
  }
}
