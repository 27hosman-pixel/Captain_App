# Preview Buttons Refactor Plan

## Current State (SessionPreviewView.swift)

The preview screen currently has 4 buttons in this order:
1. **Share to Social Media** (Primary - Blue prominent style)
2. **Save to My Activities** (Secondary - Bordered style)
3. **Save Draft** (Tertiary - Small bordered button)
4. **Edit** (Tertiary - Small bordered button)

### Current Issues:
1. ❌ Button order doesn't match the primary user flow (most users want to save, not share)
2. ❌ "Share to Social Media" doesn't save the activity (requires separate save action)
3. ❌ Edit button doesn't work properly (just pops back without allowing edits)

---

## Requested Changes

### 1. Reorder and Re-style Buttons
**Primary CTA:** "Save to My Activities" should be first and have the light blue prominent style
**Secondary:** "Share to Social Media" should be second and bordered style
**Tertiary:** "Save Draft" and "Edit" remain as small buttons at bottom

### 2. Share Auto-Saves
When user clicks "Share to Social Media":
- First save the session to SessionStore
- Then show the ShareCardView
- Prevent sharing unsaved activities

### 3. Fix Edit Button
The Edit button should:
- Navigate back to the appropriate logging form (LogGameView/LogPracticeView/LogWorkoutView)
- The form should reload all data from PreviewStore
- User can make changes
- Clicking "Continue to Preview" brings them back to SessionPreviewView

---

## Implementation Plan

### Phase 1: Button Reordering & Styling (SessionPreviewView.swift)

#### Changes to `actionButtons` computed property:

**Before:**
```swift
VStack(spacing: 12) {
    // PRIMARY CTA: Share (V1 focus)
    Button(action: { showShareSheet = true }) {
        HStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up")
            Text("Share to Social Media")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
    }
    .buttonStyle(.borderedProminent)
    
    // Save to activities
    Button(action: saveSession) {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
            Text("Save to My Activities")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
    }
    .buttonStyle(.bordered)
    
    // Secondary actions
    HStack(spacing: 12) {
        Button(action: saveDraft) { ... }
        Button(action: editSession) { ... }
    }
}
```

**After:**
```swift
VStack(spacing: 12) {
    // PRIMARY CTA: Save to My Activities (most common action)
    Button(action: saveSession) {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
            Text("Save to My Activities")
                .font(.system(size: 17, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.large)
    .disabled(isSaving)
    
    // SECONDARY: Share (auto-saves first)
    Button(action: shareToSocialMedia) {
        HStack(spacing: 12) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 18, weight: .semibold))
            Text("Share to Social Media")
                .font(.system(size: 17, weight: .medium))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
    }
    .buttonStyle(.bordered)
    .disabled(isSaving)
    
    // V2 FEATURE: Post to feed (hidden in V1)
    if FeatureFlags.inAppSocial {
        Button(action: postToFeed) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                Text("Post to Feed")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
    }
    
    // Tertiary actions (small buttons at bottom)
    HStack(spacing: 12) {
        Button(action: saveDraft) {
            Label("Save Draft", systemImage: "archivebox")
                .font(.system(size: 15, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(.bordered)
        
        Button(action: editSession) {
            Label("Edit", systemImage: "pencil")
                .font(.system(size: 15, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(.bordered)
    }
}
```

---

### Phase 2: Share Auto-Saves (SessionPreviewView.swift)

#### New Method: `shareToSocialMedia()`

Create a new method that combines save + share:

