import 'package:cloud_firestore/cloud_firestore.dart';

class SurveyBanner {
  final String id;
  final String message;
  final String surveyUrl;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SurveyBanner({
    required this.id,
    required this.message,
    required this.surveyUrl,
    required this.isActive,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SurveyBanner.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SurveyBanner(
      id: doc.id,
      message:
          data['message'] ?? 'Help improve Shelter Partner with a short survey',
      surveyUrl: data['surveyUrl'] ?? '',
      isActive: data['isActive'] ?? false,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'surveyUrl': surveyUrl,
      'isActive': isActive,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SurveyBanner copyWith({
    String? id,
    String? message,
    String? surveyUrl,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SurveyBanner(
      id: id ?? this.id,
      message: message ?? this.message,
      surveyUrl: surveyUrl ?? this.surveyUrl,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if the banner should be shown based on its configuration
  bool shouldShow() {
    if (!isActive) {
      return false;
    }

    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
      return false;
    }

    return true;
  }
}
