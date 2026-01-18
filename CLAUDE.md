# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Drift is a native iOS app built with SwiftUI for the van life/RV community. It enables users to discover other travelers, find campgrounds, plan activities, and connect via messaging.

## Project Structure

This is an Xcode workspace containing:
- **Drift.xcodeproj** - The main iOS app
- **DriftBackend/** - Local Swift package containing all backend services and models

## Build Commands

Open workspace in Xcode:
```bash
open Drift.xcworkspace
# Then Cmd+R to build and run
```

Build from command line:
```bash
xcodebuild -workspace Drift.xcworkspace -scheme Drift -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Run tests:
```bash
xcodebuild -workspace Drift.xcworkspace -scheme Drift -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Architecture

### DriftBackend Package (`DriftBackend/`)
Local Swift package containing all backend services. Import with `import DriftBackend`.

**Managers (singletons):**
- `SupabaseManager.shared` - Authentication (Apple Sign In, email), user metadata, onboarding state
- `CampflareManager.shared` - Campground search and availability API
- `RevenueCatManager.shared` - In-app subscriptions ("Drift Pro")

**Models:**
- `Campground`, `Campsite`, `Availability` - Campflare API models
- `CampgroundSearchRequest`, `CampgroundSearchResponse` - Search types
- `SubscriptionPlan` - RevenueCat subscription plans

**Configuration:**
Call `initializeDriftBackend()` in app init (see `BackendConfig.swift`) before using any managers.

### App Entry & Navigation
- `DriftApp.swift` - App entry point, initializes DriftBackend, handles auth state routing
- `ContentView.swift` - Main container with tab-based navigation via `BottomNav`
- `BackendConfig.swift` - Configures DriftBackend with API keys from gitignored config files

### Config Files (gitignored)
API keys stored in `Drift/Network/`:
- `SupabaseConfig.swift` - Supabase URL and anon key
- `CampflareConfig.swift` - Campflare API key

### Screens Structure
- **Tabs/** - Main app screens: DiscoverScreen, ActivitiesScreen, BuilderScreen, MessagesScreen, ProfileScreen
- **Screens/** - Full-screen views: MapScreen, PaywallScreen, WelcomeScreen, VanBuilderCommunity
- **Sheets/** - Modal presentations: CreateActivitySheet, EditProfileSheet, ActivityDetailSheet, MessageDetailScreen
- **Onboarding/** - New user flow (9 screens): Name, Birthday, Location, Interests, Lifestyle, etc.
- **FriendOnboarding/** - Alternative "friends only" onboarding flow

### State Management
- Managers accessed via `.shared` singletons with `@ObservedObject`/`@StateObject`
- User authentication state drives app flow via `isAuthenticated`, `showOnboarding`, `showWelcomeSplash` flags
- Onboarding completion tracked in Supabase user metadata (`onboarding_completed` key)

### Design System
- Custom colors in `Assets.xcassets`: BurntOrange, Charcoal
- Custom fonts in `Drift/Fonts/`
- Components in `Drift/Components/`: ProfileCard, FriendCard, ActivityCard, SubscriptionStatusView

## Key Patterns

### Async/Await
All network calls use Swift concurrency:
```swift
Task {
    await SupabaseManager.shared.checkAuthStatus()
}
```

### MainActor Managers
All managers are `@MainActor` annotated for thread-safe UI updates.

### Subscription Entitlements
Check pro access via `RevenueCatManager.shared.hasProAccess`. Entitlement ID is "Drift Pro".

## Dependencies

**DriftBackend package:**
- `supabase-swift` - Backend authentication and database
- `purchases-ios-spm` (RevenueCat) - Subscription management

**Main app:** Links to DriftBackend local package
