import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_circularprogressbar.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/activity/presentation/components/ctacard_activity.dart';
import 'package:smileon/features/activity/presentation/components/ctacard_noactivity.dart';
import 'package:smileon/features/activity/presentation/components/eventattended_slider.dart';
import 'package:smileon/features/activity/presentation/components/lastphoto_slider.dart';
import 'package:smileon/features/activity/presentation/components/lasttransaction_slider.dart';
import 'package:smileon/features/activity/presentation/components/savedframe_slider.dart';

export 'package:smileon/features/activity/presentation/components/ctacard_activity.dart';
export 'package:smileon/features/activity/presentation/components/ctacard_noactivity.dart';
export 'package:smileon/features/activity/presentation/components/eventattended_slider.dart';
export 'package:smileon/features/activity/presentation/components/lastphoto_slider.dart';
export 'package:smileon/features/activity/presentation/components/lasttransaction_slider.dart';
export 'package:smileon/features/activity/presentation/components/savedframe_slider.dart';

/// Layar Aktivitas pengguna: Foto Terakhir, Frame Disimpan, Event Diikuti, dan Transaksi.
/// Seluruh fitur slider telah dimodularisasi menjadi komponen independen yang siap menerima data API.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  // Status momen: set true untuk CtaCardActivity, atau false untuk CtaCardNoActivity
  final bool _hasActivityMoment = true;

  // Status loading data dari API (dapat dipicu dari function pemanggilan API)
  bool _isLoadingApi = false;

  /// Function pemuatan data dari API (Programmatic Trigger)
  Future<void> fetchActivityDataFromApi() async {
    setState(() => _isLoadingApi = true);
    // Simulasi request API
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      setState(() => _isLoadingApi = false);
    }
  }

  /// Fungsi pemuatan/refresh saat layar ditarik dari atas ke bawah (Pull-To-Refresh Trigger)
  Future<void> _handlePullRefresh() async {
    // Simulasi request API saat ditarik
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: SmileRefreshIndicator(
          isLoading: _isLoadingApi,
          onRefresh: _handlePullRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // 1. Header Judul
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  t.activityTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E22),
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Banner CTA Card Aktivitas (Switch antara ada moment atau tidak ada)
              _hasActivityMoment
                  ? const CtaCardActivity()
                  : const CtaCardNoActivity(),
              const SizedBox(height: 24),

              // 3. Konten Komponen Slider Aktivitas
              const LastPhotoSlider(),
              const SizedBox(height: 24),
              const SavedFrameSlider(),
              const SizedBox(height: 24),
              const EventAttendedSlider(),
              const SizedBox(height: 24),
              const LastTransactionSlider(),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
