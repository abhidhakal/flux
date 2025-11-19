# 🔥 Firestore Setup Guide for Flux Budgeting App

This guide will help you set up Firebase Firestore to make your Flux app fully functional.

## 📋 Prerequisites

1. Firebase project created
2. Flutter app connected to Firebase
3. Firebase Console access

## 🛡️ Step 1: Set Up Security Rules

**Go to Firebase Console → Firestore → Rules**

Replace the existing rules with:

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
        (resource.data.userId == request.auth.uid || 
         request.resource.data.userId == request.auth.uid);
    }
    
    // Users can only access their own budgets
    match /budgets/{budgetId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.resource.data.userId == request.auth.uid);
    }
    
    // Users can only access their own goals
    match /goals/{goalId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.resource.data.userId == request.auth.uid);
    }
    
    // Users can only access their own notifications
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.resource.data.userId == request.auth.uid);
    }
    
    // Users can only access their own streaks
    match /streaks/{streakId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.resource.data.userId == request.auth.uid);
    }
    
    // Users can access their own streak document by user ID
    match /streaks/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can only access their own badges
    match /badges/{badgeId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.resource.data.userId == request.auth.uid);
    }
    
    // Users can only access their own categories
    match /categories/{categoryId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.resource.data.userId == request.auth.uid);
    }
    
    // All authenticated users can read system badges
    match /system_badges/{badgeId} {
      allow read: if request.auth != null;
    }
    
    // All authenticated users can read goal templates
    match /goal_templates/{templateId} {
      allow read: if request.auth != null;
    }
  }
}
```

**Click "Publish" to save the rules.**

## 🏆 Step 2: Create System Badges Collection

**Go to Firebase Console → Firestore → Data**

### Create Collection: `system_badges`

Add these documents:

#### Document 1: `streak_7`
```json
{
  "id": "streak_7",
  "name": "Week Warrior",
  "description": "Maintain a 7-day streak",
  "icon": "🔥",
  "color": "#FF6B6B",
  "type": "streak",
  "requiredValue": 7,
  "isUnlocked": false,
  "unlockedAt": null,
  "createdAt": "2024-01-01T00:00:00Z",
  "metadata": {}
}
```

#### Document 2: `streak_30`
```json
{
  "id": "streak_30",
  "name": "Monthly Master",
  "description": "Maintain a 30-day streak",
  "icon": "👑",
  "color": "#4ECDC4",
  "type": "streak",
  "requiredValue": 30,
  "isUnlocked": false,
  "unlockedAt": null,
  "createdAt": "2024-01-01T00:00:00Z",
  "metadata": {}
}
```

#### Document 3: `streak_100`
```json
{
  "id": "streak_100",
  "name": "Century Club",
  "description": "Maintain a 100-day streak",
  "icon": "💎",
  "color": "#45B7D1",
  "type": "streak",
  "requiredValue": 100,
  "isUnlocked": false,
  "unlockedAt": null,
  "createdAt": "2024-01-01T00:00:00Z",
  "metadata": {}
}
```

#### Document 4: `spending_1000`
```json
{
  "id": "spending_1000",
  "name": "Big Spender",
  "description": "Track $1000 in expenses",
  "icon": "💸",
  "color": "#FF9500",
  "type": "spending",
  "requiredValue": 1000,
  "isUnlocked": false,
  "unlockedAt": null,
  "createdAt": "2024-01-01T00:00:00Z",
  "metadata": {}
}
```

#### Document 5: `transactions_50`
```json
{
  "id": "transactions_50",
  "name": "Transaction Tracker",
  "description": "Log 50 transactions",
  "icon": "📊",
  "color": "#34C759",
  "type": "milestone",
  "requiredValue": 50,
  "isUnlocked": false,
  "unlockedAt": null,
  "createdAt": "2024-01-01T00:00:00Z",
  "metadata": {}
}
```

## 🧪 Step 3: Test Your Setup

### Test Authentication:
1. Run your Flutter app
2. Try to sign up with a new email
3. Check if user document is created in `users` collection
4. Check if default categories are created in `categories` collection
5. Check if streak document is created in `streaks` collection

### Test Transactions:
1. Sign in to your app
2. Try to add a transaction
3. Check if transaction appears in `transactions` collection
4. Check if it appears in the transactions list in the app

### Test Dashboard:
1. Add a few transactions
2. Check if dashboard shows correct financial summary
3. Check if streak is being tracked

## 🚨 Troubleshooting

### Common Issues:

**1. "Permission denied" errors:**
- Check if security rules are properly set
- Make sure user is authenticated
- Verify user ID matches in documents

**2. "Collection doesn't exist" errors:**
- Collections are created automatically when first document is added
- This is normal behavior

**3. App crashes on startup:**
- Check Firebase configuration
- Verify `google-services.json` is in `android/app/`
- Verify `GoogleService-Info.plist` is in `ios/Runner/`

**4. Categories not showing:**
- Check if default categories were created during signup
- Look in `categories` collection for user's categories

## 📱 Step 4: Deploy and Test

1. **Build and run on device:**
   ```bash
   flutter run --release
   ```

2. **Test all features:**
   - Sign up/Sign in
   - Add transactions
   - View dashboard
   - Check streak tracking
   - Test badge system

## 🎉 Success!

If everything works correctly, your Flux budgeting app is now fully functional with:
- ✅ User authentication
- ✅ Transaction management
- ✅ Real-time data sync
- ✅ Streak tracking
- ✅ Badge system
- ✅ Financial dashboard

## 📞 Need Help?

If you encounter any issues:
1. Check the Firebase Console for error logs
2. Check the Flutter console for error messages
3. Verify all collections and documents are created correctly
4. Test with a fresh user account

---

**Your app is now ready for users! 🚀**
