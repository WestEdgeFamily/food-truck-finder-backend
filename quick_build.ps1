param(
    [int]$VersionCode = 100,
    [string]$VersionName = "2.0.0"
)

Write-Host "Building AAB with Version Code: $VersionCode, Version Name: $VersionName"

# Update build.gradle.kts
$buildGradleContent = Get-Content "android/app/build.gradle.kts" -Raw
$buildGradleContent = $buildGradleContent -replace "versionCode = \d+", "versionCode = $VersionCode"
$buildGradleContent = $buildGradleContent -replace 'versionName = "[^"]*"', "versionName = `"$VersionName`""
Set-Content "android/app/build.gradle.kts" -Value $buildGradleContent

# Clean and build
flutter clean
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
flutter build appbundle --release

Write-Host "AAB built with version code $VersionCode"
Get-ChildItem "build\app\outputs\bundle\release\" | Format-Table Name, LastWriteTime, Length 