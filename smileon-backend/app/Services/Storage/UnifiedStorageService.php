<?php

namespace App\Services\Storage;

use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

class UnifiedStorageService
{
    protected GoogleDriveService $driveService;

    public function __construct(GoogleDriveService $driveService)
    {
        $this->driveService = $driveService;
    }

    /**
     * Menyimpan file dengan opsi target: 'vps' (local public), 's3', 'r2', atau 'google_drive'.
     *
     * @param string $content Konten file biner
     * @param string $path Relatif path (contoh: "strips/uuid/photostrip_hd.png")
     * @param string|null $disk Target disk ('vps'|'public'|'s3'|'r2'|'google_drive'|null)
     * @return array Detail hasil penyimpanan ['disk', 'url', 'path', 'meta']
     */
    public function save(string $content, string $path, ?string $disk = null): array
    {
        $targetDisk = $disk ?? config('filesystems.default_save_target', env('FILESYSTEM_DISK', 'public'));

        // Normalisasi nama disk
        if ($targetDisk === 'vps') {
            $targetDisk = 'public';
        }

        // 1. Simpan ke Google Drive Admin
        if ($targetDisk === 'google' || $targetDisk === 'google_drive') {
            $fileName = basename($path);
            $driveResult = $this->driveService->uploadFile($content, $fileName);

            if ($driveResult) {
                return [
                    'disk'    => 'google_drive',
                    'success' => true,
                    'url'     => $driveResult['web_view_link'],
                    'file_id' => $driveResult['file_id'],
                    'path'    => $path,
                ];
            }

            Log::warning("UnifiedStorageService: Fallback ke VPS public disk karena Google Drive gagal.");
            $targetDisk = 'public';
        }

        // 2. Simpan ke S3 / R2 / VPS Public Storage
        Storage::disk($targetDisk)->put($path, $content, 'public');
        $url = Storage::disk($targetDisk)->url($path);

        return [
            'disk'    => $targetDisk,
            'success' => true,
            'url'     => $url,
            'path'    => $path,
        ];
    }
}
