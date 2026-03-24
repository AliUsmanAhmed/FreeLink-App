# Build Guide — Android and Flutter Integration

This document explains how to build the Go client for Android and integrate it with a Flutter app using two methods:

- ✅ Option A: gomobile (recommended) — Simple, official, Flutter-friendly
- ✅ Option B: c-shared + NDK — Manual, low-level, full control

Prerequisites
- Go 1.20+
- Flutter SDK
- Android Studio / adb / gradle

For gomobile:
```bash
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init
```

For c-shared:
- Android NDK (r21+)
- Environment variables:
```bash
export NDK_ROOT=/path/to/android-ndk
export TARGET=aarch64-linux-android
export API=21
export CC=$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/${TARGET}${API}-clang
```

Option A — gomobile (Recommended)
1. Install gomobile (once):
```bash
go install golang.org/x/mobile/cmd/gomobile@latest
gomobile init
```
2. Build AAR:
```bash
cd FreeLink-app/go
gomobile bind -target=android -o FreeLink.aar .
```
3. Use in Flutter (Android): copy FreeLink.aar to android/app/libs and add implementation files('libs/FreeLink.aar') to build.gradle. Use a MethodChannel to call start/stop.

Option B — c-shared + NDK (Advanced)
1. Build shared lib:
```bash
cd FreeLink-app/go
CGO_ENABLED=1 GOOS=android GOARCH=arm64 CC=$CC go build -buildmode=c-shared -o libfreelink.so
```
2. Add to android/app/src/main/jniLibs/arm64-v8a/libfreelink.so and write JNI glue.

Flutter integration notes and testing steps included.