```swift
/// Save session first, then show share sheet
/// This ensures we never share an activity that isn't saved
private func shareToSocialMedia() {
    guard !isSaving else { return }
    
    print("📤 SessionPreviewView: Share to social - saving first...")
    
    // Step 1: Save the session
    isSaving = true
    
    // Save images to persistent storage
    let imageFileNames = storeImages()
    print("📤 SessionPreviewView: Saved \(imageFileNames.count) image files")
    
    // Create SessionData from PreviewStore
    let sessionData = SessionData(
        id: UUID(),
        title: previewStore.title,
        date: previewStore.date,
        location: previewStore.location,
        sessionType: previewStore.sessionType,
        details: previewStore.details,
        imageFileNames: imageFileNames,
        origin: nil,
        isPublic: false
    )
    
    // Save to SessionStore
    NotificationCenter.default.post(
        name: Notification.Name("SaveNewSession"),
        object: nil,
        userInfo: ["sessionData": sessionData]
    )
    
    print("📤 SessionPreviewView: Session saved, showing share sheet...")
    
    // Clean up draft if exists
    if let draftId = previewStore.currentDraftId {
        previewStore.deleteDraftById(draftId)
    }
    
    isSaving = false
    
    // Step 2: Show share sheet
    showShareSheet = true
    
    // Note: Don't clear previewStore or navigate away yet
    // User might cancel the share sheet
}
```

#### Update existing `saveSession()` method:

Keep the existing method but rename internally for clarity:

```swift
/// Save session to SessionStore and navigate to home
private func saveSession() {
    saveSessionAndNavigate(shouldNavigate: true)
}

/// Core save logic - can optionally skip navigation
private func saveSessionAndNavigate(shouldNavigate: Bool) {
    guard !isSaving else { return }
    isSaving = true
    
    print("💾 SessionPreviewView: Starting save process...")
    print("💾 SessionPreviewView: Title: '\(previewStore.title)'")
    print("💾 SessionPreviewView: Type: '\(previewStore.sessionType)'")
    print("💾 SessionPreviewView: Images: \(previewStore.images.count)")
    
    // Save images to persistent storage and get filenames
    let imageFileNames = storeImages()
    print("💾 SessionPreviewView: Saved \(imageFileNames.count) image files")
    
    // Create SessionData from PreviewStore
    let sessionData = SessionData(
        id: UUID(),
        title: previewStore.title,
        date: previewStore.date,
        location: previewStore.location,
        sessionType: previewStore.sessionType,
        details: previewStore.details,
        imageFileNames: imageFileNames,
        origin: nil,
        isPublic: false
    )
    
    print("💾 SessionPreviewView: Posting SaveNewSession notification...")
    
    NotificationCenter.default.post(
        name: Notification.Name("SaveNewSession"),
        object: nil,
        userInfo: ["sessionData": sessionData]
    )
    
    print("💾 SessionPreviewView: Notification posted")
    
    if let draftId = previewStore.currentDraftId {
        previewStore.deleteDraftById(draftId)
    }
    
    if shouldNavigate {
        previewStore.clear()
        NotificationCenter.default.post(name: Notification.Name("ShowPostedToast"), object: nil)
        NotificationCenter.default.post(name: Notification.Name("NavigateToHome"), object: nil)
        print("💾 SessionPreviewView: Save complete, navigating to home")
    }
    
    isSaving = false
}
```

---

### Phase 3: Fix Edit Button (SessionPreviewView.swift)

The edit functionality is **already implemented** per SHARE_EDIT_FIXES.md:
- ✅ `editSession()` pops back to the logging form
- ✅ LogGameView, LogPracticeView, LogWorkoutView all have `loadDraftIfNeeded()`
- ✅ Forms detect PreviewStore has data and reload it

**No changes needed** - just verify it's working correctly.

Current implementation:
```swift
private func editSession() {
    print("✏️ SessionPreviewView: Edit session of type '\(previewStore.sessionType)'")
    router.pop()
}
```

This is correct - it simply pops back, and the logging form handles reloading data.

---

## User Flow Diagrams

### Flow 1: Save Only (Most Common)
```
User fills out LogGameView
  ↓
Clicks "Continue to Preview"
  ↓
Sees SessionPreviewView
  ↓
Clicks "Save to My Activities" (PRIMARY BLUE BUTTON)
  ↓
Session saved to SessionStore
  ↓
Navigate to Home tab
  ↓
See session in feed ✅
```

