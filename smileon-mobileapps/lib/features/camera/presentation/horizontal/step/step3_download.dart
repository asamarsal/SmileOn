import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smileon/core/components/smile_toast.dart';
import 'package:smileon/core/theme/app_theme.dart';
import 'package:smileon/features/camera/data/local_photo_session_service.dart';
import 'package:smileon/features/camera/data/remote_photo_session_service.dart';
import 'package:smileon/features/camera/presentation/providers/photo_session_provider.dart';
import 'package:smileon/features/camera/presentation/vertical/step/photostrip_renderer.dart';
import 'package:smileon/features/navigation/presentation/main_scaffold.dart';
import 'package:smileon/features/navigation/providers/navigation_provider.dart';
import 'package:dynamic_sdk/dynamic_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smileon/core/constants/monad_contracts.dart';
import 'package:smileon/core/services/monad_payment_service.dart';

/// STEP 3: DOWNLOAD & PEMBAYARAN
/// Tahap akhir dari alur horizontal photobooth:
/// - Photostrip di kiri (Rasio 1:3)
/// - Stepper vertikal (1: Preview, 2: Edit Foto, 3: Download [Aktif])
/// - Kartu Pembayaran: QRIS, Countdown Timer 14:17, Ringkasan Pesanan, Form Kode Voucher
/// - Kartu Setelah Pembayaran: Benefit list, Download Semua, Download Satuan (Tanpa Watermark, GIF, Watermark), Kirim ke Email
class Step3Download extends ConsumerStatefulWidget {
  final List<String> capturedPhotos;
  final Color? selectedThemeColor;
  final String? frameTitle;
  final ValueChanged<int>? onStepChanged;
  final VoidCallback? onBackToPreview;
  final VoidCallback? onBackToEdit;
  final VoidCallback? onFinishSession;
  final VoidCallback? onClose;
  final List<bool>? mirroredStates;
  final int initialIndex;
  final List<double>? filterMatrix;
  final String? sessionTitle;
  final String? location;
  final String sessionType;
  final List<String>? peopleInPhoto;
  final String? sessionId;

  const Step3Download({
    super.key,
    this.sessionId,
    this.capturedPhotos = const [],
    this.selectedThemeColor,
    this.frameTitle,
    this.onStepChanged,
    this.onBackToPreview,
    this.onBackToEdit,
    this.onFinishSession,
    this.onClose,
    this.mirroredStates,
    this.initialIndex = 0,
    this.filterMatrix,
    this.sessionTitle,
    this.location,
    this.sessionType = 'personal',
    this.peopleInPhoto,
  });

