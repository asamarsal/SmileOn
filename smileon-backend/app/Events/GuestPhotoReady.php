<?php

namespace App\Events;

use App\Models\EventGuestVoucher;
use App\Models\PhotoSession;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class GuestPhotoReady implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public EventGuestVoucher $guestVoucher,
        public PhotoSession $session
    ) {
    }

    public function broadcastOn(): Channel
    {
        return new Channel('guests.' . $this->guestVoucher->voucher_code);
    }

    public function broadcastWith(): array
    {
        $strip = $this->session->strip;
        $photos = $this->session->photos()->orderBy('shot_index')->get()->map(function ($p) {
            return [
                'index'    => $p->shot_index,
                'url'      => $p->signed_url ?? $p->raw_url ?? '',
                'fileName' => $p->file_name ?? '',
            ];
        });

        return [
            'voucherCode'    => $this->guestVoucher->voucher_code,
            'guestName'      => $this->guestVoucher->guest_name,
            'eventName'      => $this->guestVoucher->event->name ?? '',
            'sessionId'      => $this->session->uuid,
            'photostripUrl'  => $strip?->clean_url ?? $strip?->watermarked_url ?? '',
            'shareUrl'       => url('/invite/' . $this->guestVoucher->voucher_code),
            'photos'         => $photos,
            'completedAt'    => now()->toIso8601String(),
        ];
    }
}
