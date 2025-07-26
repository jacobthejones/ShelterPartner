import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/survey_banner.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';

class SurveyBannerRepository {
  final FirebaseFirestore _firestore;

  SurveyBannerRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  /// Stream that watches for changes to active survey banners
  Stream<SurveyBanner?> watchActiveSurveyBanner() {
    return _firestore.collection('public').doc('surveyBanner').snapshots().map((
      doc,
    ) {
      if (!doc.exists) {
        return null;
      }
      return SurveyBanner.fromFirestore(doc);
    });
  }

  /// Get the current active survey banner as a one-time fetch
  Future<SurveyBanner?> getActiveSurveyBanner() async {
    try {
      final doc = await _firestore
          .collection('public')
          .doc('surveyBanner')
          .get();

      if (!doc.exists) {
        return null;
      }

      return SurveyBanner.fromFirestore(doc);
    } catch (e) {
      // Return null if there's an error fetching the banner
      return null;
    }
  }
}

/// Provider for SurveyBannerRepository
final surveyBannerRepositoryProvider = Provider<SurveyBannerRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return SurveyBannerRepository(firestore: firestore);
});
