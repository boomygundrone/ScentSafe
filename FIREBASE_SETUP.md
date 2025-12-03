# Firebase Setup Guide for ScentSafe App

## 🚀 Quick Setup Steps

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" 
3. Enter project name: `scentsafe-app`
4. Enable Google Analytics (optional)
5. Click "Create project"

### 2. Add Web App
1. In your Firebase project, click "Add app"
2. Select Web app icon (</>)
3. Enter app nickname: `ScentSafe Web`
4. Click "Register app"
5. **Copy the Firebase configuration object** - you'll need this for the next step

### 3. Configure Firebase in Your App
1. Open `lib/config/firebase_config.dart`
2. Replace the placeholder values with your actual Firebase credentials:
   ```dart
   static const FirebaseOptions current = FirebaseOptions(
     apiKey: "PASTE_YOUR_API_KEY_HERE",
     appId: "PASTE_YOUR_APP_ID_HERE", 
     messagingSenderId: "PASTE_YOUR_SENDER_ID_HERE",
     projectId: "PASTE_YOUR_PROJECT_ID_HERE",
     authDomain: "YOUR_PROJECT_ID_HERE.firebaseapp.com",
     databaseURL: "https://YOUR_PROJECT_ID_HERE-default-rtdb.firebaseio.com",
     storageBucket: "YOUR_PROJECT_ID_HERE.appspot.com",
     measurementId: "PASTE_YOUR_MEASUREMENT_ID_HERE",
   );
   ```

### 4. Enable Firestore Database
1. In Firebase Console, go to "Build" → "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location near you
5. Click "Enable"

### 5. Enable Authentication
1. Go to "Build" → "Authentication"
2. Click "Get started"
3. Enable "Email/Password" sign-in method
4. Click "Save"

### 6. Configure Firestore Security Rules
For development, you can use these permissive rules (⚠️ **Not for production**):

1. Go to Firestore Database → "Rules" tab
2. Replace existing rules with:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.time < timestamp.date(2025, 1, 1);
       }
     }
   }
   ```
3. Click "Publish"

## 🔧 Testing Your Setup

After completing the setup:

1. Restart your Flutter app:
   ```bash
   flutter run -d web-server --debug
   ```

2. Check the browser console for Firebase initialization logs
3. Look for `🔥 DIAGNOSTIC:` messages to confirm Firebase is working

## 🚨 Troubleshooting

### Common Issues:

1. **"ERR_BLOCKED_BY_CLIENT" Error**
   - Ensure you've replaced all placeholder values in `firebase_config.dart`
   - Check that Firestore Database is enabled in your Firebase project
   - Verify your Firebase project ID matches exactly

2. **Authentication Errors**
   - Make sure Email/Password authentication is enabled
   - Check that your Firebase project is not in a suspended state

3. **CORS Issues**
   - Ensure your web app domain is added to Firebase Authentication settings
   - For local development, `localhost` should work automatically

### Getting Help:

- Check the browser console for detailed error messages
- Look for `🔥 DIAGNOSTIC:` logs in your app
- Verify all Firebase configuration values are correctly copied

## 📱 Next Steps

Once Firebase is working:
- The app will store drowsiness detection data
- User authentication will be functional
- Real-time state updates will work across devices

## 🔒 Production Security

For production deployment:
- Update Firestore security rules to be more restrictive
- Enable Firebase App Check if needed
- Consider using Firebase Extensions for additional security