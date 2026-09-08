import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/core/localization/app_translations.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isScanQrMode = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tProvider);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryRose,
              unselectedLabelColor: AppTheme.muted,
              indicatorColor: AppTheme.primaryRose,
              tabs: [
                Tab(text: t.tabEvent),
                Tab(text: t.tabPersonal),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildEventAccessTab(t), _buildPersonalAccessTab(t)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventAccessTab(AppTranslations t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Text(
            t.eventAccessTitle,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.eventAccessDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Toggle Scan QR / Kode Voucher
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isScanQrMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isScanQrMode
                            ? AppTheme.primaryRose
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          t.scanQr,
                          style: TextStyle(
                            color: isScanQrMode ? Colors.white : AppTheme.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isScanQrMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isScanQrMode
                            ? AppTheme.primaryRose
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          t.voucherCode,
                          style: TextStyle(
                            color: !isScanQrMode ? Colors.white : AppTheme.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // QR Scanner Placeholder
          if (isScanQrMode) ...[
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 150,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  Positioned(
                    bottom: 24,
                    child: Text(
                      t.pointCamera,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Divider "atau"
          Row(
            children: [
              Expanded(child: Divider(color: AppTheme.muted.withOpacity(0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(t.or, style: const TextStyle(color: AppTheme.text)),
              ),
              Expanded(child: Divider(color: AppTheme.muted.withOpacity(0.3))),
            ],
          ),
          const SizedBox(height: 24),

          // Voucher Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: t.inputVoucherHint,
                hintStyle: const TextStyle(color: AppTheme.muted),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                suffixIcon: const Icon(
                  Icons.confirmation_number_outlined,
                  color: AppTheme.primaryRose,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRose,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                t.checkVoucher,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPersonalAccessTab(AppTranslations t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline,
            size: 80,
            color: AppTheme.primaryRose,
          ),
          const SizedBox(height: 16),
          Text(
            t.personalAccessTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.personalAccessDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Text(
              t.startCamera,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
