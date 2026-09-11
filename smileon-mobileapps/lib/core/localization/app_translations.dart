import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

enum AppLanguage { id, en }

final languageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.id);

final tProvider = Provider<AppTranslations>((ref) {
  final lang = ref.watch(languageProvider);
  return AppTranslations(lang);
});

class AppTranslations {
  final AppLanguage language;

  AppTranslations(this.language);

  bool get isEn => language == AppLanguage.en;

  // Bottom Navigation
  String get navHome => isEn ? 'Home' : 'Beranda';
  String get navCamera => isEn ? 'Camera' : 'Kamera';
  String get navSettings => isEn ? 'Settings' : 'Pengaturan';

  // Home Screen
  String get homeHeroTitle =>
      isEn ? 'Capture\nthe Special\nMoment' : 'Abadikan\nMomen\nSpesial';
  String get homeHeroSubtitle => isEn
      ? 'Photobox for Your\nBeautiful Story'
      : 'Photobox untuk Cerita\nIndahmu';
  String get startPhoto => isEn ? 'Start Photo' : 'Mulai Foto';
  String get personalMode => isEn ? 'Personal\nMode' : 'Mode\nPersonal';
  String get personalModeDesc =>
      isEn ? 'Photo & pay\nat the end' : 'Foto & bayar\ndi akhir';
  String get eventMode => isEn ? 'Event\nMode' : 'Mode\nEvent';
  String get eventModeDesc =>
      isEn ? 'Use event\nvoucher' : 'Gunakan voucher\nevent';
  String get popularFrames => isEn ? 'Popular Frames' : 'Frame Populer';
  String get seeAll => isEn ? 'See All' : 'Lihat Semua';

  // Camera Screen - Tabs
  String get tabEvent => isEn ? 'Event Mode' : 'Mode Event';
  String get tabPersonal => isEn ? 'Personal Mode' : 'Mode Personal';

  // Camera Screen - Event
  String get eventAccessTitle => isEn ? 'Event Access' : 'Akses Event';
  String get eventAccessDesc => isEn
      ? 'Enter voucher code or scan QR\nfrom your event.'
      : 'Masukkan kode voucher atau scan QR\ndari event Anda.';
  String get scanQr => isEn ? 'Scan QR' : 'Scan QR';
  String get voucherCode => isEn ? 'Voucher Code' : 'Kode Voucher';
  String get pointCamera =>
      isEn ? 'Point camera to QR Code' : 'Arahkan kamera ke QR Code';
  String get or => isEn ? 'or' : 'atau';
  String get inputVoucherHint =>
      isEn ? 'Enter voucher code' : 'Masukkan kode voucher';
  String get checkVoucher => isEn ? 'Check Voucher' : 'Cek Voucher';

  // Camera Screen - Personal
  String get personalAccessTitle => isEn ? 'Personal Mode' : 'Mode Personal';
  String get personalAccessDesc => isEn
      ? 'Take photos as you like,\npay only for what you want.'
      : 'Ambil foto sesuka Anda,\nbayar hanya untuk hasil yang Anda inginkan.';
  String get startCamera => isEn ? 'Start Camera' : 'Mulai Kamera';

  // Settings Screen
  String get settingsTitle => isEn ? 'Settings & Admin' : 'Pengaturan & Admin';
  String get changeLanguage => isEn ? 'Change Language' : 'Ganti Bahasa';
  String get languageDesc => isEn ? 'Current: English' : 'Saat ini: Indonesia';

