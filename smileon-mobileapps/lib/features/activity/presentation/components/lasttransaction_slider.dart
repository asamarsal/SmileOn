import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/localization/app_translations.dart';
import 'package:smileon/features/activity/presentation/category/lasttransaction_activity.dart';

/// Model item Transaksi Terakhir
class TransactionActivityItem {
  final String id;
  final String title;
  final String date;
  final String amount;
  final String crypto;
  final String paymentMethod;
  final bool isSuccess;

  const TransactionActivityItem({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.crypto,
    required this.paymentMethod,
    this.isSuccess = true,
  });

  factory TransactionActivityItem.fromJson(Map<String, dynamic> json) {
    return TransactionActivityItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      crypto: json['crypto']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? 'Monad Pay',
      isSuccess: json['is_success'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'amount': amount,
      'crypto': crypto,
      'payment_method': paymentMethod,
      'is_success': isSuccess,
    };
  }

  /// Default mock items transaksi terakhir sesuai desain
  static List<TransactionActivityItem> get defaultItems => const [
        TransactionActivityItem(
          id: 'trx-1',
          title: 'Paket 50 Kredit Foto',
          date: '15 Sep 2026 • 14:20',
          amount: '- Rp 60.000',
          crypto: '0.60 MON',
          paymentMethod: 'Monad Pay',
          isSuccess: true,
        ),
        TransactionActivityItem(
          id: 'trx-2',
          title: 'Wedding Package Promo',
          date: '12 Sep 2026 • 10:05',
          amount: '- Rp 100.000',
          crypto: '1.00 MON',
          paymentMethod: 'QRIS',
          isSuccess: true,
        ),
        TransactionActivityItem(
          id: 'trx-3',
          title: 'Top Up Monad Wallet',
          date: '10 Sep 2026 • 18:44',
          amount: '+ 2.50 MON',
          crypto: '+2.50 MON',
          paymentMethod: 'Monad Network',
          isSuccess: true,
        ),
      ];
}

/// Komponen Reusable List / Slider untuk Transaksi Terakhir pada Layar Aktivitas
class LastTransactionSlider extends ConsumerWidget {
  final List<TransactionActivityItem>? items;
  final bool isExpanded;
  final bool isLoading;
  final bool showHeader;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<TransactionActivityItem>? onItemTap;

  const LastTransactionSlider({
    super.key,
    this.items,
    this.isExpanded = false,
    this.isLoading = false,
    this.showHeader = true,
    this.onSeeAllTap,
    this.onItemTap,
  });

  List<TransactionActivityItem> get _effectiveItems {
    final list = (items != null && items!.isNotEmpty)
        ? items!
        : TransactionActivityItem.defaultItems;
    return isExpanded ? list : list.take(2).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tProvider);
    final data = _effectiveItems;

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
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFFFF2E7E),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.recentTransactions,
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
                          builder: (context) =>
                              const LastTransactionActivityScreen(),
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
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: data.map((trx) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildTransactionCard(context, trx),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionActivityItem trx) {
    return GestureDetector(
      onTap: () {
        if (onItemTap != null) {
          onItemTap!(trx);
        } else {
          _showTransactionDetailBottomSheet(context, trx);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFF3F4F6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFFFF2E7E),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trx.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E22),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${trx.date} • ${trx.paymentMethod}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  trx.amount,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1E22),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Berhasil',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
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
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          );
        }),
      ),
    );
  }

  void _showTransactionDetailBottomSheet(
    BuildContext context,
    TransactionActivityItem trx,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detail Transaksi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E22),
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
              const SizedBox(height: 16),
              Text(
                trx.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E22),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Waktu: ${trx.date}',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                'Metode Pembayaran: ${trx.paymentMethod}',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 6),
              Text(
                'Total: ${trx.amount} (${trx.crypto})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF2E7E),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2E7E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: const Text('Tutup', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}
