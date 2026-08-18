import '../storage/secure_token_store.dart';

export '../storage/secure_token_store.dart'
    show InMemorySecureTokenStore, SecureTokenStore, secureTokenStoreProvider;

/// Back-compat alias for [SecureTokenStore].
typedef AuthTokenStore = SecureTokenStore;

/// Back-compat alias for [secureTokenStoreProvider].
final authTokenStoreProvider = secureTokenStoreProvider;

/// Back-compat alias for [InMemorySecureTokenStore].
typedef InMemoryAuthTokenStore = InMemorySecureTokenStore;