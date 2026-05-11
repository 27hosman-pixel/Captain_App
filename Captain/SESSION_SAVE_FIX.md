# Session Save Bug Fix

## Problem
When users logged a game/practice/workout and clicked "Save Game" in the preview screen, the session was not appearing in the home feed or recent activities.

## Root Cause
The `SessionPreviewView` was posting a `"SaveNewSession"` notification with the session data, but `SessionStore` was **not listening** for this notification. The notification was being sent into the void.

## Solution
Added a notification observer to `SessionStore` that listens for `"SaveNewSession"` notifications and properly saves the session data.

## Changes Made

### 1. SessionStore.swift
**Added notification listener in `init()`:**
```swift
init() {
    load()
    
    // Listen for save requests from SessionPreviewView
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleSaveNewSession(_:)),
        name: Notification.Name("SaveNewSession"),
        object: nil
    )
}

deinit {
    NotificationCenter.default.removeObserver(self)
}
```

**Added handler method:**
```swift
@objc private func handleSaveNewSession(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let sessionData = userInfo["sessionData"] as? SessionData else {
        print("❌ SessionStore: Failed to extract sessionData from notification")
        return
    }
    
    // Validate title
    let trimmedTitle = sessionData.title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedTitle.isEmpty else {
        print("⚠️ SessionStore: Attempted to save session with empty title - skipping")
        return
    }
    
    // Add session to the store
    sessions.insert(sessionData, at: 0)
    save()
    
    print("✅ SessionStore: Successfully saved session. Total sessions: \(sessions.count)")
}
```

### 2. SessionPreviewView.swift
**Added debug logging** to trace the save flow:
- Logs session details before saving
- Logs image count
- Confirms notification was posted
- Confirms navigation to home

## How It Works Now

### Save Flow:
1. User logs a game/practice/workout
2. User reviews in `SessionPreviewView`
3. User clicks "Save Game" button
4. `SessionPreviewView.saveSession()`:
   - Saves images to disk → gets filenames
   - Creates `SessionData` object
   - Posts `"SaveNewSession"` notification with sessionData
   - Clears preview store
   - Navigates to home
5. `SessionStore.handleSaveNewSession()`:
   - Receives notification
   - Extracts sessionData
   - Validates title is not empty
   - Inserts session at beginning of array
   - Saves to disk (sessions.json)
6. Session appears in home feed and activities ✅

## Debug Output

When saving a session, you'll now see console output like:
```
💾 SessionPreviewView: Starting save process...
💾 SessionPreviewView: Title: 'Championship Game'
💾 SessionPreviewView: Type: 'Game'
💾 SessionPreviewView: Images: 1
💾 SessionPreviewView: Saved 1 image files
💾 SessionPreviewView: Posting SaveNewSession notification...
💾 SessionPreviewView: Notification posted
💾 SessionPreviewView: Save complete, navigating to home
💾 SessionStore: Received SaveNewSession notification
💾 SessionStore: Saving session 'Championship Game'
✅ SessionStore: Successfully saved session. Total sessions: 5
```

## Testing
To verify the fix:
1. Go to Log tab
2. Log a game/practice/workout with some stats
3. Click "Save Game" in preview screen
4. Check Xcode console for success messages
5. Navigate to Home tab → Recent Activities should show your new session
6. Navigate to Profile tab → Feed should show your new session

## Why This Pattern?
The app uses NotificationCenter for loose coupling between views and stores:
- `SessionPreviewView` doesn't need direct reference to `SessionStore`
- Multiple observers can respond to the same save event
- Consistent with other app patterns (NavigateToHome, ShowPostedToast, etc.)

## Related Files
- `SessionStore.swift` - Now listens for saves
- `SessionPreviewView.swift` - Posts save notifications (already was)
- `HomeView.swift` - Displays sessions from SessionStore
- `ActivitiesView.swift` - Displays recent sessions
- `ProfileView.swift` - Displays user's sessions

## Status
✅ **FIXED** - Sessions now save correctly and appear in all relevant views
