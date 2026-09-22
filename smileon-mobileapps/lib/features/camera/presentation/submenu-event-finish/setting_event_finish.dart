import 'package:flutter/material.dart';
import 'package:smileon/core/components/smile_toast.dart';

/// Tab Pengaturan (Konfigurasi Event) pada Event Siap / Finish
/// Menampilkan:
/// - Grid Setup Kamera & Printer dan Edit Info Event
/// - Toggles: Kunci Frame Resmi, Simpan Google Drive, Cetak Otomatis, Watermark
/// - Dropdown konfigurasi: Foto per Sesi Photostrip dan Countdown Timer
/// - Tombol Simpan Pengaturan Event
class SettingEventFinish extends StatefulWidget {
  final VoidCallback? onEditInfoEvent;

  const SettingEventFinish({
    super.key,
    this.onEditInfoEvent,
  });

  @override
  State<SettingEventFinish> createState() => _SettingEventFinishState();
}

class _SettingEventFinishState extends State<SettingEventFinish> {
  bool _lockFrameToEvent = true;
  bool _autoUploadDrive = true;
  bool _autoPrintPhotos = true;
  bool _showWatermark = false;
  int _photosPerStrip = 4;
  int _countdownTimerSeconds = 5;

  void _showSetupCameraPrinterDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.settings_suggest_rounded,
                    color: Color(0xFF233876),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup Kamera & Printer',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2448),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Konfigurasi perangkat photobox di venue',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),
            // Item Kamera
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EEF5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF233876),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kamera Utama',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2448),
                          ),
                        ),
                        Text(
                          'Kamera Depan HD (Aktif)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      SmileToast.showSuccess(
                        context,
                        title: 'Kamera Siap',
                        message: 'Kalibrasi kamera berhasil',
                      );
                    },
                    child: const Text('Uji Coba'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Item Printer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EEF5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.print_outlined,
                    color: Color(0xFF233876),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Printer Photostrip',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2448),
                          ),
                        ),
                        Text(
                          'DNP DS-RX1 / Bluetooth (Tersambung)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      SmileToast.showSuccess(
                        context,
                        title: 'Test Print',
                        message: 'Perintah cetak uji coba terkirim',
                      );
                    },
                    child: const Text('Test Print'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF233876),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Tutup Pengaturan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F4F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF233876), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2448),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: const Color(0xFFFF2E7E),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid (Setup Kamera / Printer & Edit Info Event)
        Row(
          children: [
            // Card Kiri: Setup Kamera / Printer
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showSetupCameraPrinterDialog(context),
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFF0F1F5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E293B)
                              .withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.settings_suggest_rounded,
                            color: Color(0xFF233876),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Setup Kamera\n/ Printer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2448),
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Card Kanan: Edit Info Event
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onEditInfoEvent,
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFF0F1F5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E293B)
                              .withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.photo_library_outlined,
                            color: Color(0xFF233876),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Edit Info\nEvent',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E2448),
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _buildSettingToggle(
          title: 'Kunci Frame Resmi Acara',
          subtitle: 'Tamu hanya dapat berfoto menggunakan frame resmi ini',
          value: _lockFrameToEvent,
          onChanged: (val) => setState(() => _lockFrameToEvent = val),
          icon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 12),
        _buildSettingToggle(
          title: 'Simpan ke Google Drive',
          subtitle: 'Semua hasil foto otomatis ter-upload ke Google Drive',
          value: _autoUploadDrive,
          onChanged: (val) => setState(() => _autoUploadDrive = val),
          icon: Icons.cloud_upload_outlined,
        ),
        const SizedBox(height: 12),
        _buildSettingToggle(
          title: 'Cetak Otomatis (Auto-Print)',
          subtitle: 'Langsung kirim ke printer setelah sesi selesai',
          value: _autoPrintPhotos,
          onChanged: (val) => setState(() => _autoPrintPhotos = val),
          icon: Icons.print_outlined,
        ),
        const SizedBox(height: 12),
        _buildSettingToggle(
          title: 'Tampilkan Watermark SmileOn',
          subtitle: 'Tambahkan logo SmileOn kecil di pojok photostrip',
          value: _showWatermark,
          onChanged: (val) => setState(() => _showWatermark = val),
          icon: Icons.branding_watermark_outlined,
        ),
        const SizedBox(height: 18),
        // Jumlah Foto & Timer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F4F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Foto per Sesi Photostrip',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2448),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Berapa jepretan foto dalam 1 photostrip',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _photosPerStrip,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 3, child: Text('3 Foto')),
                      DropdownMenuItem(value: 4, child: Text('4 Foto')),
                      DropdownMenuItem(value: 6, child: Text('6 Foto')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _photosPerStrip = val);
                    },
                  ),
                ],
              ),
              const Divider(color: Color(0xFFF1F3F7), height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timer Countdown Jepretan',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2448),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Waktu pose sebelum kamera mengambil gambar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _countdownTimerSeconds,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 3, child: Text('3 Detik')),
                      DropdownMenuItem(value: 5, child: Text('5 Detik')),
                      DropdownMenuItem(value: 7, child: Text('7 Detik')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _countdownTimerSeconds = val);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              SmileToast.showSuccess(
                context,
                title: 'Pengaturan Disimpan',
                message: 'Konfigurasi event berhasil diperbarui',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2E7E),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Simpan Pengaturan Event',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
