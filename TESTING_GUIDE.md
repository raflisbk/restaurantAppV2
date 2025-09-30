# Panduan Testing Notifikasi

## Jawaban untuk Pertanyaan: "Notifikasi akan berjalan langsung hari ini atau menunggu besok?"

**JAWAB: Notifikasi AKAN berjalan hari ini jika waktu yang di-set belum lewat.**

Contoh:
- Waktu sekarang: 14:30
- Set notifikasi: 14:48
- **Hasil: Notifikasi akan muncul pada 14:48 hari ini (18 menit lagi)**

Jika waktu sudah lewat:
- Waktu sekarang: 15:00
- Set notifikasi: 14:48
- **Hasil: Notifikasi akan muncul pada 14:48 besok**

## Metode Testing Bertahap

### 1. TEST IMMEDIATE (Harus berhasil dulu)
```dart
await NotificationHelper().testImmediateNotification();
```
**Hasil yang diharapkan**: Notifikasi muncul LANGSUNG
**Jika gagal**: Ada masalah dasar dengan sistem notifikasi

### 2. TEST 30 DETIK (Test scheduling sederhana)
```dart
await NotificationHelper().scheduleSimpleTest();
```
**Hasil yang diharapkan**: Notifikasi muncul setelah 30 detik
**Jika gagal**: Ada masalah dengan zonedSchedule atau permissions

### 3. TEST 1 MENIT (Test scheduling lebih lama)
```dart
await NotificationHelper().scheduleQuickTestNotification();
```
**Hasil yang diharapkan**: Notifikasi muncul setelah 1 menit

### 4. TEST DAILY REMINDER (Test fitur utama)
1. Set waktu 2-3 menit ke depan di Settings
2. Tunggu notifikasi muncul
3. Jika berhasil, set ke waktu yang diinginkan

## Debug Screen Usage

1. Tambahkan screen debug ke main navigation atau buat route khusus
2. Import: `import 'debug_notification.dart';`
3. Gunakan `NotificationDebugScreen()`

### Langkah Debug:
1. **Test Immediate** - Harus berhasil dulu
2. **Debug Info** - Cek timezone dan permission
3. **Check Pending** - Cek apakah notifikasi terjadwal
4. **Test 30 Second** - Test scheduling
5. **Cancel All** - Bersihkan jika perlu

## Permission Issues (Android 12+)

Jika notifikasi tidak muncul, cek:

1. **Notification Permission**: Settings > Apps > Restaurant App > Notifications
2. **Exact Alarm Permission**: Settings > Apps > Restaurant App > Special app access > Alarms & reminders
3. **Battery Optimization**: Settings > Battery > App optimization > Restaurant App (Set to "Don't optimize")

## Troubleshooting Common Issues

### Issue 1: Immediate notification tidak muncul
**Cause**: Permission dasar tidak ada
**Solution**: Cek notification permission di system settings

### Issue 2: Scheduled notification tidak muncul
**Cause**: Exact alarm permission tidak ada (Android 12+)
**Solution**: Grant exact alarm permission atau disable battery optimization

### Issue 3: Notifikasi muncul tapi tidak tepat waktu
**Cause**: Battery optimization atau Doze mode
**Solution**: Whitelist app dari battery optimization

### Issue 4: Timezone masalah
**Cause**: Timezone tidak ter-set dengan benar
**Solution**: Force set timezone di `_getDeviceTimeZone()`

## Log Output Yang Normal

```
🔔 === SIMPLIFIED DAILY REMINDER ===
Current time: 2025-01-XX 14:30:00.000+07:00
Notification setting: 14:48
Scheduled time: 2025-01-XX 14:48:00.000+07:00
Time until notification: 0:18:00.000000
✅ Daily reminder scheduled successfully!
```

## Verifikasi Manual

1. **Set waktu 2 menit ke depan**
2. **Tutup aplikasi sepenuhnya** (swipe dari recent apps)
3. **Tunggu waktu yang ditentukan**
4. **Notifikasi HARUS muncul**

Jika langkah di atas gagal, ada masalah fundamental yang perlu diperbaiki.