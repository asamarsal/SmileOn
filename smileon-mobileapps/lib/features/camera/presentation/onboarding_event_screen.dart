import 'package:flutter/material.dart';
import 'package:smileon/features/camera/presentation/layout-onboarding-event/horizontal/onboarding_horizontal.dart';
import 'package:smileon/features/camera/presentation/layout-onboarding-event/vertical/onboarding_vertical.dart';

export 'package:smileon/features/camera/presentation/layout-onboarding-event/horizontal/onboarding_horizontal.dart';
export 'package:smileon/features/camera/presentation/layout-onboarding-event/vertical/onboarding_vertical.dart';
export 'package:smileon/features/camera/presentation/layout-onboarding-event/vertical/component-onboarding-vertical/show_qrcode_view.dart';

/// Screen Utama Onboarding Photobox Event.
///
/// Menyajikan tampilan onboarding event yang mewah dan elegan:
/// - Menampilkan orientasi [OnboardingVertical] saat perangkat dalam posisi Portrait.
/// - Menampilkan orientasi [OnboardingHorizontal] saat perangkat dalam posisi Landscape.
class OnboardingEventScreen extends StatelessWidget {
  final String? titlePrefix;
  final String? eventName;
  final String? eventDate;
  final String? eventLocation;
  final String? eventOrganizer;
  final int remainingSessions;
  final int? totalCredits;
  final int? remainingCredits;
  final String? bannerAsset;
  final Map<String, dynamic>? customTemplateData;
  final VoidCallback? onScanQr;
  final VoidCallback? onInputCode;
  final VoidCallback? onGuestAccess;

  const OnboardingEventScreen({
    super.key,
    this.titlePrefix,
    this.eventName,
    this.eventDate,
    this.eventLocation,
    this.eventOrganizer,
    this.remainingSessions = 300,
    this.totalCredits = 300,
    this.remainingCredits = 280,
    this.bannerAsset,
    this.customTemplateData,
    this.onScanQr,
    this.onInputCode,
    this.onGuestAccess,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return OnboardingHorizontal(
            titlePrefix: titlePrefix ?? 'The Wedding of',
            eventName: eventName ?? 'Asa & Aulia',
            eventDate: eventDate ?? '20 September 2026',
            eventLocation: eventLocation ?? 'The Ritz-Carlton, Jakarta',
            remainingSessions: remainingSessions,
            totalCredits: totalCredits,
            remainingCredits: remainingCredits,
            bannerAsset: bannerAsset,
            onScanQr: onScanQr,
            onInputCode: onInputCode,
            onGuestAccess: onGuestAccess,
          );
        } else {
          return OnboardingVertical(
            titlePrefix: titlePrefix,
            eventName: eventName,
            eventDate: eventDate,
            eventLocation: eventLocation,
            eventOrganizer: eventOrganizer,
            remainingSessions: remainingSessions,
            totalCredits: totalCredits,
            remainingCredits: remainingCredits,
            bannerAsset: bannerAsset,
            customTemplateData: customTemplateData,
            onScanQr: onScanQr,
            onInputCode: onInputCode,
            onGuestAccess: onGuestAccess,
          );
        }
      },
    );
  }
}
