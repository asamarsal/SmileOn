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
      isEn ? 'Capture your\nSpecial\nMoment' : 'Abadikan\nMomen\nSpesialmu';
  String get homeHeroSubtitle => isEn
      ? 'Photobox for Your\nBeautiful Story'
      : 'Photobox untuk\nCerita Indahmu';
  String get startPhoto => isEn ? 'Start Photo' : 'Mulai Foto';
  String get personalMode => isEn ? 'Personal\nMode' : 'Mode\nPersonal';
  String get personalModeDesc =>
      isEn ? 'Photo & pay\nat the end' : 'Foto & bayar\ndi akhir';
  String get eventMode => isEn ? 'Event\nMode' : 'Mode\nEvent';
  String get eventModeDesc =>
      isEn ? 'Use event\nvoucher' : 'Gunakan voucher\nevent';
  String get popularFrames => isEn ? 'Popular Frames' : 'Frame Populer';
  String get seeAll => isEn ? 'See All' : 'Lihat Semua';
  String get specialPromo => isEn ? 'Special Promo' : 'Promo Spesial';
  String get getVoucher => isEn ? 'Get voucher' : 'Dapatkan voucher';
  String get discountForEvent =>
      isEn ? 'discount for your event!' : 'diskon untuk event kamu!';

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
  String get settingsTitle => isEn ? 'Settings' : 'Pengaturan';
  String get settingsSubtitle => isEn
      ? 'Manage your SmileOn account, storage, and preferences.'
      : 'Kelola akun, penyimpanan, dan preferensi SmileOn kamu.';
  String get changeLanguage => isEn ? 'Change Language' : 'Ganti Bahasa';
  String get languageDesc => isEn ? 'Current: English' : 'Saat ini: Indonesia';

  // Settings Menu Items
  String get menuAccount => isEn ? 'Account' : 'Akun';
  String get menuStorage => isEn ? 'Storage' : 'Penyimpanan';
  String get menuEventVoucher => isEn ? 'Event & Voucher' : 'Event & Voucher';
  String get menuPayment => isEn ? 'Payment' : 'Pembayaran';
  String get menuSecurity => isEn ? 'Security' : 'Keamanan';
  String get menuPrivacy => isEn ? 'Privacy' : 'Privasi';
  String get menuSecurityPrivacy =>
      isEn ? 'Security & Privacy' : 'Keamanan & Privasi';
  String get securityPrivacySubtitle => isEn
      ? 'Small steps for big protection'
      : 'Langkah kecil untuk perlindungan besar';
  String get accountSafeTitle =>
      isEn ? 'Your account is secure! 🎉' : 'Akun kamu aman! 🎉';
  String get accountSafeSubtitle =>
      isEn ? 'No security issues found' : 'Tidak ada masalah keamanan';
  String get settingsSection => isEn ? 'Settings' : 'Pengaturan';
  String get accountLoginTitle => isEn ? 'Account & Login' : 'Akun & Login';
  String get accountLoginSubtitle =>
      isEn ? 'Passkey, password, devices' : 'Passkey, kata sandi, perangkat';
  String get photoPrivacyTitle =>
      isEn ? 'Photo & Album Privacy' : 'Privasi Foto & Album';
  String get photoPrivacySubtitle =>
      isEn ? 'Who can see your photos' : 'Siapa yang bisa melihat fotomu';
  String get dataStorageTitle => isEn ? 'Data & Storage' : 'Data & Penyimpanan';
  String get dataStorageSubtitle =>
      isEn ? 'Manage data and downloads' : 'Kelola data dan unduhan';
  String get permissionsAccessTitle =>
      isEn ? 'Permissions & Access' : 'Izin & Akses';
  String get permissionsAccessSubtitle =>
      isEn ? 'Manage app permissions' : 'Kelola izin aplikasi';
  String get activitySecurityTitle =>
      isEn ? 'Activity & Security' : 'Aktivitas & Keamanan';
  String get activitySecuritySubtitle =>
      isEn ? 'Login history, alerts' : 'Riwayat login, notifikasi';
  String get menuLanguage => isEn ? 'Language' : 'Bahasa';
  String get menuHelpOthers => isEn ? 'Help & Others' : 'Bantuan & Lainnya';

  // Settings Sub-sheets
  String get storageSettingsTitle =>
      isEn ? 'Storage Settings' : 'Pengaturan Penyimpanan';
  String get storageSettingsDesc => isEn
      ? 'Configure where and how your photobox results are saved.'
      : 'Atur lokasi dan cara penyimpanan hasil foto photobox kamu.';

  String get paymentSettingsTitle =>
      isEn ? 'Payment & Network' : 'Pembayaran & Jaringan';
  String get paymentSettingsDesc => isEn
      ? 'SmileOn is powered by Monad Testnet for fast and affordable onchain transactions.'
      : 'SmileOn didukung jaringan Monad Testnet untuk transaksi onchain yang cepat dan terjangkau.';

  String get securitySettingsTitle =>
      isEn ? 'Account Security' : 'Keamanan Akun';
  String get securitySettingsDesc => isEn
      ? 'Authentication is securely managed by Dynamic.xyz embedded MPC wallet.'
      : 'Otentikasi dikelola dengan aman oleh Dynamic.xyz embedded MPC wallet.';

  String get privacySettingsTitle => isEn ? 'Privacy & Data' : 'Privasi & Data';
  String get privacySettingsDesc => isEn
      ? 'Your photos are strictly yours. We do not sell or share your personal pictures.'
      : 'Foto kamu adalah milikmu sepenuhnya. Kami tidak membagikan atau menjual data fotomu.';

  String get languageSettingsTitle => isEn ? 'Choose Language' : 'Pilih Bahasa';
  String get languageSettingsDesc => isEn
      ? 'Select your preferred display language'
      : 'Pilih bahasa tampilan yang kamu inginkan';

  String get helpSettingsTitle =>
      isEn ? 'Help & Information' : 'Bantuan & Informasi';
  String get helpSettingsDesc => isEn
      ? 'Need help or have questions about SmileOn?'
      : 'Butuh bantuan atau punya pertanyaan tentang SmileOn?';

  String get close => isEn ? 'Close' : 'Tutup';
  String get manageDynamicProfile => isEn
      ? 'Manage Account in Dynamic Profile'
      : 'Kelola Akun di Dynamic Profile';
  String get connected => isEn ? 'Connected' : 'Terhubung';
  String get monadNetworkTitle => isEn ? 'Monad Network' : 'Jaringan Monad';
  String get walletAddressTitle =>
      isEn ? 'Wallet Address (Monad EVM):' : 'Alamat Dompet (Monad EVM):';
  String get copiedToast => isEn ? 'Copied! ✨' : 'Tersalin! ✨';
  String get copiedWalletMsg => isEn
      ? 'Monad wallet address copied to clipboard.'
      : 'Alamat dompet Monad berhasil disalin ke clipboard.';

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

  // Buy Voucher & Promo Screen
  String get voucherPromoTitle => isEn ? 'Voucher & Promo' : 'Voucher & Promo';
  String get categoryTitle => isEn ? 'Category' : 'Kategori';
  String get choosePhotoCount =>
      isEn ? 'Choose Photo Amount' : 'Pilih Kredit Foto';
  String get creditNoExpiry =>
      isEn ? 'Credits never expire' : 'Kredit tidak kadaluarsa';
  String get creditUsableAllEvents =>
      isEn ? 'Can be used for all events' : 'Bisa digunakan untuk semua event';
  String get choosePhotoCreditPackage =>
      isEn ? 'Choose Photo Credit Package' : 'Pilih Paket Kredit Foto';
  String get continueBtn => isEn ? 'Continue' : 'Lanjutkan';
  String get recommendedForYou =>
      isEn ? 'Recommended For You' : 'Rekomendasi Untukmu';
  String get tabAll => isEn ? 'All' : 'Semua';
  String get mostPopularBadge => isEn ? 'Most Popular' : 'Paling Populer';
  String get photoCreditsCategory => isEn ? 'Photo Credit' : 'Kredit Foto';
  String get eventCategory => isEn ? 'Event' : 'Event';
  String get specialCategory => isEn ? 'Special' : 'Spesial';
  String get memberCategory => isEn ? 'Member' : 'Member';
  String get buyVoucherTitle => isEn ? 'Voucher & Promo' : 'Voucher & Promo';
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

  String get saveToDrive =>
      isEn ? 'Save to Google Drive' : 'Simpan ke Google Drive';
  String get sendToEmail => isEn ? 'Send to Email' : 'Kirim ke Email';
  String get photoQuality => isEn ? 'Photo Quality' : 'Kualitas Foto';
  String get photoQualityHigh => isEn ? 'High' : 'Tinggi';

  String get useMonadCoin => isEn ? 'Use Monad Coin' : 'Gunakan Coin Monad';
  String get redeemVoucherSetting => isEn ? 'Buy Voucher' : 'Beli Voucher';
  String get aboutApp => isEn ? 'About App' : 'Tentang Aplikasi';
  String get accountName => isEn ? 'Name' : 'Nama';
  String get accountEmail => isEn ? 'Email' : 'Email';
  String get walletMonad => isEn ? 'Wallet Monad' : 'Wallet Monad';
  String get linkedAccounts => isEn ? 'Linked Accounts' : 'Linked Accounts';
  String get profilePhoto => isEn ? 'Profile Photo' : 'Foto Profil';

  String get logout => isEn ? 'Logout' : 'Keluar';
  String get logoutConfirmDesc => isEn
      ? 'Are you sure you want to logout?'
      : 'Apa Anda yakin ingin keluar?';
  String get yes => isEn ? 'Yes' : 'Ya';
  String get cancel => isEn ? 'Cancel' : 'Batal';
}
