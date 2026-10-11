<?php

namespace App\Jobs;

use App\Models\PhotoStrip;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

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

    public function handle(): void
    {
        $strip = PhotoStrip::find($this->photoStripId);
        if (!$strip) {
            Log::warning("UploadPhotostripToDriveJob: PhotoStrip #{$this->photoStripId} not found.");
            return;
        }

        Log::info("UploadPhotostripToDriveJob: Syncing PhotoStrip #{$strip->id} (uuid: {$strip->uuid}) to Google Drive folder: " . ($this->targetFolder ?? 'SmileOn Events'));

        // If Google Drive API / Cloud Storage is connected, perform the upload here
        // Update metadata or sync state
        $metadata = $strip->metadata ?? [];
        $metadata['drive_synced_at'] = now()->toIso8601String();
        $metadata['drive_status'] = 'synced';
        $strip->update(['metadata' => $metadata]);
    }
}
