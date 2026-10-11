import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/features/activity/domain/models/user_voucher_model.dart';
import 'package:smileon/features/activity/presentation/category/myvoucher_activity.dart';
import 'package:smileon/features/activity/presentation/providers/user_voucher_provider.dart';
import 'package:smileon/features/camera/presentation/newsession_event_screen.dart';

/// Komponen Reusable Slider / List untuk Voucher Saya pada Layar Aktivitas
class MyVoucherSlider extends ConsumerWidget {
  final List<UserVoucherModel>? items;
  final bool isExpanded;
  final bool isLoading;
  final bool showHeader;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<UserVoucherModel>? onItemTap;

  const MyVoucherSlider({
    super.key,
    this.items,
    this.isExpanded = false,
    this.isLoading = false,
    this.showHeader = true,
    this.onSeeAllTap,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final allVouchers = ref.watch(userVoucherProvider);

    final dataList = items ?? allVouchers;
    final effectiveItems =
        isExpanded ? dataList : dataList.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF2E7E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.confirmation_number_rounded,
                        color: Color(0xFFFF2E7E),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.myVouchers,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1E22),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    if (onSeeAllTap != null) {
                      onSeeAllTap!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyVoucherActivityScreen(),
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        t.seeAll,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF2E7E),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFFFF2E7E),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (isLoading)
          _buildLoadingSkeleton()
        else if (effectiveItems.isEmpty)
          _buildEmptyState(context)
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: effectiveItems.map((voucher) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildVoucherTicketCard(context, voucher),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildVoucherTicketCard(
      BuildContext context, UserVoucherModel voucher) {
    final isActive = voucher.isActive;

    return GestureDetector(
      onTap: () {
        if (onItemTap != null) {
          onItemTap!(voucher);
        } else {
          _showVoucherDetailSheet(context, voucher);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFFFFD4E2) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Header Tag & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_offer_rounded,
                          size: 11,
                          color: Color(0xFFFF2E7E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          voucher.category,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF2E7E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      voucher.status,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? const Color(0xFF059669)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 2: Title & Kuota Foto
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1E22),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${voucher.photoCount} • Berlaku s/d ${voucher.expiryDate}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 3: Unique 32-character Code Box
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.qr_code_2_rounded,
                      size: 14,
                      color: Color(0xFFFF2E7E),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        voucher.voucherCode,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: voucher.voucherCode));
                        HapticFeedback.lightImpact();
                        SmileToast.showSuccess(
                          context,
                          title: 'Kode Disalin',
                          message:
                              'Kode voucher berhasil disalin ke papan klip',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEF3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.copy_rounded,
                                size: 10, color: Color(0xFFFF2E7E)),
                            SizedBox(width: 3),
                            Text(
                              'SALIN',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFF2E7E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.confirmation_number_outlined,
                  color: Color(0xFFFF2E7E), size: 24),
            ),
            const SizedBox(height: 10),
            const Text(
              'Belum Ada Voucher',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E22),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Beli voucher acara atau kredit foto di menu Pengaturan untuk memulai photobox.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: List.generate(2, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
      ),
    );
  }

  void _showVoucherDetailSheet(
      BuildContext context, UserVoucherModel voucher) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title Header & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1E22),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kategori: ${voucher.category} • ${voucher.photoCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Kode Voucher Box (32 Karakter Unik)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF0F5), Color(0xFFFAF2F8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFDDE9), width: 1.2),
                ),
                child: Column(
                  children: [
                    const Text(
                      'KODE VOUCHER ANDA (MAKS. 32 KARAKTER)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      voucher.voucherCode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF2E7E),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: voucher.voucherCode));
                        HapticFeedback.lightImpact();
                        SmileToast.showSuccess(
                          context,
                          title: 'Kode Disalin',
                          message: 'Kode voucher berhasil disalin!',
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Salin Kode Voucher'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF2E7E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Detail Info Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildRow('Harga Paket', voucher.priceFormatted),
                    const Divider(color: Color(0xFFE2E8F0), height: 16),
                    _buildRow('Metode Pembayaran', voucher.paymentMethod),
                    const Divider(color: Color(0xFFE2E8F0), height: 16),
                    _buildRow('Waktu Pembelian', voucher.purchaseDate),
                    const Divider(color: Color(0xFFE2E8F0), height: 16),
                    _buildRow('Berlaku Sampai', voucher.expiryDate),
                    const Divider(color: Color(0xFFE2E8F0), height: 16),
                    _buildRow('Status', voucher.status,
                        isHighlight: voucher.isActive),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Gunakan untuk Buat Event Baru
              if (voucher.isActive)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewSessionEventScreen(
                          totalCredits: voucher.creditAmount,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.celebration_rounded, size: 18),
                  label: const Text(
                    'Gunakan untuk Buat Event Baru',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2E7E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isHighlight
                ? const Color(0xFF059669)
                : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
