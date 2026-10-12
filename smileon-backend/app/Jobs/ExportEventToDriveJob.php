<?php

namespace App\Jobs;

use App\Models\Event;
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

class ExportEventToDriveJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 60;

    public function __construct(
        public int $eventId,
        public ?int $userId = null
    ) {
    }

    public function handle(GoogleDriveService $driveService): void
    {
        $event = Event::with(['sessions.photos', 'sessions.strip'])->find($this->eventId);
        if (!$event) {
            Log::warning("ExportEventToDriveJob: Event #{$this->eventId} tidak ditemukan.");
            return;
        }

        Log::info("ExportEventToDriveJob: Memulai backup bulk event '{$event->name}' (#{$event->id}) ke Google Drive.");

        if (!$driveService->isConfigured()) {
            Log::warning("ExportEventToDriveJob: Kredensial Google Drive belum dikonfigurasi di .env.");
            return;
        }

        // 1. Buat folder khusus event di Google Drive
        $folderName = "SmileOn Event - {$event->name} ({$event->access_code})";
        $folder = $driveService->createFolder($folderName);
        $folderId = $folder['id'] ?? null;

        if (!$folderId) {
            Log::error("ExportEventToDriveJob: Gagal membuat folder di Google Drive.");
            return;
        }

        $uploadedCount = 0;

        // 2. Loop semua sesi foto di event ini
        foreach ($event->sessions as $session) {
            // Upload photostrip HD
            if ($session->strip) {
                $strip = $session->strip;
                $stripKey = "strips/{$session->uuid}/photostrip_hd.png";
                $content = null;

                if (Storage::disk('public')->exists($stripKey)) {
                    $content = Storage::disk('public')->get($stripKey);
                } elseif ($strip->clean_url) {
                    try {
                        $res = Http::timeout(20)->get($strip->clean_url);
                        if ($res->successful()) $content = $res->body();
                    } catch (\Throwable) {}
                }

                if ($content) {
                    $driveService->uploadFile(
                        $content,
                        "Photostrip_{$session->session_code}_{$session->uuid}.png",
                        $folderId,
                        'image/png'
                    );
                    $uploadedCount++;
                }
            }

            // Upload foto satuan (shots)
            foreach ($session->photos as $photo) {
                $photoKey = "photos/{$session->uuid}/shot_{$photo->shot_number}.jpg";
                $photoContent = null;

                if (Storage::disk('public')->exists($photoKey)) {
                    $photoContent = Storage::disk('public')->get($photoKey);
                } elseif ($photo->original_url) {
                    try {
                        $res = Http::timeout(20)->get($photo->original_url);
                        if ($res->successful()) $photoContent = $res->body();
                    } catch (\Throwable) {}
                }

                if ($photoContent) {
                    $driveService->uploadFile(
                        $photoContent,
                        "Shot_{$session->session_code}_{$photo->shot_number}.jpg",
                        $folderId,
                        'image/jpeg'
                    );
                    $uploadedCount++;
                }
            }
        }

        Log::info("ExportEventToDriveJob: Berhasil mengupload {$uploadedCount} foto event ke Google Drive folder '{$folderName}' (Link: {$folder['web_view_link']}).");

        // Simpan log sinkronisasi
        StorageSync::create([
            'user_id'          => $this->userId ?? $event->organizer_id,
            'source_url'       => url("/api/v1/events/{$event->uuid}"),
            'destination_type' => 'google_drive',
            'destination_id'   => $folderId,
            'destination_url'  => $folder['web_view_link'],
            'status'           => 'completed',
            'synced_at'        => now(),
        ]);
    }
}
