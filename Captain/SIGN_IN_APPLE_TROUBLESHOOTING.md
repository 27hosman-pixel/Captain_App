# Sign in with Apple - Troubleshooting

## Issue: Button Not Working / Not Responding

If the Sign in with Apple button appears but doesn't do anything when clicked, follow these steps:

### ✅ Step 1: Add the Capability in Xcode (REQUIRED)

This is the most common issue - the button won't work without this capability enabled.

1. **Open your project in Xcode**
2. **Click on your project** in the left sidebar (the blue icon at the top)
3. **Select your app target** (usually named "Captain")
4. **Click the "Signing & Capabilities" tab** at the top
5. **Click the "+ Capability" button** (near the top left)
6. **Type "Sign in with Apple"** in the search
7. **Double-click "Sign in with Apple"** to add it

You should now see "Sign in with Apple" appear in your capabilities list with a checkmark.

### ✅ Step 2: Clean Build (If Still Not Working)

1. **Product → Clean Build Folder** (or press Cmd+Shift+K)
2. **Build and run again**

### ✅ Step 3: Check Console for Errors

If the button still doesn't work:
1. Open the **Console** in Xcode (View → Debug Area → Show Debug Area)
2. Click the button
3. Look for any error messages starting with "❌"

Common errors:
- **"Invalid client"** → You didn't add the capability
- **"User cancelled"** → User clicked cancel (this is normal)
- **"Network error"** → Check your internet connection

### ✅ Step 4: Test on Real Device (Recommended)

Sign in with Apple works best on a real device:
1. Connect your iPhone/iPad
2. Select it as the destination in Xcode
3. Build and run
4. Try the button

On a real device, you'll see:
- Face ID / Touch ID prompt
- Your Apple ID information
- Much faster authentication

### ✅ Step 5: Verify Simulator Apple ID

If testing on Simulator:
1. Open **Settings** app in Simulator
2. Tap **Sign In** at the top
3. Sign in with your Apple ID
4. Go back to your app and try the button

---

## How to Tell If It's Working

When you tap the button, you should see:

### On Real Device:
1. Screen dims slightly
2. Apple's authentication sheet slides up from bottom
3. Shows "Sign in with Apple ID"
4. Face ID / Touch ID prompt appears
5. After authentication, app continues

### On Simulator:
1. Alert appears asking for Apple ID password
2. After entering password, authentication completes
3. App continues to Build Profile screen

---

## Debugging Steps

### Check 1: Is the button visible?
- ✅ Yes → Capability might be missing
- ❌ No → Build issue, try cleaning and rebuilding

### Check 2: Does tapping do anything?
- ✅ Shows authentication sheet → Working! 
- ✅ Shows error in console → Check the error message
- ❌ Nothing happens → Add the capability

### Check 3: Is "Sign in with Apple" in capabilities?
- ✅ Yes → Should work
- ❌ No → Add it now (see Step 1 above)

---

## Still Not Working?

### Option A: Verify Code is Updated

Make sure these files were updated:
- ✅ `AuthStore.swift` - Has `signInWithApple()` method
- ✅ `ContentView.swift` - Has `SignInWithAppleButtonView` component
- ✅ `ContentView.swift` - Imports `AuthenticationServices`

### Option B: Check Bundle ID

1. Go to Project Settings → General
2. Check your **Bundle Identifier** (e.g., "com.yourname.captain")
3. Make sure it's unique and valid
4. Make sure the capability is added for this bundle ID

### Option C: Create New Build

Sometimes Xcode needs a fresh start:
1. **Product → Clean Build Folder** (Cmd+Shift+K)
2. **Close Xcode completely**
3. **Delete derived data**: `~/Library/Developer/Xcode/DerivedData`
4. **Reopen Xcode**
5. **Build and run**

---

## Success Checklist ✅

Before testing, make sure you have:
- [ ] Added "Sign in with Apple" capability in Xcode
- [ ] Built the project without errors
- [ ] Signed in to Apple ID (on Simulator) or using a device
- [ ] Seen the button appear on screen
- [ ] Internet connection is working

---

## What Should Happen When It Works

### User Flow:
1. User sees landing screen with 3 buttons:
   - LOG IN (blue)
   - SIGN UP (purple)
   - Sign in with Apple (black Apple button)

2. User taps "Sign in with Apple"

3. iOS shows authentication sheet

4. User authenticates with Face ID/Touch ID/Password

5. App receives user ID from Apple

6. App stores user ID in Keychain

7. App navigates to Build Profile screen

8. First name and last name may be pre-filled

9. User completes profile

10. User is signed in! 🎉

---

## Need More Help?

If you're still having issues:

1. **Share the console output** - Copy any error messages
2. **Share a screenshot** - Show what happens when you tap the button
3. **Verify the capability** - Take a screenshot of your Signing & Capabilities tab

The most common fix is simply adding the capability! Make sure that's done first. 🚀
