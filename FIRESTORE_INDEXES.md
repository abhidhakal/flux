# Firestore Indexes Setup

The app requires specific Firestore indexes for efficient querying. Please create these indexes in your Firebase Console.

## Required Indexes

### 1. Transactions Collection - Date Range Queries
**Collection Group:** `transactions`
**Fields:**
- `userId` (Ascending)
- `date` (Ascending)
- `__name__` (Ascending)

**Query Scope:** Collection
**Status:** Enabled

### 2. Transactions Collection - Recent Transactions
**Collection Group:** `transactions`
**Fields:**
- `userId` (Ascending)
- `date` (Descending)
- `__name__` (Descending)

**Query Scope:** Collection
**Status:** Enabled

## How to Create Indexes

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `flux-budget-tracking`
3. Navigate to **Firestore Database** → **Indexes**
4. Click **Create Index**
5. For each index above:
   - Set **Collection Group ID** to `transactions`
   - Add the fields in the exact order specified
   - Set the sort order (Ascending/Descending) as specified
   - Click **Create**

## Alternative: Auto-Create from Error Links

The app will show error messages with direct links to create the required indexes. You can click these links to automatically create the indexes:

### Index 1: Transactions by userId (Ascending), date (Descending), __name__ (Descending)
**Purpose**: Recent transactions query (newest first)
```
https://console.firebase.google.com/v1/r/project/flux-budget-tracking/firestore/indexes?create_composite=Cllwcm9qZWN0cy9mbHV4LWJ1ZGdldC10cmFja2luZy9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvdHJhbnNhY3Rpb25zL2luZGV4ZXMvXxABGgoKBnVzZXJJZBABGggKBGRhdGUQAhoMCghfX25hbWVfXxAC
```

### Index 2: Transactions by userId (Ascending), date (Ascending), __name__ (Ascending)
**Purpose**: Date range queries (oldest first)
```
https://console.firebase.google.com/v1/r/project/flux-budget-tracking/firestore/indexes?create_composite=Cllwcm9qZWN0cy9mbHV4LWJ1ZGdldC10cmFja2luZy9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvdHJhbnNhY3Rpb25zL2luZGV4ZXMvXxABGgoKBnVzZXJJZBABGggKBGRhdGUQARoMCghfX25hbWVfXxAB
```

### Index 3: Goals by userId (Ascending), createdAt (Descending), __name__ (Descending)
**Purpose**: User goals query (newest first)
```
https://console.firebase.google.com/v1/r/project/flux-budget-tracking/firestore/indexes?create_composite=ClJwcm9qZWN0cy9mbHV4LWJ1ZGdldC10cmFja2luZy9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvZ29hbHMvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg
```

## Index Creation Time

- **Small datasets**: 1-2 minutes
- **Large datasets**: 5-10 minutes
- **Very large datasets**: Up to 1 hour

The app will continue to work with limited functionality until the indexes are created.

## Verification

After creating the indexes, restart the app to verify that:
1. Transactions load properly
2. Dashboard shows financial data
3. No more "index required" errors in the console
