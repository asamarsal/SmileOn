import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/network/api_client.dart';
import 'package:smileon/core/network/api_endpoints.dart';
import 'package:smileon/features/activity/presentation/components/eventattended_slider.dart';
import 'package:smileon/features/activity/presentation/components/eventmade_slider.dart';
import 'package:smileon/features/activity/presentation/components/lasttransaction_slider.dart';
import 'package:smileon/features/activity/presentation/components/savedframe_slider.dart';

/// Provider Transaksi Pengguna dari Backend VPS (GET /api/v1/orders atau GET /api/v1/user/credits/ledger)
final activityTransactionsProvider =
    FutureProvider<List<TransactionActivityItem>>((ref) async {
  try {
    final client = ApiClient();
    final res = await client.get(ApiEndpoints.orders);
    if (res.statusCode == 200 && res.data != null) {
      final dataObj = res.data['data'];
      final List<dynamic> list = dataObj is Map && dataObj.containsKey('data')
          ? (dataObj['data'] as List<dynamic>)
          : (dataObj is List ? dataObj : []);

      if (list.isNotEmpty) {
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          final itemsList = m['items'] as List<dynamic>?;
          final firstItem = itemsList != null && itemsList.isNotEmpty
              ? itemsList.first as Map<String, dynamic>
              : null;
          final paymentMethod = m['payment_method'] as Map<String, dynamic>?;

          final title = firstItem?['name']?.toString() ??
              m['notes']?.toString() ??
              'Paket Kredit Foto SmileOn';
          final dateStr = _formatDate(m['created_at']?.toString());
          final amountIdr = m['total_amount'] != null
              ? '- Rp ${_formatNumber(m['total_amount'])}'
              : '- Rp 60.000';
          final cryptoStr = m['total_crypto'] != null
              ? '${m['total_crypto']} MON'
              : '0.60 MON';
          final status = m['status']?.toString().toLowerCase();

          return TransactionActivityItem(
            id: m['uuid']?.toString() ?? m['id']?.toString() ?? '',
            title: title,
            date: dateStr,
            amount: amountIdr,
            crypto: cryptoStr,
            paymentMethod: paymentMethod?['name']?.toString() ?? 'Monad Pay',
            isSuccess: status == 'paid' || status == 'completed',
          );
        }).toList();
      }
    }
  } catch (e) {
    debugPrint('activityTransactionsProvider: Gagal memuat dari API: $e');
  }
  return TransactionActivityItem.defaultItems;
});

/// Provider Event yang Dibuat Pengguna sebagai Host dari Backend VPS (GET /api/v1/events)
final activityCreatedEventsProvider =
    FutureProvider<List<CreatedEventActivityItem>>((ref) async {
  try {
    final client = ApiClient();
    final res = await client.get(ApiEndpoints.events);
    if (res.statusCode == 200 && res.data != null) {
      final dataObj = res.data['data'];
      final List<dynamic> list = dataObj is Map && dataObj.containsKey('data')
          ? (dataObj['data'] as List<dynamic>)
          : (dataObj is List ? dataObj : []);

      if (list.isNotEmpty) {
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          final totalCredits = (m['total_credits'] as num?)?.toInt() ?? 100;
          final usedCredits = (m['used_credits'] as num?)?.toInt() ?? 0;
          final guestsCount = (m['guest_vouchers_count'] ??
                  m['participants_count'] as num?)
                  ?.toInt() ??
              0;
          final dateStr = _formatDate(m['starts_at']?.toString() ?? m['created_at']?.toString());
          final accessCode = m['access_code']?.toString() ?? m['host_voucher_code']?.toString() ?? '';
          final coverUrl = m['cover_photo_url']?.toString() ?? m['banner_url']?.toString();

          return CreatedEventActivityItem(
            id: m['uuid']?.toString() ?? m['id']?.toString() ?? '',
            title: m['name']?.toString() ?? 'Acara SmileOn',
            date: dateStr,
            venue: m['venue']?.toString() ?? 'Venue Acara',
            totalCredits: totalCredits,
            usedCredits: usedCredits,
            totalGuests: guestsCount,
            voucherCode: accessCode,
            status: m['status']?.toString() ?? (m['is_active'] == false ? 'Selesai' : 'Aktif'),
            bannerAsset: (coverUrl != null && coverUrl.isNotEmpty)
                ? coverUrl
                : 'assets/images/eventmode/wedding_event_banner.jpg',
            shareLink: 'https://smileon-dapps.my.id/events/join/$accessCode',
          );
        }).toList();
      }
    }
  } catch (e) {
    debugPrint('activityCreatedEventsProvider: Gagal memuat dari API: $e');
  }
  return CreatedEventActivityItem.defaultItems;
});

