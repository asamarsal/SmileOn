<?php

namespace App\Jobs;

use App\Models\PhotoStrip;
use App\Mail\PhotoStripExportMail;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class SendPhotoStripEmailJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 30;

    public function __construct(
        public int $photoStripId,
        public string $recipientEmail
    ) {
    }

    public function handle(): void
    {
        $strip = PhotoStrip::find($this->photoStripId);
        if (!$strip) {
            Log::warning("SendPhotoStripEmailJob: PhotoStrip #{$this->photoStripId} tidak ditemukan.");
            return;
        }

        try {
            Mail::to($this->recipientEmail)->send(new PhotoStripExportMail($strip));
            Log::info("SendPhotoStripEmailJob: Berhasil mengirim photostrip #{$strip->id} ke email {$this->recipientEmail}.");
        } catch (\Throwable $e) {
            Log::error("SendPhotoStripEmailJob Exception ke {$this->recipientEmail}: " . $e->getMessage());
            throw $e;
        }
    }
}
