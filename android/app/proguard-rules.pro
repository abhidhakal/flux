-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.GoogleApiClient { *; }
-keep class com.google.android.gms.common.api.PendingResult { *; }
-keep class com.google.android.gms.common.api.Status { *; }

# Firebase Auth required rules
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.android.gms.internal.firebase-auth-api.** { *; }
