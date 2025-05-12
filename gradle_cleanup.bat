@echo off
echo Stopping all Gradle daemons...
call gradlew --stop

echo Clearing Gradle caches...
rmdir /s /q "%USERPROFILE%\.gradle\caches\8.10.2\transforms"
rmdir /s /q "%USERPROFILE%\.gradle\caches\8.10.2\kotlin-dsl\accessors"
rmdir /s /q "%USERPROFILE%\.gradle\caches\modules-2\metadata-2.106"
rmdir /s /q "%USERPROFILE%\.gradle\caches\modules-2\files-2.1"

echo Clearing Android build directories...
cd /d "c:\Users\wailik\Documents\Code\Flutter\demo\demo"
rmdir /s /q "build"
rmdir /s /q "android\build"
rmdir /s /q "android\.gradle"

echo Running Flutter clean...
call flutter clean

echo Rebuilding Flutter packages...
call flutter pub get

echo Rebuilding Gradle project...
cd android
call gradlew clean --refresh-dependencies

echo Clean-up complete! Try building your project again.
