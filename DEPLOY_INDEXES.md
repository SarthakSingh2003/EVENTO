# Deploy Firestore Indexes - Quick Fix

## The Problem
You're seeing this error when trying to view event tickets:
```
Error loading tickets: [cloud_firestore/failed-precondition] The query requires an index
```

This happens because Firestore needs composite indexes for queries that filter and order by different fields.

## Quick Fix - Deploy Indexes

### Option 1: Using Firebase Console (Easiest)

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `evento-app-2ade7`
3. **Navigate to**: Firestore Database → Indexes tab
4. **Click**: "Create Index"
5. **Create these indexes**:

#### Index 1: Tickets by EventId and Purchase Date
- **Collection ID**: `tickets`
- **Fields**:
  - `eventId` (Ascending)
  - `purchasedAt` (Descending)

#### Index 2: Tickets by EventId and Usage Status
- **Collection ID**: `tickets`
- **Fields**:
  - `eventId` (Ascending)
  - `isUsed` (Ascending)

#### Index 3: Events by Date and Active Status
- **Collection ID**: `events`
- **Fields**:
  - `date` (Ascending)
  - `isActive` (Ascending)

#### Index 4: Events by Organizer and Date
- **Collection ID**: `events`
- **Fields**:
  - `organiserId` (Ascending)
  - `date` (Descending)

### Option 2: Using Firebase CLI

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Deploy the indexes**:
   ```bash
   firebase deploy --only firestore:indexes
   ```

### Option 3: Using the Direct Link

Click this link to create the required index directly:
```
https://console.firebase.google.com/v1/r/project/evento-app-2ade7/firestore/indexes?create_composite=ClBwcm9qZWN0cy9ldmVudG8tYXBwLTJhZGU3L2RhdGFiYXNlY3MvYmFzZWRvY2tldHMvY29sbGVjdGlvbkdyb3Vwcy90aWNrZXRzL2luZGV4ZXMvXxABGgSKB2V2ZW50SWQQARoPCgtwdXJjaGFzZWRBdBACGgwKCF9fbmFtZV9fEAI
```

## What This Fixes

✅ **Event creators can now view all tickets for their events**
✅ **Ticket management screen loads without errors**
✅ **Analytics screen shows proper ticket statistics**
✅ **Real-time ticket data works correctly**

## Temporary Workaround

While indexes are being created (can take 1-5 minutes), the app will:
- Show a user-friendly error message
- Provide a "Retry" button
- Automatically fall back to basic queries if possible

## After Deployment

1. **Wait 1-5 minutes** for indexes to build
2. **Try accessing the ticket management screen again**
3. **The error should be resolved**

## Verification

To verify the fix worked:
1. Go to an event you created
2. Click "Tickets" or "Analytics"
3. You should see the tickets/analytics without errors

If you still see errors after 5 minutes, try refreshing the app or checking the Firebase console for any remaining index build issues.