/// Provider Event yang Diikuti Pengguna dari Backend VPS (GET /api/v1/user/events/joined)
final activityJoinedEventsProvider =
    FutureProvider<List<JoinedEventActivityItem>>((ref) async {
  try {
    final client = ApiClient();
    final res = await client.get(ApiEndpoints.joinedEvents);
    if (res.statusCode == 200 && res.data != null) {
      final dataObj = res.data['data'];
      final List<dynamic> list = dataObj is List
          ? dataObj
          : (dataObj is Map && dataObj.containsKey('data')
              ? (dataObj['data'] as List<dynamic>)
              : []);

      if (list.isNotEmpty) {
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          final totalCredits = (m['total_credits'] as num?)?.toInt() ?? 100;
          final dateStr = _formatDate(m['starts_at']?.toString() ?? m['created_at']?.toString());

          return JoinedEventActivityItem(
            id: m['uuid']?.toString() ?? m['id']?.toString() ?? '',
            title: m['name']?.toString() ?? 'Acara SmileOn',
            date: dateStr,
            venue: m['venue']?.toString() ?? 'Venue Acara',
            quota: '$totalCredits Kuota Foto HD',
            status: m['status']?.toString() ?? (m['is_active'] == false ? 'Selesai' : 'Aktif'),
          );
        }).toList();
      }
    }
  } catch (e) {
    debugPrint('activityJoinedEventsProvider: Gagal memuat dari API: $e');
  }
  return JoinedEventActivityItem.defaultItems;
});

/// Provider Frame yang Disimpan Pengguna dari Backend VPS (GET /api/v1/user/frames/saved)
final activitySavedFramesProvider =
    FutureProvider<List<SavedFrameActivityItem>>((ref) async {
  try {
    final client = ApiClient();
    final res = await client.get(ApiEndpoints.savedFrames);
    if (res.statusCode == 200 && res.data != null) {
      final dataObj = res.data['data'];
      final List<dynamic> list = dataObj is Map && dataObj.containsKey('data')
          ? (dataObj['data'] as List<dynamic>)
          : (dataObj is List ? dataObj : []);

      if (list.isNotEmpty) {
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          final category = m['category'] as Map<String, dynamic>?;
          final imgUrl = m['image_url']?.toString() ??
              m['thumbnail_url']?.toString() ??
              'assets/images/frame-example/frame-example-1.png';
          final isNetwork = imgUrl.startsWith('http://') || imgUrl.startsWith('https://');
          final isPremium = m['is_premium'] == true;
          final priceStr = isPremium
              ? (m['price_idr'] != null ? 'Rp ${_formatNumber(m['price_idr'])}' : 'Premium')
              : 'Gratis';

          return SavedFrameActivityItem(
            id: m['uuid']?.toString() ?? m['id']?.toString() ?? '',
            title: m['name']?.toString() ?? 'Smile Frame',
            imagePath: imgUrl,
            isNetwork: isNetwork,
            category: category?['name']?.toString() ?? 'Populer',
            price: priceStr,
          );
        }).toList();
      }
    }
  } catch (e) {
    debugPrint('activitySavedFramesProvider: Gagal memuat dari API: $e');
  }
  return SavedFrameActivityItem.defaultItems;
});

// Helper format tanggal singkat (e.g. 15 Sep 2026)
String _formatDate(String? raw) {
  if (raw == null || raw.isEmpty) return 'Hari ini';
  try {
    final dt = DateTime.parse(raw).toLocal();
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  } catch (_) {
    return raw;
  }
}

// Helper format angka ribuan (e.g. 60.000)
String _formatNumber(dynamic numVal) {
  if (numVal == null) return '0';
  final n = numVal is num ? numVal.toInt() : int.tryParse(numVal.toString()) ?? 0;
  final str = n.toString();
  final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  return str.replaceAllMapped(reg, (Match m) => '${m[1]}.');
}
