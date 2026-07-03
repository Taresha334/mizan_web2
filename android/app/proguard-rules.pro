# Mizan Sentinel: Keep Background Service alive
-keep class id.flutter.flutter_background_service.** { *; }

# Supabase & Realtime Persistence
-keep class io.supabase.** { *; }
-keep class okhttp3.** { *; }
-keep class org.postgresql.** { *; }

# Flutter SMS Inbox preservation
-keep class com.shounakmulay.telephony.** { *; }