  String get buyVoucher => isEn ? 'Buy Event Voucher' : 'Beli Voucher Event';
  String get buyVoucherDesc => isEn
      ? 'Buy voucher packages for your event'
      : 'Beli paket voucher untuk event Anda';
  String get printerConfig =>
      isEn ? 'Printer Configuration' : 'Konfigurasi Printer';
  String get printerConfigDesc => isEn
      ? 'Setup connection to thermal/photo printer'
      : 'Atur koneksi ke printer thermal/photo';
  String get monadWallet =>
      isEn ? 'Monad Wallet / Contract' : 'Dompet / Kontrak Monad';
  String get monadWalletDesc => isEn
      ? 'Configure smart contract & RPC'
      : 'Konfigurasi smart contract & RPC';
  String get adminDashboard => isEn ? 'Admin Dashboard' : 'Dasbor Admin';
  String get adminDashboardDesc => isEn
      ? 'Manage frames, sessions, and galleries'
      : 'Kelola frame, sesi, dan galeri';

  // Buy Voucher Screen
  String get buyVoucherTitle =>
      isEn ? 'Buy Event Voucher' : 'Beli Voucher Event';
  String get eventPackage => isEn ? 'Event Package' : 'Paket Event';
  String get bestValue => isEn ? 'Best Value' : 'Paling Untung';
  String get photoCredits => isEn ? '300 Photo Credits' : '300 Kredit Foto';
  String get unlimitedDownloads => isEn
      ? 'Unlimited digital downloads + GIF'
      : 'Unduhan digital tak terbatas + GIF';
  String get totalPayment => isEn ? 'Total Payment:' : 'Total Pembayaran:';
  String get choosePayment =>
      isEn ? 'Choose Payment Method' : 'Pilih Metode Pembayaran';
  String get monadContract => isEn ? 'Smart Contract' : 'Smart Contract';
  String get qrEwallet => isEn ? 'E-Wallet / Bank' : 'E-Wallet / Bank';

  String get monadInstruction => isEn
      ? 'Send 1.00 MON to Smart Contract'
      : 'Kirim 1.00 MON ke Smart Contract';
  String get monadInstructionDesc => isEn
      ? '0x1234...abcd\nMake sure you are on the Monad network.'
      : '0x1234...abcd\nPastikan Anda berada di jaringan Monad.';
  String get qrInstruction =>
      isEn ? 'Scan QR Code to Pay' : 'Scan QR Code untuk Membayar';
  String get qrInstructionDesc => isEn
      ? 'Supports all e-wallets and mobile banking in Indonesia.'
      : 'Mendukung seluruh e-wallet dan m-banking di Indonesia.';

  String get paymentDeadline => isEn
      ? 'Payment deadline:\n24 Hours from now.'
      : 'Tenggat waktu pembayaran:\n24 Jam dari sekarang.';
  String get verifyMonad =>
      isEn ? 'Verify Monad Payment' : 'Verifikasi Pembayaran Monad';
  String get showQr => isEn ? 'Show Payment QR' : 'Tampilkan QR Pembayaran';

  // Settings New UI
  String get sectionAccount => isEn ? 'Account' : 'Akun';
  String get sectionStorage => isEn ? 'Storage' : 'Penyimpanan';
  String get sectionOthers => isEn ? 'Others' : 'Lainnya';
  
  String get saveToDrive => isEn ? 'Save to Google Drive' : 'Simpan ke Google Drive';
  String get sendToEmail => isEn ? 'Send to Email' : 'Kirim ke Email';
  String get photoQuality => isEn ? 'Photo Quality' : 'Kualitas Foto';
  String get photoQualityHigh => isEn ? 'High' : 'Tinggi';
  
  String get useMonadCoin => isEn ? 'Use Monad Coin' : 'Gunakan Coin Monad';
  String get redeemVoucherSetting => isEn ? 'Redeem Voucher' : 'Redeem Voucher';
  String get aboutApp => isEn ? 'About App' : 'Tentang Aplikasi';
  String get logout => isEn ? 'Logout' : 'Keluar';
  String get logoutConfirmDesc => isEn ? 'Are you sure you want to logout?' : 'Apa Anda yakin ingin keluar?';
  String get yes => isEn ? 'Yes' : 'Ya';
  String get cancel => isEn ? 'Cancel' : 'Batal';
}
