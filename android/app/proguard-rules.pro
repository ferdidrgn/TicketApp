# ==============================================================================
# 🎭 TİYATROL TICKETAPP — SENIOR STAFF LEVEL PROGUARD & R8 CONFIGURATION
# ==============================================================================
# Paket Adı: com.ferdidrgn.ticketapp
# Hedef Sürüm: Production-Grade Cryptographic Obfuscation Layer
# ==============================================================================

# ------------------------------------------------------------------------------
# 🛡️ 1. TEMEL OBFUSCATION & KOD KARARTMA AYARLARI
# ------------------------------------------------------------------------------
# Hata raporlarında (Crashlytics) satır numaralarının kaybolmaması için bunları saklıyoruz
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Metadata ve yansıtma (Reflection) mimarilerinin runtime'da patlamaması için gerekli öznitelikler
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ------------------------------------------------------------------------------
# 🔕 2. DELEGE EDİLMİŞ UYARILARI KAPATMA (DONTWARN SANTRALİ)
# ------------------------------------------------------------------------------
# Derleme (Build) esnasında kütüphanelerin ürettiği sahte uyarıların derlemeyi kilitlemesini engeller
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn com.google.android.play.core.**
-dontwarn okhttp3.**
-dontwarn okio.**

# ------------------------------------------------------------------------------
# ⚙️ 3. FLUTTER ENGINE & ÇEKİRDEK MOTOR KORUMASI
# ------------------------------------------------------------------------------
# Flutter motorunun C++ katmanı ile Java/Kotlin katmanı arasındaki JNI köprülerini korur
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# ------------------------------------------------------------------------------
# 🔥 4. FIREBASE & GOOGLE SERSVİSLERİ MODÜLER GÜVENLİĞİ
# ------------------------------------------------------------------------------
# Firebase Analytics, Crashlytics ve Play Integrity sistem bileşenlerini koruma altına alır
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepclassmembers class com.google.firebase.** { *; }

# Google Play Güvenlik Duvarı ve App Check bütünlük kontrolü (Play Integrity)
-keep class com.google.android.play.core.** { *; }

# ------------------------------------------------------------------------------
# ☕ 5. KOTLIN STANDART KÜTÜPHANESİ VE LIFECYCLE KORUMALARI
# ------------------------------------------------------------------------------
# Kotlin asenkron süreçlerinin ve StateFlow yapılarının karartma esnasında bozulmasını önler
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ------------------------------------------------------------------------------
# 🔐 6. KRİPTOGRAFİ & LOKAL DEPOLAMA GÜVENLİK ETKİSİ
# ------------------------------------------------------------------------------
# AES-256-GCM lokal veri şifreleme ve Android Keystore anahtar takas sınıflarını güvenceye alır
-keepclassmembers class * {
    javax.crypto.** *;
}
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }

# ------------------------------------------------------------------------------
# ⚡ 7. R8 AGRESİF OPTİMİZASYON DÖNGÜSÜ
# ------------------------------------------------------------------------------
# Kod optimizasyonunu 5 döngü halinde çalıştırarak APK boyutunu küçültür ve hızı maksimuma çıkarır
-optimizationpasses 5
-allowaccessmodification

# Runtime'da güvensiz döngü oluşturabilecek mizanpaj ve aritmetik sadeleştirmeleri hariç tutuyoruz
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*

# ------------------------------------------------------------------------------
# 📱 8. ANDROID MANIFEST & LOKAL SİSTEM BİLEŞENLERİ
# ------------------------------------------------------------------------------
# İşletim sisteminin uygulamayı ayağa kaldırırken kullandığı ana giriş noktalarını korur
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference

# ------------------------------------------------------------------------------
# 📦 9. VERİ SERİLEŞTİRME VE MODELLER (SERIALIZABLE / PARCELABLE)
# ------------------------------------------------------------------------------
# Firestore'dan gelen ve giden veri transfer nesnelerinin (DTO) çalışma anında bozulmasını engeller
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ------------------------------------------------------------------------------
# 🔢 10. ENUM & SABİTLERİN RENDER GÜVENLİĞİ
# ------------------------------------------------------------------------------
# Dil ve tema seçimlerinde kullanılan Enum yapılarının isim eşleşmelerini korur
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ------------------------------------------------------------------------------
# 🎯 11. UYGULAMA PAKET KORUMASI (TICKETAPP ÖZEL)
# ------------------------------------------------------------------------------
# com.ferdidrgn.saglamspot yerine projenizin orijinal kök dizini tam korumaya alınıyor
-keep class com.ferdidrgn.ticketapp.** { *; }

# JSON/Dart model eşleşmelerinin (Data Transfer Objects) patlamaması için alan adlarını koru
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ------------------------------------------------------------------------------
# 📢 12. ADMOB MONETIZATION SENSITIVE LAYER
# ------------------------------------------------------------------------------
# Google AdMob reklam banner ve interstitial API'larının karartılmasını engeller
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# ------------------------------------------------------------------------------
# 🧭 13. MAP VE RAPORLAMA ÇIKTILARI (CRITICAL FOR TRACING)
# ------------------------------------------------------------------------------
# Tersine mühendislik haritasını ve kullanılmayan kod raporlarını dışarıya aktarır
-printmapping mapping.txt
-printseeds seeds.txt
-printusage unused.txt