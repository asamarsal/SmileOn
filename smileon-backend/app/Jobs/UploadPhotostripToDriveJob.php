<?php

namespace App\Jobs;

use App\Models\PhotoStrip;
use App\Models\StorageSync;
use App\Services\Storage\GoogleDriveService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class UploadPhotostripToDriveJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 60;

    public function __construct(
        public int $photoStripId,
        public ?string $targetFolder = null
    ) {
    }

    public function handle(GoogleDriveService $driveService): void
    {
        $strip = PhotoStrip::find($this->photoStripId);
        if (!$strip) {
            Log::warning("UploadPhotostripToDriveJob: PhotoStrip #{$this->photoStripId} not found.");
            return;
        }

        $sync = StorageSync::where('strip_id', $strip->id)
            ->where('destination_type', 'google_drive')
            ->first();

        Log::info("UploadPhotostripToDriveJob: Syncing PhotoStrip #{$strip->id} (uuid: {$strip->uuid}) to Google Drive Admin.");

        // Dapatkan binary image photostrip
        $sourceUrl = $strip->clean_url ?? $strip->watermarked_url;
        $content = null;

        if ($sourceUrl && (str_starts_with($sourceUrl, 'http://') || str_starts_with($sourceUrl, 'https://'))) {
            try {
                $response = Http::timeout(30)->get($sourceUrl);
                if ($response->successful()) {
                    $content = $response->body();
                }
            } catch (\Throwable $e) {
                Log::warning("UploadPhotostripToDriveJob: Gagal download source URL {$sourceUrl}: " . $e->getMessage());
            }
        }

        // Jika tidak bisa via URL, coba baca dari local disk
        if (!$content) {
            $localKey = "strips/{$strip->uuid}/photostrip_hd.png";
            if (Storage::disk('public')->exists($localKey)) {
                $content = Storage::disk('public')->get($localKey);
            }
        }

        if (!$content) {
            $err = "File photostrip #{$strip->id} tidak ditemukan untuk diupload ke Google Drive.";
            Log::error("UploadPhotostripToDriveJob: {$err}");
            $sync?->update(['status' => 'failed', 'last_error' => $err]);
            return;
        }

        $fileName = "SmileOn_Strip_{$strip->uuid}.png";
        $result = $driveService->uploadFile($content, $fileName, $this->targetFolder);

        if ($result && !empty($result['file_id'])) {
            $metadata = $strip->metadata ?? [];
            $metadata['drive_synced_at'] = now()->toIso8601String();
            $metadata['drive_status'] = 'synced';
            $metadata['drive_file_id'] = $result['file_id'];
            $metadata['drive_view_link'] = $result['web_view_link'];

            $strip->update(['metadata' => $metadata]);

            $sync?->update([
                'status'          => 'completed',
                'destination_id'  => $result['file_id'],
                'destination_url' => $result['web_view_link'],
                'synced_at'       => now(),
                'last_error'      => null,
            ]);

            Log::info("UploadPhotostripToDriveJob: PhotoStrip #{$strip->id} sukses disimpan ke Google Drive Admin ({$result['web_view_link']}).");
        } else {
            $err = "Google Drive API tidak merespon ID file atau kredensial Google Drive belum aktif di .env.";
            Log::warning("UploadPhotostripToDriveJob: {$err}");

            $sync?->update([
                'status'     => 'pending',
                'last_error' => $err,
                'attempts'   => ($sync->attempts ?? 0) + 1,
            ]);
        }
    }
}
