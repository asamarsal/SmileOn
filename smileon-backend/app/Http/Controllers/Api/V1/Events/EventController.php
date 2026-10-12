<?php

namespace App\Http\Controllers\Api\V1\Events;

use App\Http\Controllers\Controller;
use App\Models\Event;
use App\Models\EventFrame;
use App\Models\EventParticipant;
use App\Models\EventGuestVoucher;
use App\Models\UserVoucher;
use App\Models\Frame;
use App\Events\EventQuotaUpdated;
use App\Jobs\ExportEventToDriveJob;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class EventController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $events = Event::where('organizer_id', $request->user()->id)
            ->withCount('participants', 'sessions', 'guestVouchers')
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 10);

        // Transform collection to include quota helper attributes for mobile app
        $events->getCollection()->transform(function (Event $event) {
            $event->remaining_credits = $event->availablePoolCredits();
            $event->quota_display = $event->quotaDisplayString();
            $event->is_exhausted = $event->isExhausted();
            return $event;
        });

        return response()->json(['success' => true, 'data' => $events]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name'              => 'required|string|max:150',
            'description'       => 'nullable|string',
            'venue'             => 'nullable|string|max:150',
            'host_voucher_code' => 'nullable|string|max:50',
            'voucher_code'      => 'nullable|string|max:50', // voucher used to create event
            'starts_at'         => 'nullable|date',
            'ends_at'           => 'nullable|date|after_or_equal:starts_at',
            'total_credits'     => 'required|integer|min:1',
            'banner_url'        => 'nullable|string',
        ]);

        $event = DB::transaction(function () use ($request) {
            $user = $request->user();

            $eventData = [
                'organizer_id'      => $user->id,
                'name'              => $request->name,
                'description'       => $request->description,
                'venue'             => $request->venue,
                'host_voucher_code' => $request->host_voucher_code ?? $request->voucher_code,
                'starts_at'         => $request->starts_at ?? now(),
                'ends_at'           => $request->ends_at,
                'total_credits'     => $request->total_credits,
                'used_credits'      => 0,
                'reserved_credits'  => 0,
                'status'            => 'active',
                'banner_url'        => $request->banner_url,
            ];

            $event = Event::create($eventData);

            // If created using a purchased voucher, mark it as used
            $voucherCodeToUse = $request->voucher_code ?? $request->host_voucher_code;
            if ($voucherCodeToUse) {
                $cleanCode = strtoupper(trim($voucherCodeToUse));
                $userVoucher = UserVoucher::where('voucher_code', $cleanCode)
                    ->where('user_id', $user->id)
                    ->first();

                if ($userVoucher) {
                    $userVoucher->update([
                        'status'         => 'Digunakan',
                        'used_for_event' => $event->name,
                        'used_at'        => now(),
                    ]);
                }
            }

            return $event;
        });

        return response()->json([
            'success' => true,
            'message' => 'Event berhasil dibuat.',
            'data'    => $event,
        ], 201);
    }

    public function show(string $uuid): JsonResponse
    {
        $event = Event::with('frames.frame', 'organizer:id,name,email,avatar_url', 'guestVouchers')
            ->where('uuid', $uuid)
            ->firstOrFail();

        $totalGuests = $event->guestVouchers->count();
        $alreadyPhoto = $event->guestVouchers->where('has_photo', true)->count();
        $notYetPhoto = $totalGuests - $alreadyPhoto;

        $event->total_guests = $totalGuests;
        $event->already_photo_count = $alreadyPhoto;
        $event->not_yet_photo_count = $notYetPhoto;
        $event->remaining_credits = $event->availablePoolCredits();
        $event->quota_display = $event->quotaDisplayString();
        $event->is_exhausted = $event->isExhausted();
        $event->invite_url = url("/events/join/{$event->access_code}");
        $event->host_url = url("/events/host/{$event->access_code}");
        $event->starts_at_formatted = $event->starts_at?->format('d M Y, H:i');
        $event->ends_at_formatted = $event->ends_at?->format('d M Y, H:i');

        return response()->json(['success' => true, 'data' => $event]);
    }

    /**
     * POST /api/v1/events/{uuid}/cover
     * Upload cover photo / banner visual event langsung ke storage VPS.
     */
    public function uploadCover(Request $request, string $uuid): JsonResponse
    {
        $request->validate([
            'cover' => 'required|image|mimes:jpeg,png,webp|max:10240',
        ]);

        $event = Event::where('uuid', $uuid)->where('organizer_id', $request->user()->id)->firstOrFail();
        $file = $request->file('cover');
        $ext = $file->getClientOriginalExtension();
        $path = $file->storePubliclyAs("events/{$event->uuid}", "cover.{$ext}", 'public');

        $url = Storage::disk('public')->url($path);
        $event->update(['banner_url' => $url]);

        return response()->json([
            'success' => true,
            'message' => 'Cover photo event berhasil disimpan di VPS.',
            'data'    => [
                'event_uuid' => $event->uuid,
                'banner_url' => $url,
            ],
        ]);
    }

    public function update(Request $request, string $uuid): JsonResponse
    {
        $event = Event::where('uuid', $uuid)->where('organizer_id', $request->user()->id)->firstOrFail();
        $event->update($request->only('name', 'description', 'venue', 'host_voucher_code', 'starts_at', 'ends_at', 'settings', 'banner_url'));
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

    // =========================================================================
    // EVENT QUOTA MANAGEMENT (Sinkronisasi Live Kuota 37/100 di Kamera Mobile)
    // =========================================================================

    /**
     * GET /api/v1/events/{uuid}/quota
     * Mengambil metrik kuota live untuk footer kamera dan kartu ringkasan.
     */
    public function quota(string $uuid): JsonResponse
    {
        $event = Event::where('uuid', $uuid)->firstOrFail();

        $remaining = $event->availablePoolCredits();
        $isLowQuota = $remaining <= (int) round($event->total_credits * 0.15) && !$event->isExhausted();

        return response()->json([
            'success' => true,
            'data'    => [
                'eventId'             => $event->uuid,
                'eventName'           => $event->name,
                'venue'               => $event->venue,
                'totalCredits'        => $event->total_credits,
                'usedCredits'         => $event->used_credits,
                'remainingCredits'    => $remaining,
                'reservedCredits'     => $event->reserved_credits,
                'userCreditsPerGuest' => 1,
                'isExhausted'         => $event->isExhausted(),
                'isLowQuota'          => $isLowQuota,
                'quotaDisplay'        => $event->quotaDisplayString(),
                'lastUpdated'         => $event->updated_at?->toIso8601String() ?? now()->toIso8601String(),
            ],
        ]);
    }

    /**
     * POST /api/v1/events/{uuid}/quota/consume
     * Memotong kuota event secara atomik saat sesi foto strip berhasil diselesaikan.
     */
    public function consumeQuota(Request $request, string $uuid): JsonResponse
    {
        $request->validate([
            'amount'     => 'nullable|integer|min:1',
            'guest_code' => 'nullable|string',
            'session_id' => 'nullable|string',
        ]);

        $amount = $request->amount ?? 1;

        $result = DB::transaction(function () use ($uuid, $amount, $request) {
            $event = Event::where('uuid', $uuid)->lockForUpdate()->firstOrFail();

            if ($event->availablePoolCredits() < $amount) {
                return [
                    'success' => false,
                    'message' => 'Kuota foto event telah habis.',
                    'status'  => 422,
                ];
            }

            // Deduct from guest voucher if provided
            if ($request->guest_code) {
                $cleanGuestCode = strtolower(trim($request->guest_code));
                $guestVoucher = EventGuestVoucher::where('event_id', $event->id)
                    ->where('voucher_code', $cleanGuestCode)
                    ->lockForUpdate()
                    ->first();

                if ($guestVoucher) {
                    $guestVoucher->increment('quota_used', $amount);
                    $guestVoucher->update([
                        'has_photo'     => true,
                        'last_photo_at' => now(),
                        'status'        => $guestVoucher->quota_used >= $guestVoucher->quota_limit ? 'exhausted' : 'active',
                    ]);
                }
            }

            $event->increment('used_credits', $amount);
            $event->touch();

            return [
                'success' => true,
                'data'    => [
                    'eventId'          => $event->uuid,
                    'totalCredits'     => $event->total_credits,
                    'usedCredits'      => $event->used_credits,
                    'remainingCredits' => $event->availablePoolCredits(),
                    'quotaDisplay'     => $event->quotaDisplayString(),
                    'isExhausted'      => $event->isExhausted(),
                ],
            ];
        });

        if (!$result['success']) {
            return response()->json(['success' => false, 'message' => $result['message']], $result['status']);
        }

        event(new EventQuotaUpdated($event->fresh()));

        return response()->json([
            'success' => true,
            'message' => 'Kuota foto event berhasil dipotong.',
            'data'    => $result['data'],
        ]);
    }

    /**
     * POST /api/v1/events/{uuid}/quota/topup
     * Menambahkan kuota foto acara oleh Host (via kredit langsung atau voucher).
     */
    public function topupQuota(Request $request, string $uuid): JsonResponse
    {
        $request->validate([
            'additional_credits' => 'required_without:voucher_code|nullable|integer|min:1',
            'voucher_code'       => 'nullable|string',
        ]);

        $event = Event::where('uuid', $uuid)->where('organizer_id', $request->user()->id)->firstOrFail();

        $creditsToAdd = $request->additional_credits ?? 0;

        // If voucher code provided, validate and consume user voucher
        if ($request->voucher_code) {
            $userVoucher = UserVoucher::where('voucher_code', strtoupper(trim($request->voucher_code)))
                ->where('user_id', $request->user()->id)
                ->where('status', 'Aktif')
                ->first();

            if (!$userVoucher || !$userVoucher->isActive()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Kode voucher tidak valid atau sudah kadaluarsa.',
                ], 422);
            }

            $creditsToAdd = $userVoucher->credit_amount;
            $userVoucher->update([
                'status'         => 'Digunakan',
                'used_for_event' => $event->name,
                'used_at'        => now(),
            ]);
        }

        $event->increment('total_credits', $creditsToAdd);
        $event->touch();

        event(new EventQuotaUpdated($event->fresh()));

        return response()->json([
            'success' => true,
            'message' => "Top-up kuota {$creditsToAdd} foto berhasil.",
            'data'    => [
                'totalCredits'     => $event->total_credits,
                'usedCredits'      => $event->used_credits,
                'remainingCredits' => $event->availablePoolCredits(),
                'quotaDisplay'     => $event->quotaDisplayString(),
            ],
        ]);
    }

    // =========================================================================
    // SPLIT VOUCHER TAMU (Guest-Specific Vouchers: haikalronald-stevenbirthday)
    // =========================================================================

    /**
     * Helper fleksibel untuk mencari event berdasarkan UUID, access_code, host_voucher_code, atau ID.
     */
    private function findEventFlexible(string $uuid, ?int $userId = null): Event
    {
        $query = Event::where(function ($q) use ($uuid) {
            $q->where('uuid', $uuid)
              ->orWhere('access_code', $uuid)
              ->orWhere('host_voucher_code', $uuid);
            if (is_numeric($uuid)) {
                $q->orWhere('id', (int) $uuid);
            }
        });

        if ($userId) {
            $event = (clone $query)->where('organizer_id', $userId)->first();
            if ($event) return $event;
        }

        return $query->firstOrFail();
    }

    /**
     * GET /api/v1/events/{uuid}/guests
     * Mengambil daftar seluruh tamu undangan, pencarian (search), filter sudah/belum foto, dan ringkasan metrik.
     */
    public function guestList(Request $request, string $uuid): JsonResponse
    {
        $event = $this->findEventFlexible($uuid, $request->user()?->id);
        
        $query = $event->guestVouchers()->orderByDesc('created_at');

        // Search by guest name, voucher code, or category
        $search = $request->query('search') ?? $request->query('q');
        if ($search) {
            $search = strtolower(trim($search));
            $query->where(function ($q) use ($search) {
                $q->whereRaw('LOWER(guest_name) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(voucher_code) LIKE ?', ["%{$search}%"])
                  ->orWhereRaw('LOWER(category) LIKE ?', ["%{$search}%"]);
            });
        }

        // Filter: sudah_foto / belum_foto / all
        $filter = $request->query('filter');
        if ($filter === 'sudah_foto' || $filter === 'sudah') {
            $query->where('has_photo', true);
        } elseif ($filter === 'belum_foto' || $filter === 'belum') {
            $query->where('has_photo', false);
        }

        // Filter category: VIP / Keluarga / Teman
        if ($request->has('category') && !empty($request->category)) {
            $query->where('category', $request->category);
        }

        $allGuests = $event->guestVouchers()->get();
        $totalGuests = $allGuests->count();
        $alreadyPhoto = $allGuests->where('has_photo', true)->count();
        $notYetPhoto = $totalGuests - $alreadyPhoto;
        $totalQuotaAllocated = $allGuests->sum('quota_limit');
        $totalQuotaUsed = $allGuests->sum('quota_used');

        $guests = $query->get()->map(function (EventGuestVoucher $guest) use ($event) {
            $inviteUrl = "https://smileon-dapps.my.id/invite/{$guest->voucher_code}";
            $guest->remaining_quota = $guest->remainingQuota();
            $guest->invite_url = $inviteUrl;
            $guest->qr_image_url = "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=" . urlencode($inviteUrl);
            $guest->share_text = "Halo {$guest->guest_name}! Kamu diundang ke acara '{$event->name}'. Nikmati photobox gratis dengan tiketmu di: {$inviteUrl}";
            return $guest;
        });

        return response()->json([
            'success' => true,
            'summary' => [
                'total_guests'            => $totalGuests,
                'already_photo'           => $alreadyPhoto,
                'not_yet_photo'           => $notYetPhoto,
                'total_quota_allocated'   => $totalQuotaAllocated,
                'total_quota_used'        => $totalQuotaUsed,
                'remaining_event_credits' => $event->availablePoolCredits(),
            ],
            'data'    => $guests,
        ]);
    }

    /**
     * POST /api/v1/events/{uuid}/guests/split-voucher (dan POST /api/v1/events/{uuid}/guests)
     * Tambah tamu event & buat kode split voucher unik.
     */
    public function splitGuestVoucher(Request $request, string $uuid): JsonResponse
    {
        $request->validate([
            'guest_name'  => 'required|string|max:150',
            'category'    => 'nullable|string|max:50',
            'quota_limit' => 'nullable|integer|min:1|max:10',
            'fcm_token'   => 'nullable|string|max:500',
        ]);

        $event = $this->findEventFlexible($uuid, $request->user()?->id);

        $baseCode = EventGuestVoucher::generateCode($request->guest_name, $event->name);
        $code = $baseCode;
        $counter = 1;
        while (EventGuestVoucher::where('voucher_code', $code)->exists()) {
            $code = "{$baseCode}-{$counter}";
            $counter++;
        }

        $inviteUrl = "https://smileon-dapps.my.id/invite/{$code}";

        $voucher = EventGuestVoucher::create([
            'event_id'     => $event->id,
            'guest_name'   => $request->guest_name,
            'guest_slug'   => EventGuestVoucher::slugify($request->guest_name),
            'voucher_code' => $code,
            'category'     => $request->category ?? 'Teman',
            'quota_limit'  => $request->quota_limit ?? 1,
            'quota_used'   => 0,
            'has_photo'    => false,
            'qr_code_url'  => "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=" . urlencode($inviteUrl),
            'status'       => 'active',
        ]);

        $voucher->remaining_quota = $voucher->remainingQuota();
        $voucher->invite_url = $inviteUrl;
        $voucher->share_text = "Halo {$voucher->guest_name}! Kamu diundang ke acara '{$event->name}'. Nikmati photobox gratis dengan tiketmu di: {$inviteUrl}";

        // Opsional: Kirim push notifikasi jika FCM token tamu disertakan
        if ($request->fcm_token) {
            try {
                app(\App\Services\Notification\FcmService::class)->sendGuestInvite($voucher, $request->fcm_token);
            } catch (\Throwable) {}
        }

        return response()->json([
            'success' => true,
            'message' => "Tamu '{$voucher->guest_name}' berhasil ditambahkan ke acara.",
            'data'    => $voucher,
        ], 201);
    }

    /**
     * DELETE /api/v1/events/{uuid}/guests/{guest_id}
     * Hapus tamu event.
     */
    public function destroyGuest(Request $request, string $uuid, int $guestId): JsonResponse
    {
        $event = $this->findEventFlexible($uuid, $request->user()?->id);
        $guest = EventGuestVoucher::where('event_id', $event->id)->where('id', $guestId)->firstOrFail();

        $guestName = $guest->guest_name;
        $guest->delete();

        return response()->json([
            'success' => true,
            'message' => "Tamu '{$guestName}' berhasil dihapus dari acara.",
        ]);
    }

    /**
     * GET /api/v1/events/{uuid}/guests/{guest_id}/share
     * Dapatkan link dan teks siap kirim ke WhatsApp/SMS untuk tamu.
     */
    public function shareGuestLink(Request $request, string $uuid, int $guestId): JsonResponse
    {
        $event = $this->findEventFlexible($uuid, $request->user()?->id);
        $guest = EventGuestVoucher::where('event_id', $event->id)->where('id', $guestId)->firstOrFail();

        $inviteUrl = "https://smileon-dapps.my.id/invite/{$guest->voucher_code}";
        $shareText = "Halo {$guest->guest_name}! Kamu mendapatkan {$guest->quota_limit} kuota foto photobox di acara '{$event->name}'. Klik link tiket kamu di sini: {$inviteUrl}";
        $waUrl = "https://api.whatsapp.com/send?text=" . urlencode($shareText);

        return response()->json([
            'success' => true,
            'data'    => [
                'guest_name'   => $guest->guest_name,
                'voucher_code' => $guest->voucher_code,
                'invite_url'   => $inviteUrl,
                'share_text'   => $shareText,
                'whatsapp_url' => $waUrl,
                'qr_image_url' => "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=" . urlencode($inviteUrl),
            ],
        ]);
    }

    /**
     * POST /api/v1/events/guests/verify (dan POST /api/v1/events/{uuid}/guests/verify)
     * Verifikasi kode voucher tamu di booth kamera tanpa mewajibkan auth token.
     */
    public function verifyGuestVoucher(Request $request, ?string $uuid = null): JsonResponse
    {
        $request->validate([
            'voucher_code' => 'required|string',
        ]);

        $code = strtolower(trim($request->voucher_code));
        $query = EventGuestVoucher::with('event:id,uuid,name,venue,total_credits,used_credits,reserved_credits,banner_url,status')
            ->where('voucher_code', $code);

        if ($uuid) {
            $event = Event::where('uuid', $uuid)->first();
            if ($event) {
                $query->where('event_id', $event->id);
            }
        }

        $guestVoucher = $query->first();

        if (!$guestVoucher) {
            return response()->json([
                'success'    => false,
                'message'    => 'Kode voucher tamu tidak ditemukan atau belum terdaftar.',
                'error_code' => 'GUEST_VOUCHER_NOT_FOUND',
            ], 404);
        }

        if (!$guestVoucher->isQuotaAvailable()) {
            return response()->json([
                'success'    => false,
                'message'    => "Halo {$guestVoucher->guest_name}! Kuota fotomu sudah terpakai ({$guestVoucher->quota_used}/{$guestVoucher->quota_limit} sesi).",
                'error_code' => 'GUEST_QUOTA_EXHAUSTED',
                'data'       => $guestVoucher,
            ], 422);
        }

        $event = $guestVoucher->event;
        if ($event && $event->isExhausted()) {
            return response()->json([
                'success'    => false,
                'message'    => "Kuota total acara {$event->name} telah habis ({$event->quotaDisplayString()}).",
                'error_code' => 'EVENT_QUOTA_EXHAUSTED',
                'data'       => $guestVoucher,
            ], 422);
        }

        return response()->json([
            'success' => true,
            'message' => "Selamat datang, {$guestVoucher->guest_name}! Kode undangan valid.",
            'data'    => [
                'guestId'         => $guestVoucher->uuid,
                'guestName'       => $guestVoucher->guest_name,
                'category'        => $guestVoucher->category,
                'voucherCode'     => $guestVoucher->voucher_code,
                'remainingQuota'  => $guestVoucher->remainingQuota(),
                'event'           => [
                    'uuid'             => $event->uuid,
                    'name'             => $event->name,
                    'venue'            => $event->venue,
                    'totalCredits'     => $event->total_credits,
                    'remainingCredits' => $event->availablePoolCredits(),
                    'bannerUrl'        => $event->banner_url,
                ],
            ],
        ]);
    }

    // =========================================================================
    // FRAME & GUEST ACCESS MANAGEMENT
    // =========================================================================

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
        $request->validate([
            'title'          => 'required|string|max:150',
            'frame_file'     => 'required_without:frame_url|nullable|file|mimes:png,webp|max:20480',
            'frame_url'      => 'nullable|string',
            'thumbnail_file' => 'nullable|file|mimes:jpeg,png,webp|max:10240',
            'slot_index'     => 'nullable|integer|between:1,3',
        ]);

        $event = Event::where('uuid', $uuid)->where('organizer_id', $request->user()->id)->firstOrFail();

        $frameUrl = $request->frame_url;
        if ($request->hasFile('frame_file')) {
            $path = $request->file('frame_file')->storePublicly('frames/custom', 'public');
            $frameUrl = Storage::disk('public')->url($path);
        }

        $thumbnailUrl = $frameUrl;
        if ($request->hasFile('thumbnail_file')) {
            $thumbPath = $request->file('thumbnail_file')->storePublicly('frames/thumbnails', 'public');
            $thumbnailUrl = Storage::disk('public')->url($thumbPath);
        }

        $frame = Frame::create([
            'title'         => $request->title,
            'creator_id'    => $request->user()->id,
            'thumbnail_url' => $thumbnailUrl,
            'frame_url'     => $frameUrl,
            'orientation'   => 'portrait',
            'is_free'       => true,
            'status'        => 'active',
        ]);

        EventFrame::updateOrCreate(
            ['event_id' => $event->id, 'slot_index' => $request->slot_index ?? 1],
            ['frame_id' => $frame->id, 'is_custom' => true]
        );

        return response()->json([
            'success' => true,
            'message' => 'Custom frame berhasil diupload dan dipasang ke event.',
            'data'    => $frame,
        ], 201);
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
        $joinUrl = url("/events/join/{$event->access_code}");
        $qrImageUrl = "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=" . urlencode($joinUrl);

        return response()->json([
            'success' => true,
            'data'    => [
                'event_uuid'   => $event->uuid,
                'event_name'   => $event->name,
                'access_code'  => $event->access_code,
                'invite_url'   => $joinUrl,
                'qr_data'      => $joinUrl,
                'qr_image_url' => $qrImageUrl,
                'total_credits'=> $event->total_credits,
                'remaining'    => $event->availablePoolCredits(),
            ],
        ]);
    }

    public function hostQr(string $uuid): JsonResponse
    {
        $event = Event::where('uuid', $uuid)->firstOrFail();
        $hostJoinUrl = url("/events/host/{$event->access_code}");
        $qrImageUrl = "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=" . urlencode($hostJoinUrl);

        return response()->json([
            'success' => true,
            'data'    => [
                'event_uuid'   => $event->uuid,
                'event_name'   => $event->name,
                'access_code'  => $event->access_code,
                'host_url'     => $hostJoinUrl,
                'qr_data'      => $hostJoinUrl,
                'qr_image_url' => $qrImageUrl,
            ],
        ]);
    }

    /**
     * POST /api/v1/events/{uuid}/export/drive
     * Simpan foto bulk seluruh sesi foto event ke Google Drive folder event.
     */
    public function exportDrive(Request $request, string $uuid): JsonResponse
    {
        $event = Event::where('uuid', $uuid)->where('organizer_id', $request->user()->id)->firstOrFail();

        ExportEventToDriveJob::dispatch($event->id, $request->user()->id);

        return response()->json([
            'success' => true,
            'message' => "Proses backup bulk foto event '{$event->name}' ke Google Drive telah dijadwalkan.",
            'data'    => [
                'event_uuid' => $event->uuid,
                'event_name' => $event->name,
                'status'     => 'queued',
            ],
        ]);
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

    /**
     * GET /api/v1/events/guests/{voucher_code}/latest-photos
     * Mengambil hasil foto & photostrip terbaru milik tamu berdasarkan kode voucher (tanpa login).
     */
    public function guestLatestPhotos(string $voucherCode): JsonResponse
    {
        $cleanCode = strtolower(trim($voucherCode));
        $guestVoucher = EventGuestVoucher::with(['event', 'photoSessions' => function ($q) {
            $q->with('photos', 'strip')->whereIn('status', ['completing', 'completed'])->orderByDesc('created_at');
        }])->where('voucher_code', $cleanCode)->first();

        if (!$guestVoucher) {
            return response()->json([
                'success' => false,
                'message' => 'Voucher tamu tidak ditemukan.',
                'error_code' => 'VOUCHER_NOT_FOUND',
            ], 404);
        }

        $latestSession = $guestVoucher->photoSessions->first();

        return response()->json([
            'success' => true,
            'data'    => [
                'guestName'     => $guestVoucher->guest_name,
                'voucherCode'   => $guestVoucher->voucher_code,
                'eventName'     => $guestVoucher->event?->name,
                'hasPhoto'      => $guestVoucher->has_photo,
                'lastPhotoAt'   => $guestVoucher->last_photo_at?->toIso8601String(),
                'photostripUrl' => $latestSession?->strip?->clean_url ?? $latestSession?->strip?->watermarked_url,
                'photos'        => $latestSession?->photos->map(fn($p) => [
                    'index' => $p->shot_index,
                    'url'   => $p->signed_url ?? $p->raw_url,
                ]) ?? [],
                'shareUrl'      => url('/invite/' . $guestVoucher->voucher_code),
            ],
        ]);
    }
}


