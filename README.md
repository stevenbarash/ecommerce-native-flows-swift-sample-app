<img width="1049" alt="image" src="https://github.com/user-attachments/assets/4f8e5575-d7c6-4bdb-8f64-66b9be0c0874">

# Descope's Native Flows Swift Sample App

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Welcome to Descope's Native Flows Swift Sample App, a demonstration of how to integrate Descope [native flows](https://docs.descope.com/build/guides/gettingstarted/) for user authentication within a Swift application. Native flows are authentication UIs built in the Descope flow editor and rendered inside your app via `DescopeFlowViewController` or `DescopeFlowView`. By exploring this project, you can understand how Descope works with Swift to manage native flows. For an example with all authentication methods, refer to the [Swift Sample App](https://github.com/descope-sample-apps/swift-sample-app).

## Features
This sample app includes:

- **Simple Flow**: Push a `DescopeFlowViewController` onto a navigation stack
- **Modal Flow**: Preload a flow in the background and present it modally when ready
- **Inline Flow**: Embed a `DescopeFlowView` directly in the view hierarchy with custom animations
- **Passkeys**: Native passkey sign-in using the Descope SDK
- **Native Login**: Password sign-in and SMS OTP backed by the Descope SDK directly (no hosted webview)

## Getting Started
Follow these steps to run the sample app and explore Descope's capabilities with Swift:

### Prerequisites
Make sure you have the following installed:

- Xcode
- an iOS Simulator

### Run the app

1. Clone this repo and open the `.xcodeproj` in Xcode.
2. Set your **Descope Project ID** — this is the only required configuration:
   - In Xcode, select the **project** (top item) in the navigator, then select the **Deslope** target.
   - Go to the **Build Settings** tab and search for `myProjectId`.
   - Replace the placeholder with your Project ID from the [Descope Console](https://app.descope.com/settings/project).
   - **US region users**: leave `myBaseURL` as-is (the default works). Only change it if you are in a non-US region or using a custom CNAME domain.

   ![Alt text](.github/images/setProjectId.png?raw=true "Set Project ID")

3. Press **Run** (▶) in the top-left to build and launch on the iOS Simulator. The app opens to a menu where you can try each authentication method.

4. **(Optional) Self-Host Your Flow**: Your Descope authentication flow is automatically hosted by Descope at `https://auth.descope.io/<your_descope_project_id>` but you can use your own website or domain to host your flow. You can modify the value for the flow URL in the Flow Controller files to include your own hosted page with our Descope Web Component, as well as alter the `?flow=sign-up-or-in` parameter to run a different flow.

   ```swift
   let flow = DescopeFlow(url: "https://api.descope.com/login/\(Descope.config.projectId)?flow=sign-up-or-in")
   ```

   > For more information about Auth Hosting, visit our docs on it [here](https://docs.descope.com/auth-hosting-app)

### What you'll see

The app launches to a menu listing every supported authentication method. Tap any row to try it. Each screen demonstrates a different integration approach — from a single-line flow push to a fully custom native login surface. After signing in, you'll land on a home screen with a **Sign Out** button.

### Passkeys setup

Passkeys require additional configuration before they will work:

1. **Descope Console**: Go to [Authentication > Passkeys/WebAuthn](https://app.descope.com/settings/authentication/webauthn), enable passkeys, and configure your **top-level domain**.
2. **Associated Domains**: In Xcode, go to the **Deslope** target > **Signing & Capabilities** > **Associated Domains** and add an entry with the `webcredentials` service type whose value matches the top-level domain you configured above.
3. **Apple Developer account**: Associated domains require a paid Apple Developer account and a real device or simulator signed in to an Apple ID.

See Apple's [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/public-private_key_authentication/supporting_passkeys/) guide for full details.

### Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| App crashes on launch with `Missing myProjectId or myBaseURL in Info.plist` | Build settings not configured | Set `myProjectId` in Build Settings (step 2 above) |
| Flow screen shows a blank white page | Wrong or missing Project ID | Verify your Project ID in the [Descope Console](https://app.descope.com/settings/project) |
| Passkey dialog doesn't appear | Missing associated domain or WebAuthn not enabled | Follow the [Passkeys setup](#passkeys-setup) section above |
| Passkey fails with "passkeyFailed" error | Domain mismatch | Ensure the associated domain in Xcode matches the top-level domain in the Descope Console |
| "Network error" on any screen | No internet or wrong `myBaseURL` | Check connectivity; US region users should leave `myBaseURL` at the default |

## Learn More
To learn more please see the [Descope Documentation and API reference page](https://docs.descope.com/).

## Contact Us
If you need help you can [contact us](https://docs.descope.com/support/)

## License
Descope's Native Flows Swift Sample App is licensed for use under the terms and conditions of the MIT license Agreement.
