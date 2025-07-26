# Survey Banner Firestore Configuration

The survey banner system has been updated to use Firestore for centralized management. This allows administrators to control banner visibility, content, and expiration remotely.

## Firestore Structure

The banner configuration is stored in the `public` collection at document `surveyBanner`:

```firestore
public/surveyBanner {
  message: string,          // The message to display in the banner
  surveyUrl: string,        // The URL to open when "Take Survey" is clicked
  isActive: boolean,        // Whether the banner should be shown
  expiresAt: timestamp,     // Optional expiration date (null for no expiration)
  createdAt: timestamp,     // When the banner was created
  updatedAt: timestamp      // When the banner was last updated
}
```

## Example Document

```json
{
  "message": "Help improve Shelter Partner with a short survey",
  "surveyUrl": "https://docs.google.com/forms/d/e/1FAIpQLSf_YOUR_FORM_ID/viewform",
  "isActive": true,
  "expiresAt": null,
  "createdAt": "2024-01-15T10:00:00Z",
  "updatedAt": "2024-01-15T10:00:00Z"
}
```

## Banner Logic

The banner will be shown if:
1. `isActive` is `true`
2. Either `expiresAt` is `null` OR current time is before `expiresAt`
3. User has not dismissed the banner (stored locally)

## Local Dismissal

User dismissal is still stored locally using SharedPreferences. When a user dismisses a banner, it won't show again for 30 days, allowing new banners to appear even if previous ones were dismissed.

## Implementation Details

- **Model**: `SurveyBanner` in `lib/models/survey_banner.dart`
- **Repository**: `SurveyBannerRepository` in `lib/repositories/survey_banner_repository.dart`  
- **Provider**: `SurveyBannerProvider` in `lib/providers/survey_banner_provider.dart`
- **View**: `SurveyBannerView` in `lib/views/components/survey_banner_view.dart`

## Usage

The banner is currently used in:
- `EnrichmentPage`
- `VisitorPage`

To add to other pages, simply include:
```dart
const SurveyBannerView()
```

## Management

To create or update a banner:
1. Access Firebase Console for the project
2. Navigate to Firestore Database
3. Go to the `public` collection
4. Edit or create the `surveyBanner` document
5. Set the fields as needed
6. Save the document

The changes will be reflected in the app immediately due to real-time Firestore listeners.