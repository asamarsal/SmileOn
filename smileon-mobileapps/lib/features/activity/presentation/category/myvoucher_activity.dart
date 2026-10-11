import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/activity/domain/models/user_voucher_model.dart';
import 'package:smileon/features/activity/presentation/components/myvoucher_slider.dart';
import 'package:smileon/features/activity/presentation/providers/user_voucher_provider.dart';

/// Halaman Kategori Detail: Semua Voucher yang Dimiliki Pengguna
class MyVoucherActivityScreen extends ConsumerStatefulWidget {
  const MyVoucherActivityScreen({super.key});

  @override
  ConsumerState<MyVoucherActivityScreen> createState() =>
      _MyVoucherActivityScreenState();
}

class _MyVoucherActivityScreenState
    extends ConsumerState<MyVoucherActivityScreen> {
  int _selectedFilterIndex = 0; // 0: Semua, 1: Aktif, 2: Digunakan

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);
    final allVouchers = ref.watch(userVoucherProvider);

    final activeCount = allVouchers.where((v) => v.isActive).length;
    final totalCredits = allVouchers
        .where((v) => v.isActive)
        .fold<int>(0, (sum, v) => sum + v.creditAmount);

    List<UserVoucherModel> filteredVouchers;
    if (_selectedFilterIndex == 1) {
      filteredVouchers = allVouchers.where((v) => v.isActive).toList();
    } else if (_selectedFilterIndex == 2) {
      filteredVouchers = allVouchers.where((v) => !v.isActive).toList();
    } else {
      filteredVouchers = allVouchers;
    }

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: AppTheme.cream,
        elevation: 0,
        centerTitle: true,
        title: Text(
          t.myVouchers,
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
              // Hero Banner Ringkasan Voucher
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
                              color:
                                  const Color(0xFFFF2E7E).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.confirmation_number_rounded,
                              color: Color(0xFFFF2E7E),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Koleksi Voucher Saya',
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
                        'Voucher Acara & Kredit Foto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Setiap voucher memiliki kode unik 32 karakter yang dapat digunakan saat membuat event baru.',
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
                            label: 'Total Voucher',
                            value: '${allVouchers.length} Voucher',
                            color: const Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 10),
                          _buildStatBadge(
                            label: 'Voucher Aktif',
                            value: '$activeCount Aktif',
                            color: const Color(0xFF4ADE80),
                          ),
                          const SizedBox(width: 10),
                          _buildStatBadge(
                            label: 'Kredit Tersedia',
                            value: '$totalCredits Foto',
                            color: const Color(0xFFF472B6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Filter Tabs (Semua, Aktif, Digunakan)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    _buildFilterChip(0, 'Semua (${allVouchers.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, 'Aktif ($activeCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        2, 'Selesai (${allVouchers.length - activeCount})'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // List Voucher
              MyVoucherSlider(
                isExpanded: true,
                showHeader: false,
                items: filteredVouchers,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF2E7E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF2E7E) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF2E7E).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
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
