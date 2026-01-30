# 🚐 Drift — High-Level Architecture Overview

## ✨ Overview

Drift is a native iOS app for the van life/RV community. It lets users discover other travelers, find campgrounds, plan activities, and connect via messaging. The app is invite-only and monetizes through a premium subscription tier (“Drift Pro”).

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Platform** | iOS 17+, Swift 5.9+, Xcode workspace |
| **UI** | SwiftUI |
| **Backend services** | Local Swift package (singleton managers, async/await) |
| **Auth & data** | Supabase (Auth, Postgres, Realtime, Storage, Edge Functions) |
| **Subscriptions** | RevenueCat + App Store (auto-renewable) |
| **Push** | Firebase Cloud Messaging (FCM) |
| **Campgrounds** | Campflare API |
| **Other** | VerifyFaceID (verification), Unsplash (event imagery) |

The main app links to the backend package and to Firebase/RevenueCat via SPM. All network and backend access use async/await; managers are main-actor isolated for UI-safe updates.

---

## 🏗️ Architecture

### 🚀 App entry and flow

- **Entry** — App initializes the backend with API keys from gitignored config, then wires auth, subscription, and profile managers for the UI.
- **Auth-driven routing** — Unauthenticated users see sign-in (Apple / Google / Email). Authenticated users go through invite check, then either onboarding, preference selection, or the main tab experience.
- **Onboarding** — Completion is stored in Supabase user metadata and profiles. Flows include full onboarding (9+ screens), friend-only onboarding, preference selection, and a welcome splash.

### 📦 Backend package

A single local Swift package holds all backend logic and shared models. The app imports it and configures it once at launch (Supabase, Campflare, RevenueCat, VerifyFaceID, Unsplash).

**Managers (singletons, main-actor):**

- **Supabase** 🔐 — Auth (Apple, Google, email), session, user metadata, invite state, onboarding/welcome flags.
- **Profile** 👤 — Current user profile CRUD, travel schedule, prompts; used for onboarding completion.
- **RevenueCat** 💳 — Subscription lifecycle, entitlement checks, purchase/restore, customer center.
- **Campflare** 🏕️ — Campground search and availability.
- **Friends** 👥 — Friends, swipes, connections.
- **Messaging** 💬 — Conversations and messages.
- **Activity** 📅 — Activities/events.
- **Community** 🧑‍🤝‍🧑 — Community posts and events.
- **Invite** 🎫 — Invite codes (generate, redeem, check).
- **VanBuilder** 🚐 — Van builder feature data.
- **VerifyFaceID** 📸 — Face verification.
- **Unsplash** 🖼️ — Event header images.

**Models** — User profile, campground/campsite/availability, conversation/activity, subscription plan, and related types used by the app and the package.

### 🧭 State and navigation

- **State** — Auth and high-level flow live in the Supabase manager; subscription state in the RevenueCat manager; profile in the Profile manager. UI observes these via observed/state objects.
- **Navigation** — Tab bar with Discover, Community, Map, Messages, Profile. Full-screen views and sheets (paywall, map, edit profile, message threads) are presented from tabs or during onboarding.

### 🔐 Configuration

API keys live in gitignored config; the app passes them into the backend at startup. Example config files are committed; real keys are not.

---

## ☁️ Backend and Data (Supabase)

- **Auth** 🔑 — Supabase Auth with Apple, Google, and email. Session drives app routing and RLS.
- **Database** 📊 — Postgres with Row Level Security. Core areas: profiles (extends auth), travel schedule, friends/connections, conversations/messages, activities, community/events, van builder. Schema is managed via migrations.
- **Storage** 📁 — Buckets for user uploads (avatars, photos) with RLS policies.
- **Edge Functions** ⚡ — Server-side logic for account deletion, invite generation, and invite redemption.
- **Realtime** 🔄 — Used where needed (e.g. event messages, attendees).

---

## 💳 RevenueCat Integration and Monetization

### 🎯 Model

- **Tier** — Free (with limits) and **Drift Pro** (paid).
- **Entitlement** — Single entitlement “Drift Pro”. Pro access is gated by checking that entitlement in the RevenueCat manager.

### 📦 Products (App Store + RevenueCat)

- **Monthly** — Auto-renewable at $11.99/month.
- **Yearly** — Auto-renewable at $79.99/year.
- Both live in one subscription group in App Store Connect and are attached to the Drift Pro entitlement and to a default offering in RevenueCat.

### 📱 App-side implementation

- **Config** — RevenueCat API key, entitlement ID, and product IDs are provided at app init and passed into the backend package.
- **Identity** — On login, the app logs the user into RevenueCat with their Supabase user ID so subscriptions follow the account across devices. On logout, RevenueCat is logged out.
- **Lifecycle** — The RevenueCat manager configures the SDK at init, loads offerings and customer info, and stays in sync via the SDK delegate so entitlement state is always current.
- **Paywall** — A dedicated paywall presents the default offering (monthly/yearly), handles purchase and restore, and can open the system subscription management UI.
- **Pro gating** — Features that require Pro check the RevenueCat manager’s entitlement flag; subscription status is also shown in the profile area.

---

## 🔌 Third-Party Services

- **Campflare** 🏕️ — Campground search and availability.
- **Firebase** 🔥 — FCM for push; app delegate registers for remote notifications and forwards tokens. Other Firebase products (e.g. Analytics, Crashlytics) are available via dependencies.
- **VerifyFaceID** 📸 — Face verification flow.
- **Unsplash** 🖼️ — Optional event header images.

---

## 🎨 Design and UI

- **Design system** — Custom colors (e.g. BurntOrange, Charcoal), custom fonts, and shared styles for buttons, tags, and text.
- **Structure** — Main tabs; full-screen views (map, paywall, welcome, edit profile, van builder, etc.); modals/sheets for flows; dedicated onboarding flows.