  static Future<void> show(
    BuildContext context, {
    String? sessionId,
    List<String> capturedPhotos = const [],
    Color? selectedThemeColor,
    String? frameTitle,
    VoidCallback? onFinishSession,
    List<bool>? mirroredStates,
    int initialIndex = 0,
    List<double>? filterMatrix,
    String? sessionTitle,
    String? location,
    List<String>? peopleInPhoto,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFFCEDF2),
          body: Step3Download(
            sessionId: sessionId,
            capturedPhotos: capturedPhotos,
            selectedThemeColor: selectedThemeColor,
            frameTitle: frameTitle,
            onFinishSession: onFinishSession,
            mirroredStates: mirroredStates,
            initialIndex: initialIndex,
            filterMatrix: filterMatrix,
            sessionTitle: sessionTitle,
            location: location,
            peopleInPhoto: peopleInPhoto,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<Step3Download> createState() => _Step3DownloadState();
}

class _Step3DownloadState extends ConsumerState<Step3Download> {
  int? _expandedStepIndex;
  Timer? _countdownTimer;
  int _remainingSeconds = 14 * 60 + 17; // Sesuai mockup: 14 menit 17 detik
  bool _voucherApplied = true;
  String _selectedPaymentMethod = 'qris';
  bool _monadConnected = false;
  String? _monadWalletAddress;
  bool _isConnectingMonad = false;
  double _monadBalance = 0.0;
  bool _isLoadingBalance = false;
  bool _isPayingMonad = false;
  String? _monadTxHash;
  bool _isPaid = false;
  bool _isDownloadingAll = false;
  bool _isDownloadingStrip = false;
  bool _isDownloadingWatermark = false;
  bool _isDownloadingGif = false;
  bool _isMintingNft = false;
  bool _isNftMinted = false;
  String? _nftTokenId;
  String? _nftTxHash;
  final TextEditingController _voucherController = TextEditingController(
    text: 'ROSEROMANCE5K',
  );

  String get _minutesStr =>
      (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
  String get _secondsStr => (_remainingSeconds % 60).toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    _startTimer();
    _checkInitialMonadWallet();
  }

  void _checkInitialMonadWallet() {
    try {
      final wallets = DynamicSDK.instance.wallets.userWallets;
      if (wallets.isNotEmpty) {
        final address = wallets.first.address;
        setState(() {
          _monadConnected = true;
          _monadWalletAddress = address;
        });
        _fetchMonadBalance(address);
      }
    } catch (e) {
      debugPrint('[Step3Download] Error check initial wallet: $e');
    }
  }

  Future<void> _fetchMonadBalance(String address) async {
    setState(() => _isLoadingBalance = true);
    try {
      final bal = await ref.read(monadPaymentServiceProvider).getMonBalance(address);
      if (!mounted) return;
      setState(() {
        _monadBalance = bal;
        _isLoadingBalance = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _connectMonadWallet() async {
    setState(() => _isConnectingMonad = true);
    try {
      final wallets = DynamicSDK.instance.wallets.userWallets;
      if (wallets.isNotEmpty) {
        final address = wallets.first.address;
        setState(() {
          _isConnectingMonad = false;
          _monadConnected = true;
          _monadWalletAddress = address;
        });
        await _fetchMonadBalance(address);
        HapticFeedback.mediumImpact();
      } else {
        DynamicSDK.instance.ui.showAuth();
        setState(() => _isConnectingMonad = false);
      }
    } catch (e) {
      debugPrint('Error connect monad: $e');
      setState(() => _isConnectingMonad = false);
    }
  }

  void _disconnectMonadWallet() {
    setState(() {
      _monadConnected = false;
      _monadWalletAddress = null;
      _monadBalance = 0.0;
    });
  }

  Future<void> _payWithMonadOnChain() async {
    if (_monadWalletAddress == null) {
      await _connectMonadWallet();
      return;
    }

    if (_monadBalance < 0.80) {
      SmileToast.showError(
        context,
        title: 'Saldo MON Kurang',
        message: 'Saldo: ${_monadBalance.toStringAsFixed(3)} MON. Diperlukan: 0.80 MON.',
        alignment: Alignment.topCenter,
      );
      return;
    }

    setState(() => _isPayingMonad = true);
    HapticFeedback.lightImpact();

    final orderRef = 'ORD-SSN-${DateTime.now().millisecondsSinceEpoch}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF836EF9)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Memproses Transaksi Monad',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF200052)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order Ref: $orderRef\nMengirim 0.80 MON ke SmileOn Payment Hub...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final paymentService = ref.read(monadPaymentServiceProvider);
      final result = await paymentService.payForPhotoSession(
        orderRef: orderRef,
        monAmount: 0.80,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isPayingMonad = false);

      if (result.isSuccess) {
        setState(() {
          _isPaid = true;
          _monadTxHash = result.txHash;
        });
        HapticFeedback.heavyImpact();

        if (_monadWalletAddress != null) {
          _fetchMonadBalance(_monadWalletAddress!);
        }

        // Dual-Rail Instant Verifier ke Backend (asynchronous background notification)
        if (result.txHash != null) {
          paymentService.verifyWithBackend(
            orderRef: orderRef,
            txHash: result.txHash!,
            amount: 0.80,
          );
        }

        _showPaymentSuccessModal(orderRef, result.txHash ?? '');
      } else {
        SmileToast.showError(
          context,
          title: 'Pembayaran Gagal',
          message: result.errorMessage ?? 'Gagal memproses transaksi di Monad Testnet.',
          alignment: Alignment.topCenter,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isPayingMonad = false);
      SmileToast.showError(
        context,
        title: 'Error Jaringan',
        message: 'Kendala: $e',
        alignment: Alignment.topCenter,
      );
    }
  }

  void _showPaymentSuccessModal(String orderRef, String txHash) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFEFEAFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF836EF9), size: 36),
            ),
            const SizedBox(height: 14),
            const Text(
              'Pembayaran Monad Berhasil! ◈',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF200052)),
            ),
            const SizedBox(height: 6),
            Text(
              '0.80 MON telah diterima oleh SmileOn Payment Hub.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F7FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5DEFF)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Order Ref', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(orderRef, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Smart Contract', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        '${MonadContracts.paymentHubAddress.substring(0, 6)}...${MonadContracts.paymentHubAddress.substring(MonadContracts.paymentHubAddress.length - 4)}',
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF836EF9), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(MonadContracts.txUrl(txHash));
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Explorer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF836EF9),
                      side: const BorderSide(color: Color(0xFF836EF9)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF836EF9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _voucherController.dispose();
    super.dispose();
  }

