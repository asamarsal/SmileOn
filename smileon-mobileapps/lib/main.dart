import 'package:dynamic_sdk/dynamic_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/splash/presentation/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
