# lingsix

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



## command
- npx @biomejs/biome format --write

- flutter doctor (เช้คอุปกร)
- flutter devices (เช้คเลข iosเวลาจะรันกับเครื่อง)
- flutter run -d (รัน)
- flutter run -d emulator-5554 (android studioโหลดก่อนอันนี้)
- flutter run -d ตามด้วยเลข ios


## Firebase Services
Authenication -> Sign-in method -> enable Email/Password 
(อันนี้แอดไว้แล้วถ้าอยากเพิ่มล้อคอินอะไรเข้ามาเพิ่มจากตรงนี้)

Firestore Database -> Create database -> Start in test mode
(สร้างไว้แล้วเก็บ email/username/password พวกประวัติบันทึกผลเดี๋ยวใส่เพิ่มในนี้เอาเป็นย่อยลงมาอีก)

## Firebase setting
1) pubspec.yaml
Add dependencies -> firebase_core: ^3.0.0
firebase_auth: ^5.0.0
run -> flutter pub get

### IOS
1) ios/Runner.xcodeproj -> Bundle identifier 
ชื่อไว้ใส่เวลา create app firebase
2) download 
GoogleService-Info.plist 
from firebase
3) ใส่ไว้ใน xcode 
path ->
ios/Runner/GoogleService-Info.plist

### Android
1) เอาชื่อมากจาก application id ใน build.gradle.kts 
2) หลังใส่ชื่อในfirebase download google-services.json 
แล้วก็ใส่ในpath -> android/app/google-services.json
3) path -> android/build.gradle.kts add
    plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
    id("dev.flutter.flutter-gradle-plugin") apply false
    id("com.google.gms.google-services") version "4.4.0" apply false
}
4) path -> android/app/build.gradle.kts
add id("com.google.gms.google-services") ในplugins{}
ถึงจะรันได้ android ได้
