import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final bool isDarkMode;
  final bool pushNotificationsEnabled;
  final bool realtimeStreamEnabled;
  final bool biometricsEnabled;
  final String displayName;
  final String bio;
  final int avatarColorIndex;
  final String activeMarketEnvironment;
  final String tradingStyle;
  final String riskTolerance;
  final double defaultPositionSize;
  final String defaultOrderType;
  final bool showExtendedHours;
  final bool blurBalances;
  final int autoLockMinutes;
  final String quoteStreamSpeed;
  final bool hasCompletedOnboarding;

  const SettingsState({
    this.isDarkMode = false,
    this.pushNotificationsEnabled = true,
    this.realtimeStreamEnabled = true,
    this.biometricsEnabled = false,
    this.displayName = 'Alpha Trader',
    this.bio = 'Active U.S. Equities & Quant Trader',
    this.avatarColorIndex = 0,
    this.activeMarketEnvironment = 'AlphaCues Production',
    this.tradingStyle = 'Swing Trader',
    this.riskTolerance = 'Moderate',
    this.defaultPositionSize = 1000.0,
    this.defaultOrderType = 'Market',
    this.showExtendedHours = true,
    this.blurBalances = false,
    this.autoLockMinutes = 5,
    this.quoteStreamSpeed = 'Real-Time (100ms)',
    this.hasCompletedOnboarding = false,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    bool? pushNotificationsEnabled,
    bool? realtimeStreamEnabled,
    bool? biometricsEnabled,
    String? displayName,
    String? bio,
    int? avatarColorIndex,
    String? activeMarketEnvironment,
    String? tradingStyle,
    String? riskTolerance,
    double? defaultPositionSize,
    String? defaultOrderType,
    bool? showExtendedHours,
    bool? blurBalances,
    int? autoLockMinutes,
    String? quoteStreamSpeed,
    bool? hasCompletedOnboarding,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      realtimeStreamEnabled: realtimeStreamEnabled ?? this.realtimeStreamEnabled,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
      activeMarketEnvironment: activeMarketEnvironment ?? this.activeMarketEnvironment,
      tradingStyle: tradingStyle ?? this.tradingStyle,
      riskTolerance: riskTolerance ?? this.riskTolerance,
      defaultPositionSize: defaultPositionSize ?? this.defaultPositionSize,
      defaultOrderType: defaultOrderType ?? this.defaultOrderType,
      showExtendedHours: showExtendedHours ?? this.showExtendedHours,
      blurBalances: blurBalances ?? this.blurBalances,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      quoteStreamSpeed: quoteStreamSpeed ?? this.quoteStreamSpeed,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void toggleDarkMode(bool value) {
    state = state.copyWith(isDarkMode: value);
  }

  void togglePushNotifications(bool value) {
    state = state.copyWith(pushNotificationsEnabled: value);
  }

  void toggleRealtimeStream(bool value) {
    state = state.copyWith(realtimeStreamEnabled: value);
  }

  void toggleBiometrics(bool value) {
    state = state.copyWith(biometricsEnabled: value);
  }

  void updateProfile({
    required String displayName,
    required String bio,
    int? avatarColorIndex,
    String? tradingStyle,
    String? riskTolerance,
  }) {
    state = state.copyWith(
      displayName: displayName,
      bio: bio,
      avatarColorIndex: avatarColorIndex ?? state.avatarColorIndex,
      tradingStyle: tradingStyle ?? state.tradingStyle,
      riskTolerance: riskTolerance ?? state.riskTolerance,
    );
  }

  void updateTechnicalSettings({
    double? defaultPositionSize,
    String? defaultOrderType,
    bool? showExtendedHours,
    bool? blurBalances,
    int? autoLockMinutes,
    String? quoteStreamSpeed,
  }) {
    state = state.copyWith(
      defaultPositionSize: defaultPositionSize ?? state.defaultPositionSize,
      defaultOrderType: defaultOrderType ?? state.defaultOrderType,
      showExtendedHours: showExtendedHours ?? state.showExtendedHours,
      blurBalances: blurBalances ?? state.blurBalances,
      autoLockMinutes: autoLockMinutes ?? state.autoLockMinutes,
      quoteStreamSpeed: quoteStreamSpeed ?? state.quoteStreamSpeed,
    );
  }

  void completeOnboarding() {
    state = state.copyWith(hasCompletedOnboarding: true);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
});
