# Adding Sign in with Apple & Google Sign-In

Your app currently uses **local-only authentication** - all data is stored on the device. Here's how to add social login options while maintaining local storage.

## Current Setup ✅

- **User IDs**: Stored in Keychain (secure local storage)
- **Profile Data**: Stored in UserDefaults
- **Sessions**: Stored as JSON files in Documents directory
- **No backend**: Everything is local to the device

---

## Option 1: Sign in with Apple (Recommended - Easiest)

### Why Choose This?
- ✅ Native to iOS - built into the OS
- ✅ No API keys or external SDKs needed
- ✅ Required by Apple if you offer other social sign-in
- ✅ Best for privacy-focused users
- ✅ Works offline (for authentication check)
- ✅ Users trust it

### Setup Steps

#### 1. Enable in Xcode
1. Select your project in Xcode
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add "Sign in with Apple"

#### 2. Update AuthStore.swift

Add this import at the top:
```swift
import AuthenticationServices
```

Add these methods to `AuthStore`:

```swift
@MainActor
final class AuthStore: ObservableObject {
    // ... existing code ...
    
    // Add this new method for Sign in with Apple
    func signInWithApple(authorization: ASAuthorization) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }
        
        // Use Apple's unique user identifier as our userId
        let userId = appleIDCredential.user
        
        // Store user info if this is first time sign in
        if let fullName = appleIDCredential.fullName {
            // You might want to save this to ProfileStore
            let firstName = fullName.givenName ?? ""
            let lastName = fullName.familyName ?? ""
            
            // Store in UserDefaults for later use
            UserDefaults.standard.set(firstName, forKey: "apple_first_name")
            UserDefaults.standard.set(lastName, forKey: "apple_last_name")
        }
        
        // Persist the userId
        persist(userId: userId)
        
        // New Apple sign-in users need to complete profile
        hasCompletedProfile = false
    }
}

enum AuthError: Error {
    case invalidCredential
    case signInFailed
}
```

#### 3. Create Sign in with Apple Button View

Create a new file `SignInWithAppleButton.swift`:

```swift
import SwiftUI
import AuthenticationServices

struct SignInWithAppleButton: View {
    @EnvironmentObject var authStore: AuthStore
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        SignInWithAppleButtonViewRepresentable(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                Task {
                    switch result {
                    case .success(let authorization):
                        do {
                            try await authStore.signInWithApple(authorization: authorization)
                        } catch {
                            print("Sign in with Apple failed: \(error)")
                        }
                    case .failure(let error):
                        print("Authorization failed: \(error.localizedDescription)")
                    }
                }
            }
        )
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 50)
    }
}

// SwiftUI wrapper for ASAuthorizationAppleIDButton
struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(
            authorizationButtonType: .signIn,
            authorizationButtonStyle: .black
        )
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleButtonPress),
            for: .touchUpInside
        )
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        let onCompletion: (Result<ASAuthorization, Error>) -> Void
        
        init(onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
             onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }
        
        @objc func handleButtonPress() {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            onRequest(request)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onCompletion(.failure(error))
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return UIWindow()
            }
            return window
        }
    }
}
```

#### 4. Add to Your Landing View

Update `ContentView.swift` landing view to include the Apple Sign In button:

```swift
VStack(spacing: 18) {
    // Your existing LOG IN button
    Button(action: {
        router.current = .login
    }) {
        Text("LOG IN")
            .font(.headline)
            .frame(maxWidth: .infinity)
    }
    .buttonStyle(PillButtonStyle(colors: [Color(red: 0.78, green: 0.94, blue: 0.99), Color(red: 0.68, green: 0.91, blue: 0.98)], foreground: .black))

    // Your existing SIGN UP button
    Button(action: {
        router.current = .signup
    }) {
        Text("SIGN UP")
            .font(.headline)
            .frame(maxWidth: .infinity)
    }
    .buttonStyle(PillButtonStyle(colors: [Color(red: 0.84, green: 0.87, blue: 0.98), Color(red: 0.72, green: 0.79, blue: 0.96)], foreground: .black))
    
    // Divider
    HStack {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(.gray.opacity(0.3))
        Text("or")
            .font(.caption)
            .foregroundColor(.gray)
        Rectangle()
            .frame(height: 1)
            .foregroundColor(.gray.opacity(0.3))
    }
    .padding(.vertical, 8)
    
    // NEW: Sign in with Apple button
    SignInWithAppleButton()
        .frame(height: 50)
        .cornerRadius(25)
}
.padding(.horizontal, 36)
.padding(.bottom, 67)
```

---

## Option 2: Google Sign-In

### Why Choose This?
- ✅ Users already have Google accounts
- ✅ Cross-platform (works on Android too if you expand)
- ⚠️ Requires Google SDK (adds ~5MB to app size)
- ⚠️ More complex setup with API keys

### Setup Steps

#### 1. Install Google Sign-In SDK

Add to your Xcode project via Swift Package Manager:
1. File → Add Package Dependencies
2. URL: `https://github.com/google/GoogleSignIn-iOS`
3. Version: "Latest"

