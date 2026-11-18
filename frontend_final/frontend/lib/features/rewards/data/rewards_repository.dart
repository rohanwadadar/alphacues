import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session_provider.dart';

class RewardsInfo {
  const RewardsInfo({
    required this.balance,
    required this.tier,
    required this.pointsToNextTier,
    required this.targetTier,
    required this.referralCode,
    required this.referralUrl,
    required this.shareText,
    required this.whatsappUrl,
    required this.metaUrl,
    this.twitterUrl = '',
    this.instagramUrl = '',
    this.gmailUrl = '',
    required this.redemptionStatus,
    required this.redemptionNotice,
  });

  final int balance;
  final String tier;
  final int pointsToNextTier;
  final String targetTier;
  final String referralCode;
  final String referralUrl;
  final String shareText;
  final String whatsappUrl;
  final String metaUrl;
  final String twitterUrl;
  final String instagramUrl;
  final String gmailUrl;
  final String redemptionStatus;
  final String redemptionNotice;

  String get effectiveTwitterUrl => twitterUrl.isNotEmpty
      ? twitterUrl
      : 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(shareText)}';

  String get effectiveWhatsappUrl => whatsappUrl.isNotEmpty
      ? whatsappUrl
      : 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(shareText)}';

  String get effectiveMetaUrl => metaUrl.isNotEmpty
      ? metaUrl
      : 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(referralUrl)}';

  String get effectiveGmailUrl => gmailUrl.isNotEmpty
      ? gmailUrl
      : 'https://mail.google.com/mail/?view=cm&fs=1&su=${Uri.encodeComponent('Join me on AlphaCues - Simulation Trading Rewards')}&body=${Uri.encodeComponent(shareText)}';

  String get effectiveInstagramUrl => instagramUrl.isNotEmpty
      ? instagramUrl
      : 'https://www.instagram.com/';

  factory RewardsInfo.fromJson(Map<String, dynamic> json) {
    final shareUrls = json['shareUrls'] as Map<String, dynamic>? ?? {};
    final shareText = json['shareText'] as String? ?? 'Join me on AlphaCues!';
    final referralUrl = json['referralUrl'] as String? ?? 'https://alphacues.com';
    return RewardsInfo(
      balance: (json['balance'] as num?)?.toInt() ?? 1420,
      tier: json['tier'] as String? ?? 'Silver Tier Trader',
      pointsToNextTier: (json['pointsToNextTier'] as num?)?.toInt() ?? 580,
      targetTier: json['targetTier'] as String? ?? 'Gold Tier Trader',
      referralCode: json['referralCode'] as String? ?? 'ALPHA-VIP-2026',
      referralUrl: referralUrl,
      shareText: shareText,
      whatsappUrl: shareUrls['whatsapp'] as String? ?? '',
      metaUrl: shareUrls['meta'] as String? ?? '',
      twitterUrl: shareUrls['twitter'] as String? ?? '',
      instagramUrl: shareUrls['instagram'] as String? ?? '',
      gmailUrl: shareUrls['gmail'] as String? ?? '',
      redemptionStatus: json['redemptionStatus'] as String? ?? 'Coming Soon',
      redemptionNotice: json['redemptionNotice'] as String? ??
          'Redeem Credits — Coming Soon! Points can soon be redeemed for pro quant tools, fee rebates, and exclusive indicators.',
    );
  }
}

class RewardsRepository {
  RewardsRepository(this._dio);

  final Dio _dio;

  Future<RewardsInfo> getRewardsInfo() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/rewards');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final innerData = data['data'];
        if (innerData is Map<String, dynamic>) {
          return RewardsInfo.fromJson(innerData);
        }
      }
      return const RewardsInfo(
        balance: 1420,
        tier: 'Silver Tier Trader',
        pointsToNextTier: 580,
        targetTier: 'Gold Tier Trader',
        referralCode: 'ALPHA-VIP-2026',
        referralUrl: 'https://alphacues.com',
        shareText: 'Join me on AlphaCues!',
        whatsappUrl: '',
        metaUrl: '',
        redemptionStatus: 'Coming Soon',
        redemptionNotice: 'Redeem Credits — Coming Soon! Points can soon be redeemed for pro quant tools, fee rebates, and exclusive indicators.',
      );
    } catch (_) {
      return const RewardsInfo(
        balance: 1420,
        tier: 'Silver Tier Trader',
        pointsToNextTier: 580,
        targetTier: 'Gold Tier Trader',
        referralCode: 'ALPHA-VIP-2026',
        referralUrl: 'https://alphacues.com',
        shareText: 'Join me on AlphaCues!',
        whatsappUrl: '',
        metaUrl: '',
        redemptionStatus: 'Coming Soon',
        redemptionNotice: 'Redeem Credits — Coming Soon! Points can soon be redeemed for pro quant tools, fee rebates, and exclusive indicators.',
      );
    }
  }

  Future<Map<String, dynamic>> claimReferral(String referralCode) async {
    final response = await _dio.post<dynamic>(
      '/api/v1/rewards/claim',
      data: {'referralCode': referralCode},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final innerData = data['data'];
      if (innerData is Map<String, dynamic>) {
        return innerData;
      }
      return data;
    }
    return {};
  }
}

final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return RewardsRepository(dio);
});

final rewardsProvider = FutureProvider.autoDispose<RewardsInfo>((ref) async {
  final repository = ref.watch(rewardsRepositoryProvider);
  return repository.getRewardsInfo();
});
