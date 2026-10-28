# Jaring pengaman untuk crash saat start:
#   RuntimeException: Failed to create an instance of androidx.work.impl.WorkDatabase
# WorkManager (dibawa AdMob) membuat database Room lewat refleksi
# (Class.forName("..._Impl").newInstance()). R8 full mode membuang constructor
# tanpa argumen kalau aturan keep tidak menyebutnya secara eksplisit, seperti pada
# Room 2.2.5. Penyebab utamanya sudah diatasi dengan menaikkan
# androidx.work:work-runtime di build.gradle; aturan ini menjaga supaya crash yang
# sama tidak kembali kalau ada dependency lain yang menurunkan versi Room.
-keep class * extends androidx.room.RoomDatabase { void <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