Or add to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0")
]
```

#### 2. Get Google OAuth Client ID

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable "Google Sign-In API"
4. Create OAuth 2.0 Client IDs:
   - iOS application
   - Bundle ID: Your app's bundle identifier

#### 3. Configure Info.plist

Add these keys to your Info.plist:

```xml
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

#### 4. Update AuthStore.swift

```swift
import GoogleSignIn

// Add to AuthStore
func signInWithGoogle() async throws {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootViewController = windowScene.windows.first?.rootViewController else {
        throw AuthError.signInFailed
    }
    
    do {
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController
        )
        
        let user = result.user
        let userId = user.userID ?? UUID().uuidString
        
        // Store user info
        if let profile = user.profile {
            UserDefaults.standard.set(profile.givenName, forKey: "google_first_name")
            UserDefaults.standard.set(profile.familyName, forKey: "google_last_name")
            UserDefaults.standard.set(profile.email, forKey: "google_email")
        }
        
        // Persist the userId
        persist(userId: userId)
        hasCompletedProfile = false
        
    } catch {
        throw AuthError.signInFailed
    }
}
```

#### 5. Create Google Sign-In Button

```swift
import SwiftUI
import GoogleSignIn

struct GoogleSignInButton: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var isLoading = false
    
    var body: some View {
        Button(action: {
            Task {
                isLoading = true
                do {
                    try await authStore.signInWithGoogle()
                } catch {
                    print("Google Sign-In failed: \(error)")
                }
                isLoading = false
            }
        }) {
            HStack {
                Image("google_logo") // Add Google logo to Assets
                    .resizable()
                    .frame(width: 20, height: 20)
                
                Text("Sign in with Google")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(isLoading)
    }
}
```

#### 6. Initialize Google Sign-In

In your App file (or where you initialize your app):

```swift
import GoogleSignIn

@main
struct CaptainApp: App {
    @StateObject private var authStore = AuthStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authStore)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
```

---

## Comparison: Apple vs Google

| Feature | Sign in with Apple | Google Sign-In |
|---------|-------------------|----------------|
| Setup Difficulty | ⭐ Easy | ⭐⭐⭐ Moderate |
| SDK Size | 0 KB (built-in) | ~5 MB |
| API Keys Required | ❌ No | ✅ Yes |
| Privacy Focus | ⭐⭐⭐⭐⭐ Excellent | ⭐⭐⭐ Good |
| Email Hiding | ✅ Yes (relay email) | ❌ No |
| Required by Apple | ✅ If you have social login | N/A |
| Cross-platform | ❌ Apple only | ✅ iOS, Android, Web |

---

## Recommendation for Your App

Since you're storing everything **locally** and want to keep things simple:

### **Best Option: Sign in with Apple Only**

**Why?**
1. ✅ **Zero dependencies** - no external SDKs
2. ✅ **No API keys** to manage
3. ✅ **Required by Apple** anyway if you add any social login
4. ✅ **Privacy-first** - matches your local-only approach
5. ✅ **Native UI** - looks great automatically
6. ✅ **Fast setup** - can be done in 30 minutes

### **If You Really Want Google Too:**

Add it later! Start with Apple first, see how users respond. You can always add Google Sign-In in a future update.

---

## Important Notes for Local-Only Storage

Since everything is stored **locally on device**:

### ⚠️ What Users Should Know:
1. **No cloud backup** - if they delete the app, data is gone
2. **No multi-device sync** - data doesn't sync between devices
3. **Account tied to device** - signing in with Apple/Google on a different device creates a new account

### 💡 Consider Adding:
1. **Export/Import feature** - You already have export! Add import to help users transfer data
2. **Warning message** - Tell users data is local-only on first login
3. **Regular export reminders** - Remind users to backup their data

### Example Warning:

```swift
Text("🔒 Your data is stored locally on this device only")
    .font(.caption)
    .foregroundColor(.secondary)
    .multilineTextAlignment(.center)
    .padding(.top, 8)
```

---

## Quick Start: Add Sign in with Apple Now

**Minimal code to get started (5-minute version):**

1. Add capability in Xcode
2. Add this to AuthStore:
```swift
import AuthenticationServices

func signInWithApple(userId: String) {
    persist(userId: userId)
    hasCompletedProfile = false
}
```

3. Add this button to your landing view:
```swift
SignInWithAppleButtonViewRepresentable(
    onRequest: { request in
        request.requestedScopes = [.fullName]
    },
    onCompletion: { result in
        if case .success(let auth) = result,
           let credential = auth.credential as? ASAuthorizationAppleIDCredential {
            Task {
                await authStore.signInWithApple(userId: credential.user)
            }
        }
    }
)
.frame(height: 50)
```

That's it! You have Sign in with Apple working. 🎉

---

## Need Help?

Let me know if you want me to:
1. Implement Sign in with Apple for you (recommended)
2. Set up Google Sign-In too
3. Add data import/export features
4. Create user warnings about local storage

Just say which one! 🚀
