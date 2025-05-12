# Remove Gradle transforms directory that contains corrupted metadata
if (Test-Path "$env:USERPROFILE\.gradle\caches\8.10.2\transforms") {
    Remove-Item -Path "$env:USERPROFILE\.gradle\caches\8.10.2\transforms" -Recurse -Force -ErrorAction SilentlyContinue
}

# Remove Gradle kotlin-dsl directory that contains corrupted accessors
if (Test-Path "$env:USERPROFILE\.gradle\caches\8.10.2\kotlin-dsl") {
    Remove-Item -Path "$env:USERPROFILE\.gradle\caches\8.10.2\kotlin-dsl" -Recurse -Force -ErrorAction SilentlyContinue
}

# Clean build directories
if (Test-Path ".\build") {
    Remove-Item -Path ".\build" -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path ".\android\build") {
    Remove-Item -Path ".\android\build" -Recurse -Force -ErrorAction SilentlyContinue
}
if (Test-Path ".\android\.gradle") {
    Remove-Item -Path ".\android\.gradle" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Cleanup completed! Now run these commands:"
Write-Host "1. flutter clean"
Write-Host "2. flutter pub get"
Write-Host "3. cd android && ./gradlew clean"