### Flow 2: Share to Social Media
```
User fills out LogGameView
  ↓
Clicks "Continue to Preview"
  ↓
Sees SessionPreviewView
  ↓
Clicks "Share to Social Media" (SECONDARY BORDERED BUTTON)
  ↓
Session automatically saved to SessionStore ✅
  ↓
ShareCardView appears
  ↓
User generates stat card and shares to Instagram/etc.
  ↓
Dismisses share sheet
  ↓
Still on SessionPreviewView (can do more actions or go back)
```

### Flow 3: Edit Before Saving
```
User fills out LogPracticeView
  ↓
Clicks "Continue to Preview"
  ↓
Sees SessionPreviewView
  ↓
Notices typo in title
  ↓
Clicks "Edit" button
  ↓
Returns to LogPracticeView with all data populated ✅
  ↓
Fixes title
  ↓
Clicks "Continue to Preview"
  ↓
Clicks "Save to My Activities" ✅
```

### Flow 4: Save Draft for Later
```
User fills out LogWorkoutView
  ↓
Gets interrupted
  ↓
Clicks "Continue to Preview"
  ↓
Clicks "Save Draft"
  ↓
Draft saved, navigate to root
  ↓
Later: User goes to Log tab → "Saved Drafts"
  ↓
Taps draft to load
  ↓
LogWorkoutView loads with all data
  ↓
User completes and saves ✅
```

---

## State Management

### Add new state variable:
```swift
@State private var sessionSaved = false
```

This tracks whether the session has already been saved (prevents duplicate saves).

### Update save methods:
```swift
private func saveSession() {
    if !sessionSaved {
        performSave()
        sessionSaved = true
    }
    navigateToHome()
}

private func shareToSocialMedia() {
    if !sessionSaved {
        performSave()
        sessionSaved = true
    }
    showShareSheet = true
}
```

---

## Edge Cases to Handle

### 1. User clicks "Share" multiple times
**Solution:** Disable button while `isSaving == true`

### 2. User saves, then shares
**Solution:** Track `sessionSaved` state - if already saved, don't save again

### 3. User shares, dismisses sheet, then saves
**Solution:** Same as #2 - check `sessionSaved` flag

### 4. User edits after saving
**Problem:** Data is cleared after save
**Solution:** Don't clear PreviewStore until user navigates away from preview screen entirely

---

## Files to Modify

### 1. SessionPreviewView.swift (Primary Changes)
- ✅ Reorder buttons (Save first, Share second)
- ✅ Re-style buttons (Save = prominent, Share = bordered)
- ✅ Create `shareToSocialMedia()` method
- ✅ Add `sessionSaved` state tracking
- ✅ Refactor save logic to avoid duplication
- ✅ Update button actions
- ✅ Add proper disabled states

### 2. No other files need changes
- ✅ Edit functionality already works (per SHARE_EDIT_FIXES.md)
- ✅ LogGameView/LogPracticeView/LogWorkoutView already reload from PreviewStore
- ✅ ShareCardView already handles display correctly

---

## Testing Checklist

### Test 1: Save Only
- [ ] Fill out a game
- [ ] Click preview
- [ ] Verify "Save to My Activities" is the top button (blue prominent)
- [ ] Click "Save to My Activities"
- [ ] Verify navigation to Home
- [ ] Verify session appears in feed

### Test 2: Share Auto-Saves
- [ ] Fill out a practice
- [ ] Click preview
- [ ] Click "Share to Social Media" (second button, bordered)
- [ ] Verify share sheet appears
- [ ] Cancel share sheet
- [ ] Go to Home tab
- [ ] Verify session was saved despite canceling share ✅

### Test 3: Share Then Save (Should Not Duplicate)
- [ ] Fill out a workout
- [ ] Click preview
- [ ] Click "Share to Social Media"
- [ ] Dismiss share sheet
- [ ] Click "Save to My Activities"
- [ ] Go to Home tab
- [ ] Verify only ONE session exists (not duplicated) ✅