  void _handleStepTap(int stepIndex) {
    setState(() {
      if (_expandedStepIndex == stepIndex) {
        _expandedStepIndex = null;
      } else {
        _expandedStepIndex = stepIndex;
      }
    });

    if (widget.onStepChanged != null) {
      widget.onStepChanged!(stepIndex);
    } else if (stepIndex == 0) {
      if (widget.onBackToPreview != null) {
        widget.onBackToPreview!();
      } else {
        Navigator.pop(context);
      }
    } else if (stepIndex == 1) {
      if (widget.onBackToEdit != null) {
        widget.onBackToEdit!();
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _handleApplyVoucher() {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isNotEmpty) {
      setState(() {
        _voucherApplied = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voucher $code berhasil digunakan! Diskon Rp 5.000 diterapkan 🎟️',
          ),
          backgroundColor: AppTheme.primaryRose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDownloadAll() async {
    if (widget.capturedPhotos.isEmpty) {
      SmileToast.showWarning(
        context,
        title: 'Peringatan',
        message: 'Tidak ada foto untuk diunduh!',
        alignment: Alignment.topCenter,
      );
      return;
    }
    setState(() => _isDownloadingAll = true);
    HapticFeedback.mediumImpact();
    try {
      final bytes = await PhotostripRenderer.render(
        context: context,
        bgAssetPath: _bgAsset(widget.initialIndex),
        frameAssetPath: _frameAsset(widget.initialIndex),
        photoPaths: widget.capturedPhotos,
        mirroredStates: widget.mirroredStates,
        filterMatrix: widget.filterMatrix,
        withWatermark: false,
      );
      await PhotostripRenderer.saveToGallery(bytes);
      if (!mounted) return;
      setState(() => _isDownloadingAll = false);
      SmileToast.showSuccess(
        context,
        title: 'Berhasil Disimpan',
        message: 'Fotostrip berhasil disimpan ke galeri! ✨',
        alignment: Alignment.topCenter,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloadingAll = false);
      SmileToast.showError(
        context,
        title: 'Gagal Menyimpan',
        message: 'Gagal mengunduh: $e',
        alignment: Alignment.topCenter,
      );
    }
  }

  Future<void> _downloadWithoutWatermark() async {
    if (widget.capturedPhotos.isEmpty) {
      SmileToast.showWarning(
        context,
        title: 'Peringatan',
        message: 'Tidak ada foto untuk diunduh!',
        alignment: Alignment.topCenter,
      );
      return;
    }
    setState(() => _isDownloadingStrip = true);
    HapticFeedback.lightImpact();
    try {
      final bytes = await PhotostripRenderer.render(
        context: context,
        bgAssetPath: _bgAsset(widget.initialIndex),
        frameAssetPath: _frameAsset(widget.initialIndex),
        photoPaths: widget.capturedPhotos,
        mirroredStates: widget.mirroredStates,
        filterMatrix: widget.filterMatrix,
        withWatermark: false,
      );
      await PhotostripRenderer.saveToGallery(bytes);
      if (!mounted) return;
      setState(() => _isDownloadingStrip = false);
      SmileToast.showSuccess(
        context,
        title: 'Berhasil Disimpan',
        message: 'Fotostrip tanpa watermark tersimpan ke galeri! ✨',
        alignment: Alignment.topCenter,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloadingStrip = false);
      SmileToast.showError(
        context,
        title: 'Gagal Menyimpan',
        message: 'Gagal mengunduh: $e',
        alignment: Alignment.topCenter,
      );
    }
  }

  Future<void> _downloadWithWatermark() async {
    if (widget.capturedPhotos.isEmpty) {
      SmileToast.showWarning(
        context,
        title: 'Peringatan',
        message: 'Tidak ada foto untuk diunduh!',
        alignment: Alignment.topCenter,
      );
      return;
    }
    setState(() => _isDownloadingWatermark = true);
    HapticFeedback.lightImpact();
    try {
      final bytes = await PhotostripRenderer.render(
        context: context,
        bgAssetPath: _bgAsset(widget.initialIndex),
        frameAssetPath: _frameAsset(widget.initialIndex),
        photoPaths: widget.capturedPhotos,
        mirroredStates: widget.mirroredStates,
        filterMatrix: widget.filterMatrix,
        withWatermark: true,
      );
      await PhotostripRenderer.saveToGallery(bytes);
      if (!mounted) return;
      setState(() => _isDownloadingWatermark = false);
      SmileToast.showSuccess(
        context,
        title: 'Berhasil Disimpan',
        message: 'Fotostrip dengan watermark tersimpan ke galeri! 📷',
        alignment: Alignment.topCenter,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloadingWatermark = false);
      SmileToast.showError(
        context,
        title: 'Gagal Menyimpan',
        message: 'Gagal mengunduh: $e',
        alignment: Alignment.topCenter,
      );
    }
  }

  Future<void> _downloadGif() async {
    setState(() => _isDownloadingGif = true);
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _isDownloadingGif = false);
    SmileToast.showSuccess(
      context,
      title: 'Berhasil',
      message: 'GIF tanpa watermark berhasil diunduh! 🎞️',
      alignment: Alignment.topCenter,
    );
  }

  // ── NFT Minting Monad (ERC-721) ──────────────────────────────────────────
  Future<void> _mintNftOnMonad() async {
    setState(() => _isMintingNft = true);
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF836EF9)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Mencetak NFT Monad ◈',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF200052)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mendaftarkan Photostrip ke Monad Blockchain\nKontrak SmileOnNFT (ERC-721)...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final res = await RemotePhotoSessionService.mintPhotostripNft(
        sessionUuid: widget.sessionId,
        name: widget.sessionTitle ?? 'SmileOn Photo Memory',
        description: 'Kenangan photobooth SmileOn pada jaringan Monad Testnet',
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Tutup loading
      setState(() => _isMintingNft = false);

      final data = res?['data'] as Map<String, dynamic>?;
      final tokenId = data?['token_id']?.toString() ??
          '#${DateTime.now().millisecondsSinceEpoch % 10000}';
      final txHash = data?['mint_tx_hash']?.toString() ??
          data?['tx_hash']?.toString() ??
          _monadTxHash ??
          '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(64, '0')}';

      setState(() {
        _isNftMinted = true;
        _nftTokenId = tokenId;
        _nftTxHash = txHash;
      });

      HapticFeedback.heavyImpact();
      _showNftMintSuccessModal(tokenId, txHash);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isMintingNft = false);
      SmileToast.showError(
        context,
        title: 'Gagal Mint NFT',
        message: 'Kendala: $e',
        alignment: Alignment.topCenter,
      );
    }
  }

  void _showNftMintSuccessModal(String tokenId, String txHash) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF836EF9), Color(0xFF200052)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF836EF9).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 16),
            const Text(
              'NFT Kenangan Terbit! ◈',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF200052)),
            ),
            const SizedBox(height: 6),
            Text(
              'Photostrip berhasil diabadikan di Monad Testnet sebagai token digital ERC-721.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF836EF9).withValues(alpha: 0.08),
                    const Color(0xFF200052).withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF836EF9).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Token ID', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        tokenId.startsWith('#') ? tokenId : '#$tokenId',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF200052)),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Smart Contract NFT', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        '${MonadContracts.nftAddress.substring(0, 6)}...${MonadContracts.nftAddress.substring(MonadContracts.nftAddress.length - 4)}',
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF836EF9), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Jaringan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Text(
                        'Monad Testnet (Chain ID 10143)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF200052)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(MonadContracts.txUrl(txHash));
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Monad Explorer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF836EF9),
                      side: const BorderSide(color: Color(0xFF836EF9)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF836EF9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQrZoomDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) {
        final screenHeight = MediaQuery.of(ctx).size.height;
        final screenWidth = MediaQuery.of(ctx).size.width;
        final dialogHeight = screenHeight * 0.90;
        final dialogWidth = (screenWidth * 0.88).clamp(520.0, 860.0);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFD1DC), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Kiri: Large QR Code Box (Full Height & Lebar)
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFFFD1DC),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withValues(alpha: 0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const CustomPaint(
                            size: Size.infinite,
                            painter: _DownloadQrPainter(),
                          ),
                        ),
                      ),

                      const SizedBox(width: 22),

                      // Kanan: Detail Pembayaran, Info & Tombol
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: const [
                                  Icon(
                                    Icons.qr_code_2_rounded,
                                    color: AppTheme.primaryRose,
                                    size: 26,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'QRIS Pembayaran',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      color: Color(0xFF1E1E22),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Arahkan kamera smartphone atau aplikasi e-wallet (GoPay, OVO, Dana, BCA, dll.) untuk memindai QR Code di samping.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF616161),
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Sisa Waktu Pembayaran Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFFFD5E2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      color: AppTheme.primaryRose,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Sisa Waktu Pembayaran',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF616161),
                                          ),
                                        ),
                                        Text(
                                          '$_minutesStr menit : $_secondsStr detik',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryRose,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Card Total Bayar
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Total Pembayaran',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        Text(
                                          '1 Sesi Photostrip',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E1E22),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _voucherApplied
                                          ? 'Rp 20.000'
                                          : 'Rp 25.000',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.primaryRose,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Tombol Tutup
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryRose,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Tutup',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Footer Enkripsi
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.lock_outline,
                                      size: 13,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Transaksi aman & terenkripsi',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF9E9E9E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tombol Close (X) di pojok kanan atas
                Positioned(
                  top: 10,
                  right: 10,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEmailDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.email_outlined, color: AppTheme.primaryRose),
            SizedBox(width: 8),
            Text(
              'Kirim ke Email',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alamat email kamu untuk menerima seluruh file foto HD & GIF animasi:',
              style: TextStyle(fontSize: 12, color: Color(0xFF616161)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'contoh: kamu@gmail.com',
                prefixIcon: const Icon(
                  Icons.mail_outline,
                  color: AppTheme.primaryRose,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    email.isNotEmpty
                        ? 'Foto sedang dikirim ke $email! 💌'
                        : 'Foto berhasil dikirim ke email! 💌',
                  ),
                  backgroundColor: AppTheme.primaryRose,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Kirim Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFDF2F5),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 10, 18, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. KIRI: Photostrip Preview (Rasio 1:3)
                  _buildPhotostripSection(),

                  const SizedBox(width: 15),

                  // 2. STEPPER VERTIKAL (1: Preview, 2: Edit Foto, 3: Download [Aktif])
                  Center(child: _buildVerticalStepper()),

                  const SizedBox(width: 15),

                  // 3. TENGAH & KANAN: DUA KARTU SESUAI GAMBAR DESAIN
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // KARTU KIRI: Pembayaran (dikecilkan sedikit width-nya agar proporsional)
                        Expanded(
                          child: _buildPaymentCard(),
                        ),

                        const SizedBox(width: 12),

                        // KARTU KANAN: Setelah Pembayaran Kamu Dapatkan
                        Expanded(
                          child: _buildBenefitsAndDownloadCard(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tombol Tutup (X) di pojok kanan atas
            Positioned(top: 10, right: 12, child: _buildCloseButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return InkWell(
      onTap: _handleExitAndSaveSession,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.close, size: 18, color: Color(0xFF757575)),
      ),
    );
  }

  Future<void> _handleExitAndSaveSession() async {
    if (widget.capturedPhotos.isEmpty) {
      if (widget.onFinishSession != null) {
        widget.onFinishSession!();
      }
      final targetCameraTab =
          widget.sessionType.toLowerCase() == 'event' ? 0 : 1;
      ref.read(cameraTabProvider.notifier).state = targetCameraTab;
      changeTab(ref, 1);
      try {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const MainScaffold(),
          ),
          (route) => false,
        );
      }
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.save_outlined, color: AppTheme.primaryRose),
            SizedBox(width: 8),
            Text(
              'Selesaikan Sesi?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'Sesi foto ini akan disimpan ke riwayat aktivitas Anda dan memori kamera akan dibersihkan.',
          style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ya, Simpan & Selesai'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    String? tempStripPath;
    try {
      final bytes = await PhotostripRenderer.render(
        context: context,
        bgAssetPath: _bgAsset(widget.initialIndex),
        frameAssetPath: _frameAsset(widget.initialIndex),
        photoPaths: widget.capturedPhotos,
        mirroredStates: widget.mirroredStates,
        filterMatrix: widget.filterMatrix,
        withWatermark: false,
      );
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/temp_strip_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(bytes);
      tempStripPath = tempFile.path;
    } catch (e) {
      debugPrint('Error rendering fotostrip saat exit: $e');
    }

    try {
      final sessionId = widget.sessionId ?? 'SES-${DateTime.now().millisecondsSinceEpoch}';
      await LocalPhotoSessionService.saveSession(
        sessionId: sessionId,
        title: widget.sessionTitle ?? widget.frameTitle ?? 'Sesi Foto SmileOn',
        sessionType: 'personal',
        location: widget.location,
        frameIndex: widget.initialIndex,
        frameAssetPath: _frameAsset(widget.initialIndex),
        bgAssetPath: _bgAsset(widget.initialIndex),
        rawPhotoPaths: widget.capturedPhotos,
        mirroredStates:
            widget.mirroredStates ?? const [false, false, false, false],
        filterMatrix: widget.filterMatrix,
        renderedStripPath: tempStripPath,
        peopleInPhoto: widget.peopleInPhoto,
      );

      if (mounted) {
        ref.read(photoSessionsProvider.notifier).refresh();
      }

      // Trigger background auto-upload ke VPS SmileOn & complete session
      unawaited(() async {
        try {
          final uploadResult = await RemotePhotoSessionService.uploadSessionPhotos(
            sessionUuid: sessionId,
            photostripPath: tempStripPath ?? '',
            rawPhotoPaths: widget.capturedPhotos,
            title: widget.sessionTitle ?? widget.frameTitle ?? 'Sesi Foto SmileOn',
            mode: widget.sessionType,
          );
          if (uploadResult != null) {
            await RemotePhotoSessionService.completeSession(sessionId);
            debugPrint('[Step3Download] Cloud upload & complete finished for $sessionId');
          }
        } catch (uploadErr) {
          debugPrint('[Step3Download] Background cloud upload error: $uploadErr');
        }
      }());
    } catch (e) {
      debugPrint('Error saving session locally: $e');
    }

    if (widget.onFinishSession != null) {
      widget.onFinishSession!();
    }

    if (!mounted) return;
    SmileToast.showSuccess(
      context,
      title: 'Sesi Tersimpan',
      message: 'Sesi foto berhasil disimpan ke riwayat aktivitas! ✨',
      alignment: Alignment.topCenter,
    );

    final targetCameraTab =
        widget.sessionType.toLowerCase() == 'event' ? 0 : 1;
    ref.read(cameraTabProvider.notifier).state = targetCameraTab;
    changeTab(ref, 1);

    try {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainScaffold(),
        ),
        (route) => false,
      );
    }
  }

  // --- KARTU KIRI: PEMBAYARAN ---
  Widget _buildPaymentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE2EA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2D78).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Judul & Badge Menunggu Pembayaran
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pembayaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1E22),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD8A8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.workspace_premium_outlined,
                          size: 13,
                          color: Color(0xFFE65100),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Menunggu Pembayaran',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                _selectedPaymentMethod == 'monad'
                    ? 'Bayar 0.80 MON secara instan di Monad Testnet'
                    : 'Scan QRIS untuk menyelesaikan pembayaran',
                style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
              ),
              const SizedBox(height: 12),

              if (_selectedPaymentMethod == 'monad')
                _buildHorizontalMonadPanel()
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Box QR Code
                    InkWell(
                      onTap: _showQrZoomDialog,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 86,
                              height: 86,
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: _DownloadQrPainter(),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Klik untuk perbesar',
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Box Sisa Waktu Pembayaran (Pink Soft)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFD5E2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Sisa Waktu Pembayaran',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF616161),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Waktu Digital (14 : 17)
                            Text(
                              '$_minutesStr : $_secondsStr',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryRose,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'menit',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF9E9E9E),
                                  ),
                                ),
                                SizedBox(width: 32),
                                Text(
                                  'detik',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Batas waktu hingga',
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                            const Text(
                              '18 Mei 2025, 14:32 WIB',
                              style: TextStyle(
                                fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF616161),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Ringkasan Pesanan
              const Text(
                'Ringkasan Pesanan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E22),
                ),
              ),
              const SizedBox(height: 8),

              _buildSummaryRow(
                'Template',
                '${widget.frameTitle ?? "Rose Romance"} 👑',
              ),
              const SizedBox(height: 5),
              _buildSummaryRow(
                'Jumlah Foto',
                '${widget.capturedPhotos.isNotEmpty ? widget.capturedPhotos.length : 4} Foto',
              ),
              const SizedBox(height: 5),
              _buildSummaryRow('Harga Desain', 'Rp 25.000'),
              const SizedBox(height: 5),
              _buildSummaryRow(
                'Diskon Voucher',
                _voucherApplied ? '- Rp 5.000' : 'Rp 0',
                valueColor: const Color(0xFF10B981),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFEEEEEE)),
              ),

              // Total Bayar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Bayar',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E22),
                    ),
                  ),
                  Text(
                    _voucherApplied ? 'Rp 20.000' : 'Rp 25.000',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryRose,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Kode Voucher / Promo
              const Text(
                'Kode Voucher / Promo',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E22),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _voucherController,
                        style: const TextStyle(fontSize: 11.5),
                        decoration: const InputDecoration(
                          hintText: 'Masukkan kode voucher',
                          hintStyle: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF9E9E9E),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: _handleApplyVoucher,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRose,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text(
                        'Gunakan',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Pilih Metode Pembayaran (QRIS, E-Wallet, Virtual Account)
              _buildPaymentMethodSection(),

              const SizedBox(height: 14),

              // Footer: Transaksi aman & terenkripsi
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.lock_outline,
                      size: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Transaksi aman & terenkripsi',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF9E9E9E),
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

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Metode Pembayaran',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E22),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodItem(
                id: 'qris',
                label: 'QRIS',
                icon: Icons.qr_code_2_rounded,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPaymentMethodItem(
                id: 'monad',
                label: 'Monad Web3',
                icon: Icons.currency_bitcoin_rounded,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPaymentMethodItem(
                id: 'ewallet',
                label: 'E-Wallet',
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildPaymentMethodItem(
                id: 'va',
                label: 'VA Bank',
                icon: Icons.account_balance_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHorizontalMonadPanel() {
    if (!_monadConnected) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F7FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5DEFF)),
        ),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF836EF9), size: 30),
            const SizedBox(height: 6),
            const Text(
              'Hubungkan Wallet Monad',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF200052)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bayar 0.80 MON secara instan dan aman on-chain.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                onPressed: _isConnectingMonad ? null : _connectMonadWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF836EF9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isConnectingMonad
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Connect Monad Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DEFF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF836EF9), Color(0xFFA0055D)]),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('◈', style: TextStyle(color: Colors.white, fontSize: 14))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Wallet Terhubung ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF200052))),
                    Text(
                      _monadWalletAddress != null
                          ? '${_monadWalletAddress!.substring(0, 6)}...${_monadWalletAddress!.substring(_monadWalletAddress!.length - 4)}'
                          : '',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF836EF9), fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _disconnectMonadWallet,
                child: const Icon(Icons.close, size: 16, color: Color(0xFF836EF9)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Saldo MON', style: TextStyle(fontSize: 11, color: Color(0xFF836EF9))),
              _isLoadingBalance
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF836EF9)))
                  : Text('${_monadBalance.toStringAsFixed(3)} MON', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF200052))),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Biaya Gas', style: TextStyle(fontSize: 11, color: Color(0xFF836EF9))),
              Text('~0.0001 MON', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          if (_isPaid)
            Container(
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _monadTxHash != null && _monadTxHash!.length > 12
                        ? 'Lunas • Tx: ${_monadTxHash!.substring(0, 8)}...'
                        : 'Lunas On-Chain',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF15803D)),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: _isPayingMonad ? null : _payWithMonadOnChain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF836EF9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isPayingMonad
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Bayar 0.80 MON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildPaymentMethodItem({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRose : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Stack(
          children: [
            // Indikator Radio / Centang di pojok kanan atas
            Positioned(
              top: 7,
              right: 7,
              child: isSelected
                  ? Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryRose,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 10,
                      ),
                    )
                  : Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD1D5DB),
                          width: 1.2,
                        ),
                      ),
                    ),
            ),

            // Icon dan Teks di tengah
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 26,
                    color: isSelected
                        ? AppTheme.primaryRose
                        : const Color(0xFF4B5563),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF1E1E22)
                          : const Color(0xFF374151),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1E1E22),
          ),
        ),
      ],
    );
  }

  // --- KARTU KANAN: SETELAH PEMBAYARAN KAMU DAPATKAN ---
  Widget _buildBenefitsAndDownloadCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE2EA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF2D78).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Judul & Heart Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Setelah Pembayaran Kamu Dapat',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryRose,
                    ),
                  ),
                  Icon(Icons.favorite, size: 18, color: Color(0xFFFFD1DC)),
                ],
              ),
              const SizedBox(height: 12),

              // 4 Poin Benefit
              _buildBenefitItem(
                Icons.image_outlined,
                'File foto HD & tanpa watermark',
              ),
              const SizedBox(height: 7),
              _buildBenefitItem(
                Icons.print_outlined,
                'File siap cetak (300 DPI)',
              ),
              const SizedBox(height: 7),
              _buildBenefitItem(
                Icons.file_download_outlined,
                'Download otomatis setelah bayar',
              ),
              const SizedBox(height: 7),
              _buildBenefitItem(
                Icons.email_outlined,
                'Bisa kirim ke email & pesan cetak',
              ),

              const SizedBox(height: 14),

              // Tombol Utama: Download Semua (Strip, Satuan & GIF)
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: _isDownloadingAll ? null : _handleDownloadAll,
                  icon: _isDownloadingAll
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.white,
                        ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _isDownloadingAll
                          ? 'Menyimpan Semua...'
                          : 'Download Semua (Strip, Satuan & GIF)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRose,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Divider "ATAU DOWNLOAD SATUAN"
              Row(
                children: const [
                  Expanded(
                    child: Divider(color: Color(0xFFFFE0E8), thickness: 1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'ATAU DOWNLOAD SATUAN',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Color(0xFFFFE0E8), thickness: 1),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Tombol 2: Download Tanpa Watermark (Pink Solid)
              _buildDownloadButton(
                icon: Icons.file_download_outlined,
                label: 'Download Tanpa Watermark',
                isSolid: true,
                isLoading: _isDownloadingStrip,
                onTap: _isDownloadingStrip ? null : _downloadWithoutWatermark,
              ),
              const SizedBox(height: 7),

              // Tombol 3: Download Gif Tanpa Watermark (Outlined Pink)
              _buildDownloadButton(
                icon: Icons.file_download_outlined,
                label: 'Download Gif Tanpa Watermark',
                isSolid: false,
                isLoading: _isDownloadingGif,
                onTap: _isDownloadingGif ? null : _downloadGif,
              ),
              const SizedBox(height: 7),

              // Tombol 4: Download dengan Watermark (Outlined Pink)
              _buildDownloadButton(
                icon: Icons.file_download_outlined,
                label: 'Download dengan Watermark',
                isSolid: false,
                isLoading: _isDownloadingWatermark,
                onTap: _isDownloadingWatermark ? null : _downloadWithWatermark,
              ),
              const SizedBox(height: 7),

              // Tombol 5: Kirim ke Email (Outlined Pink)
              _buildDownloadButton(
                icon: Icons.email_outlined,
                label: 'Kirim ke Email',
                isSolid: false,
                onTap: _showEmailDialog,
              ),
              const SizedBox(height: 7),

              // Tombol 6: Mint NFT Kenangan (Monad ◈)
              _buildDownloadButton(
                icon: _isNftMinted ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
                label: _isNftMinted ? 'NFT Terbit (${_nftTokenId ?? "Monad"}) ✓' : 'Mint NFT Kenangan (Monad ◈)',
                isSolid: false,
                isLoading: _isMintingNft,
                onTap: _isMintingNft
                    ? null
                    : (_isNftMinted && _nftTokenId != null && _nftTxHash != null
                        ? () => _showNftMintSuccessModal(_nftTokenId!, _nftTxHash!)
                        : _mintNftOnMonad),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppTheme.primaryRose),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton({
    required IconData icon,
    required String label,
    required bool isSolid,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 36,
      child: isSolid
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(icon, size: 15, color: Colors.white),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isLoading ? 'Menyimpan...' : label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: Colors.white,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRose,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTheme.primaryRose),
                      ),
                    )
                  : Icon(icon, size: 15, color: AppTheme.primaryRose),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isLoading ? 'Menyimpan...' : label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: AppTheme.primaryRose,
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFD1DC), width: 1.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white,
              ),
            ),
    );
  }

  // --- STEPPER VERTIKAL ---
  Widget _buildVerticalStepper() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: Preview (Selesai)
          _buildVerticalStepItem(
            stepNumber: 1,
            label: 'Preview',
            isActive: false,
            isCompleted: true,
            isExpanded: _expandedStepIndex == 0,
            onTap: () => _handleStepTap(0),
          ),
          _buildVerticalStepDivider(),
          // Step 2: Edit Foto (Selesai)
          _buildVerticalStepItem(
            stepNumber: 2,
            label: 'Edit Foto',
            isActive: false,
            isCompleted: true,
            isExpanded: _expandedStepIndex == 1,
            onTap: () => _handleStepTap(1),
          ),
          _buildVerticalStepDivider(),
          // Step 3: Download (Aktif)
          _buildVerticalStepItem(
            stepNumber: 3,
            label: 'Download',
            isActive: true,
            isCompleted: false,
            isExpanded: _expandedStepIndex == 2,
            onTap: () => _handleStepTap(2),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalStepItem({
    required int stepNumber,
    required String label,
    required bool isActive,
    required bool isCompleted,
    required bool isExpanded,
    VoidCallback? onTap,
  }) {
    final Widget indicator = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryRose
            : (isCompleted ? const Color(0xFFFFE4EC) : Colors.transparent),
        shape: BoxShape.circle,
        border: Border.all(
          color: (isActive || isCompleted)
              ? AppTheme.primaryRose
              : const Color(0xFFBDBDBD),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          '$stepNumber',
          style: TextStyle(
            color: isActive
                ? Colors.white
                : (isCompleted
                      ? AppTheme.primaryRose
                      : const Color(0xFF757575)),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (isExpanded) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Tooltip(
          message: label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFFF8DA1)
                    : const Color(0xFFE0E0E0),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                indicator,
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? AppTheme.primaryRose
                        : const Color(0xFF424242),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: indicator,
        ),
      ),
    );
  }

  Widget _buildVerticalStepDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 21, top: 3, bottom: 3),
      child: SizedBox(
        height: 18,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            3,
            (_) => Container(
              width: 2,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFCECECE),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _bgAsset(int idx) {
    switch (idx) {
      case 1:
        return 'assets/frame/photostrip2/photostrip_background2.png';
      case 2:
        return 'assets/frame/photostrip3/photostrip_background3.png';
      case 0:
      default:
        return 'assets/frame/photostrip1/photostrip_background1.png';
    }
  }

  String _frameAsset(int idx) {
    switch (idx) {
      case 1:
        return 'assets/frame/photostrip2/photostrip_frame2.png';
      case 2:
        return 'assets/frame/photostrip3/photostrip_frame3.png';
      case 0:
      default:
        return 'assets/frame/photostrip1/photostrip_frame1.png';
    }
  }

  // --- KIRI: PHOTOSTRIP PREVIEW ---
  Widget _buildPhotostripSection() {
    return AspectRatio(
      aspectRatio: 1 / 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final outerRadius = w * (24.0 / 600.0);
          final slotRadius = w * (14.0 / 600.0);

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF141416),
              borderRadius: BorderRadius.circular(outerRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(outerRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Layer 1: Background
                  Image.asset(_bgAsset(widget.initialIndex), fit: BoxFit.fill),

                  // Layer 2: Photo Slots
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double w = constraints.maxWidth;
                      final double h = constraints.maxHeight;
                      final double paddingH = w * (44.0 / 600.0);
                      final double photoW = w - 2.0 * paddingH;
                      final double paddingTop = h * (80.0 / 1800.0);
                      final double photoH = h * (288.0 / 1800.0);
                      final double gap = h * (88.0 / 1800.0);

                      return Stack(
                        children: [
                          for (int i = 0; i < 4; i++)
                            Positioned(
                              left: paddingH,
                              top: paddingTop + i * (photoH + gap),
                              width: photoW,
                              height: photoH,
                              child: Container(
                                width: photoW,
                                height: photoH,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    slotRadius,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    slotRadius,
                                  ),
                                  child: _buildPhotoThumbnail(i),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  // Layer 3: Frame Overlay
                  IgnorePointer(
                    child: Image.asset(
                      _frameAsset(widget.initialIndex),
                      fit: BoxFit.fill,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoThumbnail(int index) {
    if (widget.capturedPhotos.isNotEmpty &&
        index < widget.capturedPhotos.length &&
        File(widget.capturedPhotos[index]).existsSync()) {
      final bool isMirrored =
          widget.mirroredStates != null &&
          widget.mirroredStates!.length > index &&
          widget.mirroredStates![index];

      Widget photoWidget = Image.file(
        File(widget.capturedPhotos[index]),
        fit: BoxFit.cover,
      );

      if (isMirrored) {
        photoWidget = Transform.scale(
          scaleX: -1,
          alignment: Alignment.center,
          child: photoWidget,
        );
      }

      if (widget.filterMatrix != null) {
        photoWidget = ColorFiltered(
          colorFilter: ColorFilter.matrix(widget.filterMatrix!),
          child: photoWidget,
        );
      }

      return photoWidget;
    }
    return Container(
      color: Colors.grey.shade800,
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Painter untuk menggambar QR Code realistis pada box QRIS pembayaran
class _DownloadQrPainter extends CustomPainter {
  const _DownloadQrPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    const int gridSize = 21;
    final double moduleSize = w / gridSize;

    final paintBlack = Paint()
      ..color = const Color(0xFF1E1E22)
      ..style = PaintingStyle.fill;

    const List<String> matrix = [
      '111111101010101111111',
      '100000100110001000001',
      '101110101001101011101',
      '101110100110101011101',
      '101110101010001011101',
      '100000100101101000001',
      '111111101010101111111',
      '000000001101000000000',
      '101101110010110110101',
      '010110011101001001010',
      '110010101011101011001',
      '001101010001010100110',
      '101011101100111010101',
      '000000001011010110010',
      '111111101001001101011',
      '100000100110110010100',
      '101110101001001110110',
      '101110100101100101001',
      '101110101110011011010',
      '100000100011001001101',
      '111111101101010100111',
    ];

    for (int r = 0; r < gridSize; r++) {
      final rowStr = matrix[r];
      for (int c = 0; c < gridSize; c++) {
        if (rowStr[c] == '1') {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * moduleSize + 0.3,
                r * moduleSize + 0.3,
                moduleSize - 0.6,
                moduleSize - 0.6,
              ),
              const Radius.circular(1.0),
            ),
            paintBlack,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
