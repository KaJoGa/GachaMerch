# Project Context: GachaMerch

## 🎯 Tujuan Proyek (Project Goal)
GachaMerch adalah aplikasi Mobile (Android) dan Web yang dibangun menggunakan **Flutter**, dengan *backend* berbasis **Node.js (Express)** dan *database* **MySQL**. Proyek ini merupakan tugas lab mobile yang memiliki fitur manajemen User (Otentikasi), Food, dan Weapon yang kemungkinan akan diintegrasikan dengan sistem logika Gacha. 

## 🛠️ Apa Saja yang Sudah Dilakukan (What's Done)
1. **Otentikasi Manual (Login & Register):**
   - Menghubungkan Flutter dengan API Node.js (`/auth/login` & `/auth/register`).
   - Menerapkan penyimpanan token JWT menggunakan `SharedPreferences`.
   - Mengatur Base URL server secara dinamis: `localhost:3000` untuk Flutter Web dan `10.0.2.2:3000` untuk Emulator Android.

2. **Integrasi Google Sign-In:**
   - Menambahkan dan memperbaiki *package* `google_sign_in` agar bisa bekerja di platform Web maupun Android.
   - Menyelesaikan *error* perizinan (mengaktifkan *People API* di dashboard Google Cloud).
   - Memodifikasi kode Flutter (`lib/services/auth_service.dart`) agar **tidak** menggunakan Firebase Auth, melainkan langsung melemparkan profil dari Google (`GoogleSignInAccount`) ke *backend* Node.js untuk di-*generate* token JWT-nya.
   - Kondisional untuk `clientId`: menggunakan Web Client ID saat berjalan di Web, dan `null` saat di Android agar secara otomatis membaca dari konfigurasi `google-services.json` / SHA-1 bawaan.

3. **Backend Node.js:**
   - Menyesuaikan *controller* khusus (`/auth/google-login`) agar bisa mencatat *user* yang masuk via Google ke *database* MySQL (`gachamerch.sql`) dan mengembalikan `token` ke *frontend*.

## 🚦 Kondisi Saat Ini (Current State)
- Implementasi sistem masuk (Register, Login Manual, Login Google) sudah **berhasil dan berjalan dengan baik di Web** tanpa memunculkan error dari Firebase.
- Kode aplikasi di `auth_service.dart` juga **sudah siap-pakai untuk masuk ke perangkat/Emulator Android** asalkan SHA-1 dan file `google-services.json` sudah terkonfigurasi dengan benar di Firebase & Google Cloud Console.
- Token otorisasi sudah berhasil disimpan secara lokal dan bisa digunakan untuk otorisasi *Request API* ke depannya.

## 🚀 Langkah Selanjutnya (Next Steps)
- Mengerjakan fitur / *logic* utama dari aplikasi (halaman *Main Menu*, menampilkan data *Food/Weapon*, mekanik *Gacha*).
- Menambahkan *authorization header (Bearer Token)* pada pemanggilan (request) HTTP untuk fitur Food / Weapon, agar *backend* bisa menvalidasi apakah pengguna sudah *login* atau belum.
- Tes jalan di perangkat Android asli atau Emulator guna memastikan integrasi `google-services.json` berjalan tanpa hambatan.
- Jika dibutuhkan untuk demo ke orang lain, proyek ini memerlukan proses *hosting / deployment* untuk *frontend* (Web), server backend, dan database MySQL.

