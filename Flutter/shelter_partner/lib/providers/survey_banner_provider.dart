import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelter_partner/models/survey_banner.dart';
import 'package:shelter_partner/repositories/survey_banner_repository.dart';

class SurveyBannerState {
  final bool shouldShow;
  final SurveyBanner? bannerConfig;
  final bool isDismissed;

  const SurveyBannerState({
    required this.shouldShow,
    this.bannerConfig,
    required this.isDismissed,
  });

  SurveyBannerState copyWith({
    bool? shouldShow,
    SurveyBanner? bannerConfig,
    bool? isDismissed,
  }) {
    return SurveyBannerState(
      shouldShow: shouldShow ?? this.shouldShow,
      bannerConfig: bannerConfig ?? this.bannerConfig,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}

class SurveyBannerNotifier extends StateNotifier<SurveyBannerState> {
  static const String _dismissedKey = 'survey_banner_dismissed_at';

  final SurveyBannerRepository _repository;

  SurveyBannerNotifier(this._repository)
    : super(const SurveyBannerState(shouldShow: false, isDismissed: false)) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Load dismissal state from local storage
    final isDismissed = await _loadDismissalState();

    // Set up stream to watch for banner configuration changes
    _repository.watchActiveSurveyBanner().listen((bannerConfig) {
      _updateBannerState(bannerConfig, isDismissed);
    });
  }

  Future<bool> _loadDismissalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissedAtString = prefs.getString(_dismissedKey);

      if (dismissedAtString != null) {
        final dismissedAt = DateTime.parse(dismissedAtString);
        // Check if dismissal was within the last 24 hours
        final hoursSinceDismissal = DateTime.now()
            .difference(dismissedAt)
            .inHours;
        return hoursSinceDismissal < 24;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  void _updateBannerState(SurveyBanner? bannerConfig, bool isDismissed) {
    if (bannerConfig == null) {
      state = state.copyWith(
        shouldShow: false,
        bannerConfig: null,
        isDismissed: isDismissed,
      );
      return;
    }

    final shouldShow = bannerConfig.shouldShow() && !isDismissed;

    state = state.copyWith(
      shouldShow: shouldShow,
      bannerConfig: bannerConfig,
      isDismissed: isDismissed,
    );
  }

  Future<void> dismissBanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString(_dismissedKey, now.toIso8601String());

      state = state.copyWith(shouldShow: false, isDismissed: true);
    } catch (e) {
      // Handle error silently, just update state
      state = state.copyWith(shouldShow: false, isDismissed: true);
    }
  }
}

final surveyBannerProvider =
    StateNotifierProvider<SurveyBannerNotifier, SurveyBannerState>((ref) {
      final repository = ref.watch(surveyBannerRepositoryProvider);
      return SurveyBannerNotifier(repository);
    });
