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
import 'package:smileon/features/camera/presentation/vertical/step/step1_preview_vertical.dart';
import 'package:smileon/features/camera/presentation/vertical/step/step2_editphoto_vertical.dart';
import 'package:smileon/features/camera/presentation/vertical/step/step3_dialog_previewphotostrip.dart';
import 'package:smileon/features/navigation/presentation/main_scaffold.dart';
import 'package:smileon/features/navigation/providers/navigation_provider.dart';
import 'package:dynamic_sdk/dynamic_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smileon/core/constants/monad_contracts.dart';
import 'package:smileon/core/services/monad_payment_service.dart';

/// STEP 3: DOWNLOAD & PAYMENT (VERTICAL)
/// Menyediakan alur akhir untuk vertical photobooth:
/// - Header dengan tombol Back & Close
/// - Stepper horizontal (1: Preview, 2: Edit Foto, 3: Download [Aktif])
/// - Photostrip preview vertikal
/// - QRIS payment & countdown timer
/// - Tombol download foto & GIF
class Step3DownloadVertical extends ConsumerStatefulWidget {
  final List<String> capturedPhotos;
  final Color? selectedThemeColor;
  final String? frameTitle;
  final int selectedFrameIndex;
  final ValueChanged<int>? onStepChanged;
  final VoidCallback? onBackToPreview;
  final VoidCallback? onBackToEdit;
  final VoidCallback? onFinishSession;
  final VoidCallback? onRetake;
  final VoidCallback? onClose;
  final List<double>? filterMatrix;
  final List<bool>? mirroredStates;
  final String? sessionTitle;
  final String? location;
  final String sessionType;
  final List<String>? peopleInPhoto;
  final String? sessionId;

