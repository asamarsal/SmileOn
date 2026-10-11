import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/activity/presentation/components/eventmade_slider.dart';

/// Halaman Kategori Detail: Semua Event yang Dibuat (Pembuat Acara / Host)
class EventMadeActivityScreen extends ConsumerWidget {
  const EventMadeActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        centerTitle: true,
        title: Text(
          t.createdEvents,
          style: const TextStyle(
            color: Color(0xFF1E1E22),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryRose),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner Ringkasan Acara Host
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2B2B30), Color(0xFF1E1E22)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF2E7E).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFFFF2E7E),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Ringkasan Penyelenggara',
                            style: TextStyle(
                              color: Color(0xFFFF2E7E),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Acara yang Kamu Buat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Kelola kuota foto, daftar tamu undangan, dan status booth photobox acaramu di satu tempat.',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildStatBadge(
                            label: 'Total Acara',
                            value: '3 Acara',
                            color: const Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 10),
                          _buildStatBadge(
                            label: 'Total Kuota',
                            value: '550 Foto',
                            color: const Color(0xFF4ADE80),
                          ),
                          const SizedBox(width: 10),
                          _buildStatBadge(
                            label: 'Tamu Terdaftar',
                            value: '395 Tamu',
                            color: const Color(0xFFF472B6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Daftar Lengkap Event yang Dibuat
              const EventMadeSlider(
                isExpanded: true,
                showHeader: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
