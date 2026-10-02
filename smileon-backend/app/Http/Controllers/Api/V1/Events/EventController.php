<?php

namespace App\Http\Controllers\Api\V1\Events;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\EventFrame;
use App\Models\EventParticipant;
use App\Models\Frame;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class EventController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $events = Event::where('organizer_id', $request->user()->id)
            ->withCount('participants', 'sessions')
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 10);
        return response()->json(['success' => true, 'data' => $events]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name'          => 'required|string|max:150',
            'description'   => 'nullable|string',
            'starts_at'     => 'nullable|date',
            'ends_at'       => 'nullable|date|after_or_equal:starts_at',
            'total_credits' => 'required|integer|min:1',
        ]);

        $event = Event::create(array_merge($request->validated(), ['organizer_id' => $request->user()->id]));
        return response()->json(['success' => true, 'data' => $event], 201);
    }

    public function show(string $uuid): JsonResponse
    {
        $event = Event::with('frames.frame', 'organizer:id,name,avatar_url')->where('uuid', $uuid)->firstOrFail();
        return response()->json(['success' => true, 'data' => $event]);
    }

    public function update(Request $request, string $uuid): JsonResponse
    {
        $event = Event::where('uuid', $uuid)->where('organizer_id', $request->user()->id)->firstOrFail();
        $event->update($request->only('name', 'description', 'starts_at', 'ends_at', 'settings'));
        return response()->json(['success' => true, 'data' => $event]);
    }

    public function destroy(Request $request, string $uuid): JsonResponse
    {
        Event::where('uuid', $uuid)->where('organizer_id', $request->user()->id)->firstOrFail()->delete();
        return response()->json(['success' => true, 'message' => 'Event dihapus.']);
    }

    public function start(Request $request, string $uuid): JsonResponse
    {
        $event = Event::where('uuid', $uuid)->where('organizer_id', $request->user()->id)->firstOrFail();
        $event->update(['is_event_started' => true, 'status' => 'active']);
        return response()->json(['success' => true, 'data' => $event]);
    }

    public function end(Request $request, string $uuid): JsonResponse
    {
        $event = Event::where('uuid', $uuid)->where('organizer_id', $request->user()->id)->firstOrFail();
        $event->update(['is_event_started' => false, 'status' => 'completed']);
        return response()->json(['success' => true, 'data' => $event]);
    }

    public function toggleWatermark(Request $request, string $uuid): JsonResponse
    {
        $event = Event::where('uuid', $uuid)->where('organizer_id', $request->user()->id)->firstOrFail();
        $event->update(['force_remove_watermark' => !$event->force_remove_watermark]);
        return response()->json(['success' => true, 'data' => ['force_remove_watermark' => $event->force_remove_watermark]]);
    }

    public function frames(string $uuid): JsonResponse
    {
        $event = Event::where('uuid', $uuid)->firstOrFail();
        return response()->json(['success' => true, 'data' => $event->frames()->with('frame:id,uuid,title,thumbnail_url,frame_url')->get()]);
    }

    public function attachFrame(Request $request, string $uuid): JsonResponse
    {
        $request->validate(['frame_uuid' => 'required|string', 'slot_index' => 'required|integer|between:1,3']);
        $event = Event::where('uuid', $uuid)->where('organizer_id', $request->user()->id)->firstOrFail();
        $frame = Frame::where('uuid', $request->frame_uuid)->firstOrFail();

        EventFrame::updateOrCreate(
            ['event_id' => $event->id, 'slot_index' => $request->slot_index],
            ['frame_id' => $frame->id, 'is_custom' => false]
        );

        return response()->json(['success' => true, 'message' => 'Frame dipasang ke event.']);
    }

    public function uploadCustomFrame(Request $request, string $uuid): JsonResponse
    {
        // TODO: Handle R2 upload for custom frame
        return response()->json(['success' => false, 'message' => 'Custom frame upload akan segera hadir.'], 501);
    }

    public function detachFrame(Request $request, string $uuid, int $frameId): JsonResponse
    {
        $event = Event::where('uuid', $uuid)->where('organizer_id', $request->user()->id)->firstOrFail();
        EventFrame::where('event_id', $event->id)->where('frame_id', $frameId)->delete();
        return response()->json(['success' => true, 'message' => 'Frame dicopot dari event.']);
    }

    public function inviteQr(string $uuid): JsonResponse
    {
        $event = Event::where('uuid', $uuid)->firstOrFail();
        return response()->json(['success' => true, 'data' => ['access_code' => $event->access_code, 'qr_url' => "https://smileon.app/join/{$event->access_code}"]]);
    }

    public function hostQr(string $uuid): JsonResponse
    {
        $event = Event::where('uuid', $uuid)->firstOrFail();
        return response()->json(['success' => true, 'data' => ['access_code' => $event->access_code]]);
    }

    public function joinEvent(Request $request, string $accessCode): JsonResponse
    {
        $event = Event::where('access_code', $accessCode)->where('status', 'active')->firstOrFail();

        EventParticipant::firstOrCreate(
            ['event_id' => $event->id, 'user_id' => $request->user()->id],
            ['role' => 'guest', 'checked_in_at' => now()]
        );

        return response()->json(['success' => true, 'data' => $event->load('frames.frame')]);
    }

    public function joinedEvents(Request $request): JsonResponse
    {
        $events = $request->user()->load(['sessions.event'])->sessions->pluck('event')->unique('id')->values();
        return response()->json(['success' => true, 'data' => $events]);
    }
}