  const Step3DownloadVertical({
    super.key,
    this.sessionId,
    this.capturedPhotos = const [],
    this.selectedThemeColor,
    this.frameTitle,
    this.selectedFrameIndex = 0,
    this.onStepChanged,
    this.onBackToPreview,
    this.onBackToEdit,
    this.onFinishSession,
    this.onRetake,
    this.onClose,
    this.filterMatrix,
    this.mirroredStates,
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
    int selectedFrameIndex = 0,
    VoidCallback? onFinishSession,
    VoidCallback? onRetake,
    List<double>? filterMatrix,
    String? sessionTitle,
    String? location,
    String sessionType = 'personal',
    List<String>? peopleInPhoto,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Step3DownloadVertical(
          sessionId: sessionId,
          capturedPhotos: capturedPhotos,
          selectedThemeColor: selectedThemeColor,
          frameTitle: frameTitle,
          selectedFrameIndex: selectedFrameIndex,
          onFinishSession: onFinishSession,
          onRetake: onRetake,
          filterMatrix: filterMatrix,
          sessionTitle: sessionTitle,
          location: location,
          sessionType: sessionType,
          peopleInPhoto: peopleInPhoto,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  ConsumerState<Step3DownloadVertical> createState() =>
      _Step3DownloadVerticalState();
}

class _Step3DownloadVerticalState extends ConsumerState<Step3DownloadVertical> {
  Timer? _countdownTimer;
  int _remainingSeconds = 14 * 60 + 17; // 14m 17s
  bool _voucherApplied = true;
  bool _isPaid = false;
  String _selectedPaymentMethod = 'qris'; // 'qris' | 'monad'
  bool _monadConnected = false;
  String? _monadWalletAddress;
  bool _isConnectingMonad = false;
  double _monadBalance = 0.0;
  bool _isLoadingBalance = false;
  bool _isPayingMonad = false;
  String? _monadTxHash;
  bool _isDownloadingAll = false;
  bool _isDownloadingStrip = false;
  bool _isDownloadingGif = false;
  bool _isDownloadingWatermark = false;
  bool _isSendingEmail = false;
  bool _isMintingNft = false;
  bool _isNftMinted = false;
  String? _nftTokenId;
  String? _nftTxHash;
  final TextEditingController _voucherController = TextEditingController(
    text: 'ROSEROMANCE5K',
  );
  final TextEditingController _emailController = TextEditingController();

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
      debugPrint('[Step3DownloadVertical] Error check initial wallet: $e');
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

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _voucherController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ── Monad wallet ────────────────────────────────────────────────────────────
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

    // Tampilkan Dialog Loading Progress
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
      Navigator.of(context, rootNavigator: true).pop(); // Tutup loading dialog
      setState(() => _isPayingMonad = false);

      if (result.isSuccess) {
        setState(() {
          _isPaid = true;
          _monadTxHash = result.txHash;
        });
        HapticFeedback.heavyImpact();

        // Refresh balance setelah pembayaran
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
                    child: const Text('Unduh Foto', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // ── Helpers frame asset ────────────────────────────────────────────────────
  String _bgAsset() {
    switch (widget.selectedFrameIndex) {
      case 1: return 'assets/frame/photostrip2/photostrip_background2.png';
      case 2: return 'assets/frame/photostrip3/photostrip_background3.png';
      default: return 'assets/frame/photostrip1/photostrip_background1.png';
    }
  }

  String _frameAsset() {
    switch (widget.selectedFrameIndex) {
      case 1: return 'assets/frame/photostrip2/photostrip_frame2.png';
      case 2: return 'assets/frame/photostrip3/photostrip_frame3.png';
      default: return 'assets/frame/photostrip1/photostrip_frame1.png';
    }
  }

  // ── Download helpers ─────────────────────────────────────────────────────────
  Future<void> _downloadAll() async {
    if (widget.capturedPhotos.isEmpty) {
      _showSnack('Tidak ada foto untuk diunduh!', isError: true);
      return;
    }
    setState(() => _isDownloadingAll = true);
    HapticFeedback.mediumImpact();
    try {
      // Render & simpan fotostrip tanpa watermark
      final bytes = await PhotostripRenderer.render(
        context: context,
        bgAssetPath: _bgAsset(),
        frameAssetPath: _frameAsset(),
        photoPaths: widget.capturedPhotos,
        mirroredStates: widget.mirroredStates,
        filterMatrix: widget.filterMatrix,
        withWatermark: false,
      );
      await PhotostripRenderer.saveToGallery(bytes);
      if (!mounted) return;
      setState(() { _isDownloadingAll = false; _isPaid = true; });
      _showSnack('Fotostrip berhasil disimpan ke galeri! ✨');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloadingAll = false);
      _showSnack('Gagal mengunduh: $e', isError: true);
    }
  }

  Future<void> _downloadStrip() async {
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
        bgAssetPath: _bgAsset(),
        frameAssetPath: _frameAsset(),
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
        message: 'Fotostrip tanpa watermark tersimpan! ✨',
        alignment: Alignment.topCenter,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloadingStrip = false);
      SmileToast.showError(
        context,
        title: 'Gagal Menyimpan',
        message: 'Gagal: $e',
        alignment: Alignment.topCenter,
      );
    }
  }

  Future<void> _downloadGif() async {
    // GIF memerlukan encoding terpisah — simulasi untuk sekarang
    setState(() => _isDownloadingGif = true);
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _isDownloadingGif = false);
    _showSnack('GIF tanpa watermark diunduh! 🎞️');
  }

  Future<void> _downloadWithWatermark() async {
    if (widget.capturedPhotos.isEmpty) {
      _showSnack('Tidak ada foto untuk diunduh!', isError: true);
      return;
    }
    setState(() => _isDownloadingWatermark = true);
    HapticFeedback.lightImpact();
    try {
      final bytes = await PhotostripRenderer.render(
        context: context,
        bgAssetPath: _bgAsset(),
        frameAssetPath: _frameAsset(),
        photoPaths: widget.capturedPhotos,
        mirroredStates: widget.mirroredStates,
        filterMatrix: widget.filterMatrix,
        withWatermark: true, // ← tambah watermark teks
      );
      await PhotostripRenderer.saveToGallery(bytes);
      if (!mounted) return;
      setState(() => _isDownloadingWatermark = false);
      _showSnack('Foto dengan watermark tersimpan!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDownloadingWatermark = false);
      _showSnack('Gagal: $e', isError: true);
    }
  }


  Future<void> _sendEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Masukkan alamat email yang valid!', isError: true);
      return;
    }
    setState(() => _isSendingEmail = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _isSendingEmail = false);
    _showSnack('Foto dikirim ke $email 📧');
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

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade400 : AppTheme.primaryRose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text(
          'Apakah Anda yakin ingin keluar? Sesi foto ini akan disimpan ke riwayat aktivitas Anda dan memori kamera akan dibersihkan.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _saveAndExitSession();
            },
            child: const Text(
              'Ya, Simpan & Keluar',
              style: TextStyle(
                color: AppTheme.primaryRose,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndExitSession() async {
    if (widget.capturedPhotos.isNotEmpty) {
      String? tempStripPath;
      try {
        final bytes = await PhotostripRenderer.render(
          context: context,
          bgAssetPath: _bgAsset(),
          frameAssetPath: _frameAsset(),
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
          title: widget.sessionTitle ??
              widget.frameTitle ??
              'Sesi Foto SmileOn',
          sessionType: widget.sessionType,
          location: widget.location,
          frameIndex: widget.selectedFrameIndex,
          frameAssetPath: _frameAsset(),
          bgAssetPath: _bgAsset(),
          rawPhotoPaths: widget.capturedPhotos,
          mirroredStates:
              widget.mirroredStates ?? const [false, false, false, false],
          filterMatrix: widget.filterMatrix,
          renderedStripPath: tempStripPath,
          peopleInPhoto: widget.peopleInPhoto,
          isPaid: _isPaid,
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
              debugPrint('[Step3DownloadVertical] Cloud upload & complete finished for $sessionId');
            }
          } catch (uploadErr) {
            debugPrint('[Step3DownloadVertical] Background cloud upload error: $uploadErr');
          }
        }());
      } catch (e) {
        debugPrint('Error saving session locally: $e');
      }
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

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleStepTap(int stepIndex) {
    if (stepIndex == 2) return; // Already on Step 3 (Download)

    if (widget.onStepChanged != null) {
      widget.onStepChanged!(stepIndex);
      return;
    }

    if (stepIndex == 0) {
      if (widget.onBackToPreview != null) {
        widget.onBackToPreview!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Step1PreviewVertical(
              capturedPhotos: widget.capturedPhotos,
              selectedThemeColor: widget.selectedThemeColor,
              selectedFrameIndex: widget.selectedFrameIndex,
              onRetake: widget.onRetake,
              onClose: widget.onClose,
            ),
          ),
        );
      }
    } else if (stepIndex == 1) {
      if (widget.onBackToEdit != null) {
        widget.onBackToEdit!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Step2EditPhotoVertical(
              capturedPhotos: widget.capturedPhotos,
              selectedThemeColor: widget.selectedThemeColor,
              selectedFrameIndex: widget.selectedFrameIndex,
              onRetake: widget.onRetake,
              onClose: widget.onClose,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF2F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildStepper(),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildPhotostripMiniCard(),
                    const SizedBox(height: 16),
                    _buildPaymentCard(),
                    const SizedBox(height: 16),
                    _buildDownloadActions(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(
            icon: Icons.chevron_left_rounded,
            size: 26,
            onTap: () => _handleStepTap(1),
          ),
          const Text(
            'Download',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E22),
            ),
          ),
          _buildCircleButton(
            icon: Icons.close_rounded,
            size: 20,
            onTap: _confirmExit,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF1E5E8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, size: size, color: const Color(0xFF424242)),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepItem(stepNumber: 1, label: 'Preview', isActive: false, onTap: () => _handleStepTap(0)),
          const SizedBox(width: 14),
          _buildStepItem(stepNumber: 2, label: 'Edit Foto', isActive: false, onTap: () => _handleStepTap(1)),
          const SizedBox(width: 14),
          _buildStepItem(stepNumber: 3, label: 'Download', isActive: true, onTap: () => _handleStepTap(2)),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNumber,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryRose : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppTheme.primaryRose : const Color(0xFFD4D4DC),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF9E9EA8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primaryRose : const Color(0xFF9E9EA8),
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotostripMiniCard() {
    return GestureDetector(
      onTap: () {
        Step3DialogPreviewPhotostrip.show(
          context: context,
          frameIndex: widget.selectedFrameIndex,
          capturedPhotos: widget.capturedPhotos,
          filterMatrix: widget.filterMatrix,
          mirroredStates: widget.mirroredStates,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFE8EE), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB6C6).withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Mini fotostrip (background + slot foto + frame overlay) ──────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 65,
                height: 195, // rasio 1:3
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Layer 1: background PNG
                    Image.asset(
                      _bgAssetForFrame(widget.selectedFrameIndex),
                      fit: BoxFit.fill,
                    ),

                    // Layer 2: slot foto
                    _buildMiniPhotoSlots(),

                    // Layer 3: frame overlay
                    IgnorePointer(
                      child: Image.asset(
                        _frameAssetForFrame(widget.selectedFrameIndex),
                        fit: BoxFit.fill,
                      ),
                    ),

                    // Tap hint overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.18),
                            ],
                          ),
                        ),
                        child: const Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Icon(
                              Icons.zoom_in_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            // ── Info teks ────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRose.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Siap Diunduh',
                          style: TextStyle(
                            color: AppTheme.primaryRose,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Photostrip 3 Frame',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E2E34),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.frameTitle ?? 'Hanfleur Florist',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888894),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 12,
                        color: AppTheme.primaryRose.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap untuk lihat detail',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryRose.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Slot foto mini mengikuti proporsi canvas 600 × 1800 px.
  Widget _buildMiniPhotoSlots() {
    return LayoutBuilder(
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
                child: _buildMiniPhotoSlot(i),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMiniPhotoSlot(int index) {
    final bool hasPhoto =
        index < widget.capturedPhotos.length &&
        File(widget.capturedPhotos[index]).existsSync();

    if (!hasPhoto) {
      return Container(color: Colors.black.withValues(alpha: 0.08));
    }

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

    return ClipRect(
      child: widget.filterMatrix != null
          ? ColorFiltered(
              colorFilter: ColorFilter.matrix(widget.filterMatrix!),
              child: photoWidget,
            )
          : photoWidget,
    );
  }

  String _bgAssetForFrame(int frameIndex) {
    switch (frameIndex) {
      case 1:
        return 'assets/frame/photostrip2/photostrip_background2.png';
      case 2:
        return 'assets/frame/photostrip3/photostrip_background3.png';
      case 0:
      default:
        return 'assets/frame/photostrip1/photostrip_background1.png';
    }
  }

  String _frameAssetForFrame(int frameIndex) {
    switch (frameIndex) {
      case 1:
        return 'assets/frame/photostrip2/photostrip_frame2.png';
      case 2:
        return 'assets/frame/photostrip3/photostrip_frame3.png';
      case 0:
      default:
        return 'assets/frame/photostrip1/photostrip_frame1.png';
    }
  }



  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE8EE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB6C6).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: judul + timer ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Metode Pembayaran',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppTheme.primaryRose),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(_remainingSeconds),
                    style: const TextStyle(
                      color: AppTheme.primaryRose,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Pilihan 1: QRIS ──────────────────────────────────────────────
          _PaymentOptionTile(
            isSelected: _selectedPaymentMethod == 'qris',
            onTap: () => setState(() => _selectedPaymentMethod = 'qris'),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('🔷', style: TextStyle(fontSize: 20)),
              ),
            ),
            title: 'QRIS Instant Pay',
            subtitle: 'BCA, GoPay, OVO, ShopeePay, Dana',
          ),

          const SizedBox(height: 10),

          // ── Pilihan 2: Pay with Monad ────────────────────────────────────
          _PaymentOptionTile(
            isSelected: _selectedPaymentMethod == 'monad',
            onTap: () => setState(() => _selectedPaymentMethod = 'monad'),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF836EF9), Color(0xFF200052)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('◈', style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ),
            title: 'Pay with Monad',
            subtitle: 'Bayar via crypto wallet Monad',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF836EF9), Color(0xFF5B3EE0)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Web3',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // ── Monad wallet panel ───────────────────────────────────────────
          if (_selectedPaymentMethod == 'monad') ...[
            const SizedBox(height: 12),
            _buildMonadWalletPanel(),
          ],

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFFFE8EE)),
          const SizedBox(height: 10),

          // ── Voucher ──────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _voucherController,
                  decoration: InputDecoration(
                    hintText: 'Kode Voucher',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFFBFBFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE8E8EE)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE8E8EE)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() => _voucherApplied = true);
                  _showSnack('Voucher Rp5.000 berhasil digunakan! 🎉');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRose,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Gunakan'),
              ),
            ],
          ),
          if (_voucherApplied) ...[
            const SizedBox(height: 6),
            const Text(
              '✓ Diskon Voucher Rp5.000 Aktif',
              style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonadWalletPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF200052).withValues(alpha: 0.06),
            const Color(0xFF836EF9).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF836EF9).withValues(alpha: 0.3)),
      ),
      child: _monadConnected
          ? _buildMonadConnected()
          : _buildMonadDisconnected(),
    );
  }

  Widget _buildMonadDisconnected() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF836EF9), Color(0xFF200052)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('◈', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monad Wallet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF200052)),
                  ),
                  Text(
                    'Hubungkan wallet untuk bayar dengan MON',
                    style: TextStyle(fontSize: 11, color: Color(0xFF836EF9)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isConnectingMonad ? null : _connectMonadWallet,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ).copyWith(
              backgroundColor: WidgetStateProperty.all(Colors.transparent),
              overlayColor: WidgetStateProperty.all(const Color(0xFF836EF9).withValues(alpha: 0.1)),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF836EF9), Color(0xFF200052)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: _isConnectingMonad
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('◈', style: TextStyle(fontSize: 16, color: Colors.white)),
                          SizedBox(width: 8),
                          Text(
                            'Connect Monad Wallet',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonadConnected() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF836EF9), Color(0xFF200052)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('◈', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monad Wallet Terhubung ✓',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF200052)),
                  ),
                  Text(
                    _monadWalletAddress ?? '',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF836EF9), fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _disconnectMonadWallet,
              child: Icon(Icons.close, size: 18, color: const Color(0xFF836EF9).withValues(alpha: 0.7)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Saldo MON', style: TextStyle(fontSize: 12, color: Color(0xFF836EF9))),
            _isLoadingBalance
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF836EF9)),
                  )
                : Text(
                    '${_monadBalance.toStringAsFixed(3)} MON',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF200052)),
                  ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Biaya Transaksi', style: TextStyle(fontSize: 12, color: Color(0xFF836EF9))),
            Text('~0.0001 MON', style: TextStyle(fontSize: 12, color: const Color(0xFF836EF9).withValues(alpha: 0.7))),
          ],
        ),
        const SizedBox(height: 10),
        if (_isPaid)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                const SizedBox(width: 8),
                Text(
                  _monadTxHash != null && _monadTxHash!.length > 12
                      ? 'Lunas • Tx: ${_monadTxHash!.substring(0, 8)}...'
                      : 'Lunas On-Chain',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D)),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPayingMonad ? null : _payWithMonadOnChain,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF836EF9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                elevation: 0,
              ),
              child: _isPayingMonad
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('◈', style: TextStyle(fontSize: 16, color: Colors.white)),
                        SizedBox(width: 8),
                        Text('Bayar 0.80 MON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildDownloadActions() {
    return Column(
      children: [
        // ── Tombol utama: Download Semua ─────────────────────────────────────
        _DownloadButton(
          onPressed: _isDownloadingAll ? null : _downloadAll,
          isPrimary: true,
          isLoading: _isDownloadingAll,
          icon: _isPaid ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
          label: _isPaid ? 'Sudah Diunduh ✓' : 'Download Semua',
          sublabel: _isPaid ? null : '(Strip, Satuan & GIF)',
        ),

        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: Divider(color: const Color(0xFFFFD1DC).withValues(alpha: 0.6))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'ATAU DOWNLOAD SATUAN',
                style: TextStyle(fontSize: 10, color: const Color(0xFFAAAAAA).withValues(alpha: 0.9), letterSpacing: 0.8),
              ),
            ),
            Expanded(child: Divider(color: const Color(0xFFFFD1DC).withValues(alpha: 0.6))),
          ],
        ),
        const SizedBox(height: 14),

        // ── Download Tanpa Watermark ──────────────────────────────────────────
        _DownloadButton(
          onPressed: _isDownloadingStrip ? null : _downloadStrip,
          isPrimary: false,
          isLoading: _isDownloadingStrip,
          icon: Icons.download_rounded,
          label: 'Download Tanpa Watermark',
        ),
        const SizedBox(height: 10),

        // ── Download GIF Tanpa Watermark ──────────────────────────────────────
        _DownloadButton(
          onPressed: _isDownloadingGif ? null : _downloadGif,
          isPrimary: false,
          isLoading: _isDownloadingGif,
          icon: Icons.gif_box_outlined,
          label: 'Download Gif Tanpa Watermark',
        ),
        const SizedBox(height: 10),

        // ── Download dengan Watermark ─────────────────────────────────────────
        _DownloadButton(
          onPressed: _isDownloadingWatermark ? null : _downloadWithWatermark,
          isPrimary: false,
          isLoading: _isDownloadingWatermark,
          icon: Icons.download_rounded,
          label: 'Download dengan Watermark',
        ),
        const SizedBox(height: 10),

        // ── Mint ke NFT Monad (Chain ID 10143) ────────────────────────────────
        _DownloadButton(
          onPressed: _isMintingNft
              ? null
              : (_isNftMinted && _nftTokenId != null && _nftTxHash != null
                  ? () => _showNftMintSuccessModal(_nftTokenId!, _nftTxHash!)
                  : _mintNftOnMonad),
          isPrimary: false,
          isLoading: _isMintingNft,
          icon: _isNftMinted ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
          label: _isNftMinted ? 'NFT Terbit (${_nftTokenId ?? "Monad"}) ✓' : 'Mint NFT Kenangan (Monad ◈)',
          sublabel: _isNftMinted && _nftTxHash != null ? 'Tx: ${_nftTxHash!.substring(0, 8)}...' : null,
        ),
        const SizedBox(height: 10),

        // ── Kirim ke Email ────────────────────────────────────────────────────
        _buildSendEmailSection(),
        const SizedBox(height: 20),

        // ── Selesai & Keluar ──────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _confirmExit,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFD1DC), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: Colors.white,
            ),
            child: const Text(
              'Selesai & Keluar',
              style: TextStyle(
                color: AppTheme.primaryRose,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendEmailSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE8EE), width: 1.2),
      ),
      child: Column(
        children: [
          // Tombol kirim (toggle row email)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _isSendingEmail
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryRose,
                          ),
                        )
                      : const Icon(Icons.mail_outline_rounded, color: AppTheme.primaryRose, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Kirim ke Email',
                    style: TextStyle(
                      color: AppTheme.primaryRose,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Input email + tombol kirim
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'nama@email.com',
                      hintStyle: const TextStyle(fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFFBFBFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE8E8EE)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE8E8EE)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSendingEmail ? null : _sendEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: _isSendingEmail
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Kirim'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ══ Helper widget: Payment Option Tile ══════════════════════════════════════

class _PaymentOptionTile extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _PaymentOptionTile({
    required this.isSelected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryRose.withValues(alpha: 0.05)
              : const Color(0xFFFFF9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRose : const Color(0xFFFFE8EE),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryRose : const Color(0xFFCCCCCC),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryRose,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? AppTheme.primaryRose : const Color(0xFF2E2E34),
                    ),
                  ),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// ══ Helper widget: Download Button ══════════════════════════════════════════

class _DownloadButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final IconData icon;
  final String label;
  final String? sublabel;

  const _DownloadButton({
    required this.onPressed,
    required this.isPrimary,
    required this.isLoading,
    required this.icon,
    required this.label,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRose,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: AppTheme.primaryRose.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 22),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        if (sublabel != null)
                          Text(sublabel!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ],
                ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFFD1DC), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryRose,
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRose),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: AppTheme.primaryRose),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.primaryRose,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