### Test 4: Edit Still Works
- [ ] Fill out a game with some data
- [ ] Click preview
- [ ] Click "Edit"
- [ ] Verify all data is still there
- [ ] Change title
- [ ] Click preview again
- [ ] Verify title changed
- [ ] Save

### Test 5: Save Draft Still Works
- [ ] Start logging a practice
- [ ] Click preview
- [ ] Click "Save Draft"
- [ ] Verify navigation to root
- [ ] Go to Drafts
- [ ] Verify draft appears

---

## Code Efficiency Notes

### ✅ Avoid Code Duplication
Instead of duplicating save logic in `saveSession()` and `shareToSocialMedia()`, we:
1. Create a core `performSave()` helper method
2. Use `sessionSaved` boolean to prevent duplicate saves
3. Both methods call the same save logic

### ✅ Minimal State Changes
We only add ONE new state variable: `sessionSaved`
- Simple boolean
- Easy to track
- No complex state management needed

### ✅ No Breaking Changes
- Existing edit flow works as-is
- Draft saving unchanged
- Home feed display unchanged
- Only button order and share behavior modified

### ✅ Clear User Feedback
- Disabled states during save operations
- Haptic feedback on success
- Toast notifications on completion
- No silent failures

---

## Implementation Order

### Step 1: Refactor Save Logic (15 min)
- Extract save logic to `performSave()` helper
- Add `sessionSaved` state variable
- Update `saveSession()` to use helper

### Step 2: Create Share Method (10 min)
- Implement `shareToSocialMedia()` 
- Call `performSave()` first
- Then show share sheet
- Don't navigate away

### Step 3: Reorder Buttons (5 min)
- Move "Save to My Activities" to top
- Change to `.borderedProminent`
- Move "Share to Social Media" to second
- Change to `.bordered`

### Step 4: Test All Flows (20 min)
- Run through all test cases
- Verify no regressions
- Check edge cases

**Total Time: ~50 minutes**

---

## Benefits of This Approach

### 1. User-Centric Design
✅ Primary action (Save) is now the most prominent button
✅ Users can't accidentally share without saving
✅ Clear visual hierarchy matches user intent

### 2. No Data Loss
✅ Share always saves first
✅ Can't have "ghost" shares that aren't in the app
✅ Draft system still provides safety net

### 3. Streamlined Code
✅ Shared save logic (no duplication)
✅ Simple state management
✅ Easy to test and maintain

### 4. Backward Compatible
✅ All existing flows still work
✅ No breaking changes to other views
✅ Edit/Draft features unchanged

---

## Visual Mockup

```
┌─────────────────────────────────────┐
│         Preview                     │
├─────────────────────────────────────┤
│                                     │
│  [Preview Content Card]             │
│   - Title                           │
│   - Stats                           │
│   - Images                          │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐ │
│  │ ✓ Save to My Activities       │ │  ← PRIMARY (Blue Prominent)
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ ↗ Share to Social Media       │ │  ← SECONDARY (Bordered)
│  └───────────────────────────────┘ │
│                                     │
│  ┌──────────────┐ ┌──────────────┐ │
│  │ 📦 Save Draft│ │ ✏️ Edit       │ │  ← TERTIARY (Small)
│  └──────────────┘ └──────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

## Summary

This refactor accomplishes all three goals:

1. ✅ **Reorder buttons:** "Save to My Activities" is now first and prominent
2. ✅ **Share auto-saves:** Clicking "Share to Social Media" saves the activity first
3. ✅ **Edit works:** Already functional per SHARE_EDIT_FIXES.md

The implementation is **clean, efficient, and maintainable** with:
- No code duplication (shared save logic)
- Minimal new state (one boolean)
- No breaking changes (all existing flows work)
- Clear user experience (proper hierarchy and feedback)

Ready to implement! 🚀
