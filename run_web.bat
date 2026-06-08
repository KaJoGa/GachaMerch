@echo off
setlocal
echo Mengaktifkan Backend Node.js...
start "NodeJS_Backend" cmd /k "cd backend && node app.js"

echo Menunggu sebentar agar backend siap...
timeout /t 3 /nobreak >nul

echo Menjalankan Flutter Web dengan port 5000 untuk Google Sign-In...
flutter run -d chrome --web-port=5000

echo.
echo ====================================================
echo Flutter telah ditutup. Mematikan Backend Node.js...
echo ====================================================
taskkill /FI "WINDOWTITLE eq NodeJS_Backend*" /T /F >nul 2>&1
echo Berhasil dimatikan.
endlocal
