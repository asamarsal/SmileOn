import 'package:dynamic_sdk/dynamic_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/splash/presentation/splash_page.dart';

Future<void> _initFirebaseAndGetFCMToken() async {
  try {
    print('>>> [FCM] Sedang inisialisasi Firebase...');
    await Firebase.initializeApp();
    print('>>> [FCM] Firebase initialized berhasil!');

    final messaging = FirebaseMessaging.instance;

    // Meminta izin notifikasi
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('>>> [FCM] Status izin notifikasi: ${settings.authorizationStatus}');

    // Mengambil FCM Token perangkat
    final fcmToken = await messaging.getToken();
    print('\n' + '=' * 60);
    print('🔥 FCM TOKEN PERANGKAT ANDA:');
    print(fcmToken ?? 'TOKEN KOSONG (null)');
    print('=' * 60 + '\n');

    // Listener jika token diperbarui
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('\n🔄 FCM TOKEN REFRESHED: $newToken\n');
    });
  } catch (e, stack) {
    print('❌ [FCM ERROR] Gagal mendapatkan FCM Token: $e');
    print(stack);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Jalankan inisialisasi FCM di latar belakang agar tidak memblokir render UI
  _initFirebaseAndGetFCMToken();

  DynamicSDK.init(
    props: ClientProps(
      environmentId: '8db5700d-a994-4c00-a8c8-4e1962a7549f',
      appName: 'SmileOn',
      appLogoUrl: 'https://demo.dynamic.xyz/favicon-32x32.png',
      appOrigin: 'https://smileon.app',
      redirectUrl: 'smileon://',
    ),
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmileOn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            DynamicSDK.instance.dynamicWidget,
          ],
        );
      },
      home: const SplashPage(),
    );
  }
}
