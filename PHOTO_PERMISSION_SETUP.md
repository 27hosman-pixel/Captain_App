# 📸 Photo Library Permission Setup

## ⚠️ REQUIRED: Add to Info.plist

Your app crashes when saving stat cards because iOS requires explicit permission declaration.

### **How to Add Permission:**

#### **Option 1: Using Xcode UI (Easiest)**

1. Open your project in Xcode
2. Select your **target** (Captain)
3. Go to the **Info** tab
4. Click the **+** button to add a new row
5. In the dropdown, find and select:
   - **Privacy - Photo Library Additions Usage Description**
6. Set the value to:
   - **"Captain needs access to save your stat cards to Photos"**

#### **Option 2: Edit Info.plist as Source Code**

1. Right-click **Info.plist** in Project Navigator
2. Choose **Open As > Source Code**
3. Add this inside the `<dict>` tag:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Captain needs access to save your stat cards to Photos</string>
```

### **What This Does:**

- When the user taps "Save to Photos", iOS shows a permission dialog
- If granted: Image saves successfully
- If denied: App shows a helpful alert with a link to Settings

### **Testing:**

1. Add the Info.plist entry
2. Clean build folder (⌘+Shift+K)
3. Run the app
4. Create a stat card and tap "Save to Photos"
5. You should see iOS's permission dialog
6. Tap "Allow"
7. Image saves successfully! ✅

---

**DELETE THIS FILE** after you've added the permission to Info.plist
