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
# 🔥 4. FIREBASE & GOOGLE SERVİSLERİ
# ------------------------------------------------------------------------------
# DİKKAT: Buradaki "-keep class com.google.firebase.** { *; }" ve
# "-keep class com.google.android.gms.** { *; }" satırları KASITLI OLARAK
# SİLİNDİ. Firebase/Google Play Services SDK'ları kendi consumer-proguard
# kurallarını AAR'ları içinde zaten taşıyor ve Gradle bunları otomatik
# uyguluyor — uygulama seviyesinde tekrar tüm paketi (*, tüm üyeleriyle)
# tutmak sadece kod karartmayı (obfuscation) etkisiz kılıyordu. Google
# Play Console'un "DEX kodu optimizasyonu %19, eşiğin altında" uyarısının
# ana sebebi buydu — gms tek başına DEX'in büyük bir kısmını oluşturuyor.
# Build/uyarı gürültüsünü önlemek için -dontwarn'lar yeterli, ayrıca kalıyor.
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Play Güvenlik Duvarı ve App Check bütünlük kontrolü (Play Integrity)
-keep class com.google.android.play.core.** { *; }

# ------------------------------------------------------------------------------
# ☕ 5. KOTLIN STANDART KÜTÜPHANESİ VE LIFECYCLE KORUMALARI
# ------------------------------------------------------------------------------
# "-keep class kotlin.** { *; }" da aynı sebeple kaldırıldı — R8/Kotlin'in
# resmi varsayılan kuralları sadece Metadata'yı korumayı gerektirir, tüm
# stdlib'i değil. Asenkron/StateFlow yapıları için gerçekten gereken dar
# kapsamlı korumalar (Metadata, WhenMappings) aynen kalıyor.
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
# "-keep class com.ferdidrgn.ticketapp.** { *; }" de KASITLI OLARAK
# kaldırıldı — Play Console'un obfuscation metriği özellikle UYGULAMANIN
# KENDİ kodunun karartılıp karartılmadığına bakıyor; bu satır tüm kendi
# kodumuzu (kategori/business logic dahil) karartmadan muaf tutuyordu.
# Gerçekte native tarafta yalnızca MainActivity var ve o zaten aşağıdaki
# "extends android.app.Activity" kuralıyla korunuyor; başka bir şeyin
# reflection ile isme göre çağrıldığına dair bir iz yok.
# JSON/Dart model eşleşmelerinin (Data Transfer Objects) patlamaması için alan adlarını koru
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ------------------------------------------------------------------------------
# 📢 12. ADMOB
# ------------------------------------------------------------------------------
# Google Mobile Ads SDK da kendi consumer-proguard kurallarını AAR'ı
# içinde taşıyor (resmi AdMob Android dokümantasyonu manuel keep kuralı
# gerekmediğini açıkça belirtiyor) — aynı sebeple blanket keep kaldırıldı,
# sadece build uyarılarını susturan -dontwarn kalıyor.
-dontwarn com.google.android.gms.ads.**

# ------------------------------------------------------------------------------
# 🧭 13. MAP VE RAPORLAMA ÇIKTILARI (CRITICAL FOR TRACING)
# ------------------------------------------------------------------------------
# Tersine mühendislik haritasını ve kullanılmayan kod raporlarını dışarıya aktarır
-printmapping mapping.txt
-printseeds seeds.txt
-printusage unused.txt