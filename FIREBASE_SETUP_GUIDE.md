# 🔥 Complete Firebase Setup Guide for Flux

## 🎯 **Quick Setup (5 minutes)**

### **Step 1: Set Up Security Rules**

1. **Go to Firebase Console:**
   - Open [Firebase Console](https://console.firebase.google.com)
   - Select your project
   - Click **"Firestore Database"** in the left sidebar

2. **Navigate to Rules:**
   - Click **"Rules"** tab at the top
   - Replace the existing rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can only access their own transactions
    match /transactions/{transactionId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Users can only access their own budgets
    match /budgets/{budgetId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Users can only access their own streaks
    match /streaks/{streakId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Users can only access their own badges
    match /badges/{badgeId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Users can only access their own categories
    match /categories/{categoryId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // All authenticated users can read system badges
    match /system_badges/{badgeId} {
      allow read: if request.auth != null;
    }
  }
}
```

3. **Publish Rules:**
   - Click **"Publish"** button
   - Wait for confirmation

### **Step 2: Create System Badges Collection**

1. **Go to Data Tab:**
   - Click **"Data"** tab in Firestore
   - Click **"Start collection"**

2. **Create Collection:**
   - Collection ID: `system_badges`
   - Click **"Next"**

3. **Add Badge Documents:**
   - Click **"Add document"** 5 times
   - Use these Document IDs and data:

#### **Badge 1: Week Warrior**
- **Document ID:** `streak_7`
- **Fields:**
  - `id` (string): `streak_7`
  - `name` (string): `Week Warrior`
  - `description` (string): `Maintain a 7-day streak`
  - `icon` (string): `🔥`
  - `color` (string): `#FF6B6B`
  - `type` (string): `streak`
  - `requiredValue` (number): `7`
  - `isUnlocked` (boolean): `false`
  - `unlockedAt` (timestamp): `null`
  - `createdAt` (timestamp): `2024-01-01T00:00:00Z`
  - `metadata` (map): `{}`

#### **Badge 2: Monthly Master**
- **Document ID:** `streak_30`
- **Fields:**
  - `id` (string): `streak_30`
  - `name` (string): `Monthly Master`
  - `description` (string): `Maintain a 30-day streak`
  - `icon` (string): `👑`
  - `color` (string): `#4ECDC4`
  - `type` (string): `streak`
  - `requiredValue` (number): `30`
  - `isUnlocked` (boolean): `false`
  - `unlockedAt` (timestamp): `null`
  - `createdAt` (timestamp): `2024-01-01T00:00:00Z`
  - `metadata` (map): `{}`

#### **Badge 3: Century Club**
- **Document ID:** `streak_100`
- **Fields:**
  - `id` (string): `streak_100`
  - `name` (string): `Century Club`
  - `description` (string): `Maintain a 100-day streak`
  - `icon` (string): `💎`
  - `color` (string): `#45B7D1`
  - `type` (string): `streak`
  - `requiredValue` (number): `100`
  - `isUnlocked` (boolean): `false`
  - `unlockedAt` (timestamp): `null`
  - `createdAt` (timestamp): `2024-01-01T00:00:00Z`
  - `metadata` (map): `{}`

#### **Badge 4: Big Spender**
- **Document ID:** `spending_1000`
- **Fields:**
  - `id` (string): `spending_1000`
  - `name` (string): `Big Spender`
  - `description` (string): `Track $1000 in expenses`
  - `icon` (string): `💸`
  - `color` (string): `#FF9500`
  - `type` (string): `spending`
  - `requiredValue` (number): `1000`
  - `isUnlocked` (boolean): `false`
  - `unlockedAt` (timestamp): `null`
  - `createdAt` (timestamp): `2024-01-01T00:00:00Z`
  - `metadata` (map): `{}`

#### **Badge 5: Transaction Tracker**
- **Document ID:** `transactions_50`
- **Fields:**
  - `id` (string): `transactions_50`
  - `name` (string): `Transaction Tracker`
  - `description` (string): `Log 50 transactions`
  - `icon` (string): `📊`
  - `color` (string): `#34C759`
  - `type` (string): `milestone`
  - `requiredValue` (number): `50`
  - `isUnlocked` (boolean): `false`
  - `unlockedAt` (timestamp): `null`
  - `createdAt` (timestamp): `2024-01-01T00:00:00Z`
  - `metadata` (map): `{}`

### **Step 3: Test Your Setup**

1. **Run your app:**
   ```bash
   flutter run
   ```

2. **Test features:**
   - ✅ Sign up with new email
   - ✅ Add a transaction
   - ✅ Create a budget
   - ✅ Check dashboard
   - ✅ View transactions list

## 🎉 **You're Done!**

Your Flux app now has:
- ✅ **Secure Firestore rules**
- ✅ **System badges for gamification**
- ✅ **Full transaction management**
- ✅ **Budget tracking**
- ✅ **User authentication**
- ✅ **Real-time data sync**

## 🚨 **Troubleshooting**

**If you get permission errors:**
- Check that security rules are published
- Make sure user is signed in
- Verify document structure matches the app

**If collections don't exist:**
- This is normal - they're created when first document is added
- The app will create them automatically

**If app crashes:**
- Check Firebase configuration
- Verify `google-services.json` is in `android/app/`
- Check Flutter console for error messages

---

**Your Flux budgeting app is now 100% production-ready! 🚀**
