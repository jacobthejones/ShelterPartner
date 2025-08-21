import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';

class ApiKeyBannerState {
  final bool shouldShow;
  final bool isDismissed;

  const ApiKeyBannerState({
    required this.shouldShow,
    required this.isDismissed,
  });

  ApiKeyBannerState copyWith({bool? shouldShow, bool? isDismissed}) {
    return ApiKeyBannerState(
      shouldShow: shouldShow ?? this.shouldShow,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}

class ApiKeyBannerNotifier extends StateNotifier<ApiKeyBannerState> {
  static const String _dismissedKey = 'api_key_banner_dismissed_at';

  final Ref _ref;

  ApiKeyBannerNotifier(this._ref)
    : super(const ApiKeyBannerState(shouldShow: false, isDismissed: false)) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Load dismissal state from local storage
    final isDismissed = await _loadDismissalState();

    // Listen to shelter settings changes to determine if API key is missing
    _ref.listen(shelterSettingsViewModelProvider, (previous, next) {
      next.whenOrNull(
        data: (shelter) {
          final hasApiKey = shelter?.shelterSettings.apiKey.isNotEmpty ?? false;
          final shouldShow = !hasApiKey && !isDismissed;

          state = state.copyWith(
            shouldShow: shouldShow,
            isDismissed: isDismissed,
          );
        },
      );
    });

    // Check current state immediately
    final shelterAsyncValue = _ref.read(shelterSettingsViewModelProvider);
    shelterAsyncValue.whenOrNull(
      data: (shelter) {
        final hasApiKey = shelter?.shelterSettings.apiKey.isNotEmpty ?? false;
        final shouldShow = !hasApiKey && !isDismissed;

        state = state.copyWith(
          shouldShow: shouldShow,
          isDismissed: isDismissed,
        );
      },
    );
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

final apiKeyBannerProvider =
    StateNotifierProvider<ApiKeyBannerNotifier, ApiKeyBannerState>((ref) {
      return ApiKeyBannerNotifier(ref);
    });
