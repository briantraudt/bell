# Bell iOS

A fully native SwiftUI application for older adults living independently.

## Open in Xcode

This repository includes `project.yml` for XcodeGen. Install XcodeGen (`brew install xcodegen`), then run:

```bash
xcodegen generate
open Bell.xcodeproj
```

The first build runs with local demo data. Add a publishable Supabase key using a local xcconfig before enabling live data.

## First release implemented

- Accessible tile-based home (`1a`)
- Home help, ride, grocery, and family flows
- Ask Bell chat and listening UI
- Provider discovery and detail
- Plans, reminders, profile, and HELP flow
- Bell design tokens and reusable components
- Supabase client foundation and RLS-first initial schema

## Accessibility baseline

Bell uses 64-point minimum controls, large text, explicit selected states, VoiceOver labels, scroll-safe layouts, no auto-advancing UI, and confirmation screens rather than disappearing alerts.
