# RevenueCat Integration Guide for Drift

This guide provides step-by-step instructions for completing the RevenueCat integration in your Drift app.

## Step 1: Add RevenueCat SDK via Swift Package Manager

1. Open your Xcode project
2. Go to **File** → **Add Package Dependencies...**
3. Enter the URL: `https://github.com/RevenueCat/purchases-ios`
4. Select **Up to Next Major Version** and choose the latest version (recommended: 5.x or later)
5. Click **Add Package**
6. Select the **RevenueCat** library and click **Add Package**

## Step 2: Configure RevenueCat Dashboard

1. Go to [RevenueCat Dashboard](https://app.revenuecat.com)
2. Create a new app or select your existing app
3. Navigate to **Project Settings** → **API Keys**
4. Copy your **Public API Key** (you're using the test key: `test_YJMEfoMqdCFelANmBrkdyUoUDsI`)

## Step 3: Configure Products in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app → **Features** → **In-App Purchases**
3. Create two subscription products:

   **Monthly Subscription:**
   - Product ID: `monthly`
   - Type: Auto-Renewable Subscription
   - Price: $11.99/month
   - Subscription Group: Create a new group (e.g., "Drift Pro")
   - Subscription Duration: 1 month
   - Free Trial: 7 days (optional but recommended)

   **Yearly Subscription:**
   - Product ID: `yearly`
   - Type: Auto-Renewable Subscription
   - Price: $79.99/year
   - Subscription Group: Same group as monthly
   - Subscription Duration: 1 year
   - Free Trial: 7 days (optional but recommended)

## Step 4: Configure RevenueCat Products

1. In RevenueCat Dashboard, go to **Products**
2. Click **+ New** to add products
3. Add both products:
   - `monthly` → App Store product ID: `monthly`
   - `yearly` → App Store product ID: `yearly`

## Step 5: Create Entitlement

1. In RevenueCat Dashboard, go to **Entitlements**
2. Click **+ New**
3. Create entitlement:
   - Identifier: `Drift Pro`
   - Attach both products (`monthly` and `yearly`) to this entitlement

## Step 6: Create Offering

1. In RevenueCat Dashboard, go to **Offerings**
2. Click **+ New**
3. Create a default offering:
   - Identifier: `default` (or leave as default)
   - Add both packages:
     - Monthly package → Product: `monthly`
     - Yearly package → Product: `yearly`
   - Set as **Current Offering**

## Step 7: Test the Integration

### Using Sandbox Tester Account

1. In App Store Connect, go to **Users and Access** → **Sandbox Testers**
2. Create a test account
3. On your device, sign out of your Apple ID
4. When prompted during purchase, use the sandbox tester account

### Testing Checklist

- [ ] Paywall displays correctly
- [ ] Monthly and yearly plans show correct prices
- [ ] Purchase flow completes successfully
- [ ] Entitlement is granted after purchase
- [ ] Subscription status shows in Profile
- [ ] Customer Center opens correctly
- [ ] Restore purchases works
- [ ] Entitlement checks work throughout the app

## Step 8: Production Setup

1. Replace test API key with production key in `RevenueCatConfig.swift`
2. Ensure all products are approved in App Store Connect
3. Test with real purchases in production environment
4. Monitor RevenueCat dashboard for analytics

## Code Implementation Status

✅ RevenueCat SDK integration code is complete
✅ PaywallScreen integrated with RevenueCat
✅ SubscriptionStatusView created
✅ RevenueCatManager service class created
✅ Entitlement checking implemented
✅ Customer Center support added
✅ Error handling implemented

## Key Files

- `Network/RevenueCatConfig.swift` - Configuration and API key
- `Network/RevenueCatManager.swift` - Main RevenueCat service
- `Screens/PaywallScreen.swift` - Paywall UI with RevenueCat integration
- `Components/SubscriptionStatusView.swift` - Subscription status UI
- `DriftApp.swift` - RevenueCat initialization

## Usage Examples

### Check Entitlement
```swift
if RevenueCatManager.shared.hasProAccess {
    // User has Pro access
}
```

### Show Paywall
```swift
@State private var showPaywall = false

.sheet(isPresented: $showPaywall) {
    PaywallScreen(isOpen: $showPaywall, source: .swipeLimit)
}
```

### Restore Purchases
```swift
Task {
    let result = await RevenueCatManager.shared.restorePurchases()
    // Handle result
}
```

## Troubleshooting

### Products Not Loading
- Verify product IDs match exactly in App Store Connect and RevenueCat
- Check that products are approved and available
- Ensure offering is set as "Current" in RevenueCat dashboard

### Purchase Errors
- Verify sandbox tester account is set up correctly
- Check that products are in the same subscription group
- Ensure app is signed with correct provisioning profile

### Entitlement Not Granting
- Verify entitlement identifier matches: `Drift Pro`
- Check that products are attached to the entitlement
- Ensure customer info is being refreshed after purchase

## Support

For issues with RevenueCat integration:
- [RevenueCat Documentation](https://www.revenuecat.com/docs)
- [RevenueCat Support](https://www.revenuecat.com/support)
