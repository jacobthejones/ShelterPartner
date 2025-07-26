# Survey Banner Implementation

## Banner Appearance

The survey banner appears at the top of both the Enrichment and Visitor pages with the following design:

```
┌─────────────────────────────────────────────────────────────────────┐
│ 📋 Help improve Shelter Partner with a short survey               ✕ │
│     Take Survey →                                                   │
└─────────────────────────────────────────────────────────────────────┘
```

## Visual Details:
- **Background**: Light blue (`Colors.blue.shade50`)
- **Icon**: Feedback outline icon (📋) in blue
- **Text**: "Help improve Shelter Partner with a short survey" in dark gray
- **Link**: "Take Survey →" in blue with underline
- **Close Button**: Gray X icon on the right side
- **Padding**: 16px horizontal, 12px vertical
- **Full Width**: Spans the entire width of the page

## Behavior:
- Shows automatically for new users
- Can be dismissed by clicking the X
- Auto-expires after 7 days
- Clicking "Take Survey →" opens the survey in a new tab/window
- State persisted in local storage (SharedPreferences)

## Integration:
- Added to both `enrichment_page.dart` and `visitor_page.dart`
- Positioned at the top of the page, above existing content
- Uses Riverpod for state management
- Minimal code changes to existing pages (just 3 lines added to each)

The banner provides a non-intrusive way to collect user feedback while automatically managing its own lifecycle.