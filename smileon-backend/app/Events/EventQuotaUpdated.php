<?php

namespace App\Events;

use App\Models\Event;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class EventQuotaUpdated implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public Event $event)
    {
    }

    public function broadcastOn(): Channel
    {
        return new Channel('events.' . $this->event->uuid);
    }

    public function broadcastWith(): array
    {
        return [
            'eventId'          => $this->event->uuid,
            'totalCredits'     => $this->event->total_credits,
            'usedCredits'      => $this->event->used_credits,
            'remainingCredits' => $this->event->availablePoolCredits(),
            'lastUpdated'      => now()->toIso8601String(),
        ];
    }
}
