// 🔥 Firestore Setup Script for Flux Budgeting App
// Run this script in Firebase Console → Firestore → Data → Import JSON

// Copy and paste this JSON into Firebase Console to create system badges

const systemBadges = [
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
  },
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
  },
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
  },
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
  },
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
];

// Instructions:
// 1. Go to Firebase Console → Firestore → Data
// 2. Click "Start collection"
// 3. Collection ID: system_badges
// 4. For each badge above:
//    - Click "Add document"
//    - Document ID: use the "id" field (e.g., "streak_7")
//    - Add fields manually or use the JSON structure above
// 5. Repeat for all 5 badges

console.log("System badges to create:", systemBadges);
