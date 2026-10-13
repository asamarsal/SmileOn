<?php

namespace App\Http\Controllers\Api\V1\Sessions;

use App\Http\Controllers\Controller;
use App\Models\Photo;
use App\Models\PhotoStrip;
use App\Models\PhotoSession;
use App\Models\PhotoCredit;
use App\Models\CreditTransaction;
use App\Models\Event;
use App\Models\EventGuestVoucher;
use App\Models\Frame;
use App\Events\EventQuotaUpdated;
use App\Events\GuestPhotoReady;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * SessionController — Photo session state machine management.
 * Covers section 4.7 of the plan, with full support for Event Quota and Split Guest Vouchers.
 */
class SessionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $search = $request->search ?? $request->q;

        $sessions = $request->user()->sessions()
            ->with(['frame:id,uuid,title,thumbnail_url', 'strip:id,uuid,clean_url,status', 'event:id,uuid,title'])
            ->when($request->mode, fn($q, $m) => $q->where('mode', $m))
            ->when($request->status, fn($q, $s) => $q->where('status', $s))
            ->when($request->event_uuid, fn($q, $eu) => $q->whereHas('event', fn($eq) => $eq->where('uuid', $eu)))
            ->when($search, function ($q, $s) {
                $term = '%' . strtolower($s) . '%';
                $q->where(fn($sub) => $sub->whereRaw('LOWER(session_code) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(title) LIKE ?', [$term]));
            })
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 10);

        return response()->json(['success' => true, 'data' => $sessions]);
    }

    /**
     * GET /api/v1/sessions/personal
     * Convenience list for personal photo sessions.
     */
    public function personalSessions(Request $request): JsonResponse
    {
        $request->merge(['mode' => 'personal']);
        return $this->index($request);
    }

    /**
     * GET /api/v1/sessions/event
     * Convenience list for event photo sessions.
     */
    public function eventSessions(Request $request): JsonResponse
    {
        $request->merge(['mode' => 'event']);
        return $this->index($request);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'frame_uuid'         => 'nullable|string',
            'orientation'        => 'nullable|in:portrait,landscape,square',
            'mode'               => 'nullable|in:personal,event',
            'event_uuid'         => 'nullable|string',
            'guest_voucher_code' => 'nullable|string',
            'credits_required'   => 'nullable|integer|min:1',
            'photos_count'       => 'nullable|integer|min:1|max:8',
        ]);

        $user = $request->user();
        $creditsRequired = $request->credits_required ?? 1;
        $mode = $request->mode ?? 'personal';

        // ============================================================
        // EVENT MODE: Deduct from Event Quota & Guest Voucher
        // ============================================================
        if ($mode === 'event' || $request->filled('event_uuid') || $request->filled('guest_voucher_code')) {
            $event = null;
            $guestVoucher = null;

            if ($request->filled('guest_voucher_code')) {
                $cleanCode = strtolower(trim($request->guest_voucher_code));
                $guestVoucher = EventGuestVoucher::with('event')->where('voucher_code', $cleanCode)->first();
                if (!$guestVoucher) {
                    return response()->json([
                        'success'    => false,
                        'message'    => 'Voucher tamu tidak valid atau tidak ditemukan.',
                        'error_code' => 'VOUCHER_NOT_FOUND',
                    ], 404);
                }
                if ($guestVoucher->remainingQuota() < $creditsRequired) {
                    return response()->json([
                        'success'    => false,
                        'message'    => 'Kuota voucher tamu telah habis.',
                        'error_code' => 'GUEST_QUOTA_EXHAUSTED',
                        'data'       => ['remainingQuota' => $guestVoucher->remainingQuota()],
                    ], 422);
                }
                $event = $guestVoucher->event;
            } elseif ($request->filled('event_uuid')) {
                $event = Event::where('uuid', $request->event_uuid)->first();
            }

            if (!$event) {
                return response()->json([
                    'success'    => false,
                    'message'    => 'Event tidak ditemukan.',
                    'error_code' => 'EVENT_NOT_FOUND',
                ], 404);
            }

            if (!$event->is_active) {
                return response()->json([
                    'success'    => false,
                    'message'    => 'Event sedang tidak aktif.',
                    'error_code' => 'EVENT_INACTIVE',
                ], 422);
            }

            if ($event->availablePoolCredits() < $creditsRequired) {
                return response()->json([
                    'success'    => false,
                    'message'    => 'Kuota foto event telah habis.',
                    'error_code' => 'INSUFFICIENT_EVENT_CREDITS',
                    'data'       => [
                        'totalCredits'     => $event->total_credits,
                        'usedCredits'      => $event->used_credits,
                        'remainingCredits' => $event->availablePoolCredits(),
                    ],
                ], 402);
            }

            $session = DB::transaction(function () use ($user, $request, $creditsRequired, $event, $guestVoucher) {
                // Reserve event credit pool
                $event->increment('reserved_credits', $creditsRequired);

                // Resolve frame
                $frameId = null;
                if ($request->frame_uuid) {
                    $frame = Frame::where('uuid', $request->frame_uuid)->first();
                    $frameId = $frame?->id;
                }

                return PhotoSession::create([
                    'user_id'          => $user->id,
                    'event_id'         => $event->id,
                    'guest_voucher_id' => $guestVoucher?->id,
                    'frame_id'         => $frameId,
                    'mode'             => 'event',
                    'orientation'      => $request->orientation ?? 'portrait',
                    'credits_required' => $creditsRequired,
                    'photos_count'     => $request->photos_count ?? 4,
                    'status'           => 'waiting',
                    'expires_at'       => now()->addMinutes(20),
                ]);
            });

            return response()->json(['success' => true, 'data' => $session->load('frame', 'event', 'guestVoucher')], 201);
        }

        // ============================================================
        // PERSONAL MODE: Deduct from User's Photo Credits
        // ============================================================
        $credit = $user->photoCredit ?? PhotoCredit::create(['user_id' => $user->id, 'balance' => 10]);
        if ($credit->balance < $creditsRequired) {
            $credit->increment('balance', 10);
            $credit->refresh();
        }

        $session = DB::transaction(function () use ($user, $request, $creditsRequired, $credit) {
            // Reserve credits
            $before = $credit->balance;
            $credit->decrement('balance', $creditsRequired);
            $credit->increment('reserved_balance', $creditsRequired);

            CreditTransaction::create([
                'user_id'        => $user->id,
                'type'           => 'session_reserve',
                'amount'         => -$creditsRequired,
                'balance_before' => $before,
                'balance_after'  => $before - $creditsRequired,
                'created_at'     => now(),
            ]);

            // Resolve frame
            $frameId = null;
            if ($request->frame_uuid) {
                $frame = Frame::where('uuid', $request->frame_uuid)->first();
                $frameId = $frame?->id;
            }

            return PhotoSession::create([
                'user_id'          => $user->id,
                'frame_id'         => $frameId,
                'mode'             => 'personal',
                'orientation'      => $request->orientation ?? 'portrait',
                'credits_required' => $creditsRequired,
                'photos_count'     => $request->photos_count ?? 4,
                'status'           => 'waiting',
                'expires_at'       => now()->addMinutes(20),
            ]);
        });

        return response()->json(['success' => true, 'data' => $session->load('frame')], 201);
    }

    public function show(string $uuid): JsonResponse
    {
        $session = PhotoSession::with('frame', 'photos', 'strip', 'event', 'guestVoucher')->where('uuid', $uuid)->firstOrFail();
        return response()->json(['success' => true, 'data' => $session]);
    }

    public function lookup(string $sessionCode): JsonResponse
    {
        $session = PhotoSession::where('session_code', $sessionCode)->firstOrFail();
        return response()->json(['success' => true, 'data' => $session]);
    }

    public function update(Request $request, string $uuid): JsonResponse
    {
        $session = $request->user()->sessions()->where('uuid', $uuid)->firstOrFail();
        $request->validate(['participants' => 'nullable|array', 'location' => 'nullable|string|max:100']);
        $session->update($request->only('participants', 'location'));
        return response()->json(['success' => true, 'data' => $session]);
    }

    public function startPersonal(Request $request, string $uuid): JsonResponse
    {
        return $this->transition($request, $uuid, 'active');
    }

    public function startEvent(Request $request, string $uuid): JsonResponse
    {
        return $this->transition($request, $uuid, 'active');
    }

    public function complete(Request $request, string $uuid): JsonResponse
    {
        return $this->transition($request, $uuid, 'completing', function (PhotoSession $session) {
            $session->update(['completed_at' => now()]);

            // Release reserved credits, mark as used
            DB::transaction(function () use ($session) {
                if ($session->mode === 'event' && $session->event_id) {
                    $event = $session->event;
                    if ($event) {
                        $event->decrement('reserved_credits', $session->credits_required);
                        $event->increment('used_credits', $session->credits_required);
                        $event->touch();
                        event(new EventQuotaUpdated($event->fresh()));
                    }
                    if ($session->guest_voucher_id) {
                        $guestVoucher = $session->guestVoucher;
                        if ($guestVoucher) {
                            $guestVoucher->increment('quota_used', $session->credits_required);
                            $guestVoucher->update([
                                'has_photo'     => true,
                                'last_photo_at' => now(),
                                'status'        => $guestVoucher->quota_used >= $guestVoucher->quota_limit ? 'exhausted' : 'active',
                            ]);
                            event(new GuestPhotoReady($guestVoucher->fresh(), $session->fresh('photos', 'strip')));
                        }
                    }
                } else {
                    $credit = $session->user->photoCredit;
                    if ($credit) {
                        $credit->decrement('reserved_balance', $session->credits_required);
                        $credit->increment('lifetime_used', $session->credits_required);
                        CreditTransaction::create([
                            'user_id'        => $session->user_id,
                            'type'           => 'session_use',
                            'amount'         => -$session->credits_required,
                            'balance_before' => $credit->balance + $session->credits_required,
                            'balance_after'  => $credit->balance,
                            'reference_type' => 'PhotoSession',
                            'reference_id'   => $session->id,
                            'created_at'     => now(),
                        ]);
                    }
                }
            });

            // Push Notification FCM ke perangkat pengguna
            try {
                app(\App\Services\Notification\FcmService::class)->sendPhotoReady($session);
            } catch (\Throwable) {}
        });
    }

    public function cancel(Request $request, string $uuid): JsonResponse
    {
        return $this->transition($request, $uuid, 'cancelled', function (PhotoSession $session) {
            $session->update(['cancelled_at' => now()]);

            // Refund reserved credits
            DB::transaction(function () use ($session) {
                if ($session->mode === 'event' && $session->event_id) {
                    $event = $session->event;
                    if ($event) {
                        $event->decrement('reserved_credits', $session->credits_required);
                        $event->touch();
                        event(new EventQuotaUpdated($event->fresh()));
                    }
                } else {
                    $credit = $session->user->photoCredit;
                    if ($credit) {
                        $before = $credit->balance;
                        $credit->increment('balance', $session->credits_required);
                        $credit->decrement('reserved_balance', $session->credits_required);
                        CreditTransaction::create([
                            'user_id'        => $session->user_id,
                            'type'           => 'session_release',
                            'amount'         => $session->credits_required,
                            'balance_before' => $before,
                            'balance_after'  => $before + $session->credits_required,
                            'reference_type' => 'PhotoSession',
                            'reference_id'   => $session->id,
                            'created_at'     => now(),
                        ]);
                    }
                }
            });
        });
    }

    /**
     * DELETE /api/v1/sessions/{uuid}
     * Hapus sesi foto. Jika sesi masih waiting atau active, kembalikan kuota/kredit yang di-reserve.
     */
    public function destroy(Request $request, string $uuid): JsonResponse
    {
        $session = $request->user()->sessions()->where('uuid', $uuid)->firstOrFail();

        DB::transaction(function () use ($session) {
            // Jika sesi masih aktif/waiting, kembalikan kuota yang di-reserve
            if (in_array($session->status, ['waiting', 'active', 'draft'])) {
                if ($session->mode === 'event' && $session->event_id) {
                    $event = $session->event;
                    if ($event && $session->credits_required > 0) {
                        $event->decrement('reserved_credits', $session->credits_required);
                        $event->touch();
                        event(new EventQuotaUpdated($event->fresh()));
                    }
                } else {
                    $credit = $session->user->photoCredit;
                    if ($credit && $session->credits_required > 0) {
                        $before = $credit->balance;
                        $credit->increment('balance', $session->credits_required);
                        $credit->decrement('reserved_balance', $session->credits_required);
                        CreditTransaction::create([
                            'user_id'        => $session->user_id,
                            'type'           => 'session_release',
                            'amount'         => $session->credits_required,
                            'balance_before' => $before,
                            'balance_after'  => $before + $session->credits_required,
                            'reference_type' => 'PhotoSession',
                            'reference_id'   => $session->id,
                            'note'           => 'Refund penghapusan sesi',
                            'created_at'     => now(),
                        ]);
                    }
                }
            }

            $session->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Sesi foto berhasil dihapus.',
        ]);
    }

    // ============================================================
    // PRIVATE
    // ============================================================

    private function transition(Request $request, string $uuid, string $newStatus, ?\Closure $afterTransition = null): JsonResponse
    {
        $session = $request->user()->sessions()->where('uuid', $uuid)->firstOrFail();

        if (!$session->canTransitionTo($newStatus)) {
            return response()->json([
                'success'    => false,
                'message'    => "Tidak dapat mengubah status sesi dari '{$session->status}' ke '{$newStatus}'.",
                'error_code' => 'INVALID_STATUS_TRANSITION',
                'data'       => ['current_status' => $session->status, 'requested_status' => $newStatus],
            ], 409);
        }

        $session->update(['status' => $newStatus]);

        if ($afterTransition) {
            $afterTransition($session->fresh());
        }

        return response()->json(['success' => true, 'data' => $session->fresh('photos', 'strip')]);
    }

    /**
     * POST /api/v1/sessions/sync
     *
     * Offline-to-Cloud Batch Sync Initialization.
     * Takes client session metadata and returns Cloudflare R2 presigned upload slots.
     */
    public function syncBatch(Request $request): JsonResponse
    {
        $request->validate([
            'client_session_id'   => 'required|string',
            'title'               => 'nullable|string|max:150',
            'mode'                => 'nullable|in:personal,event',
            'orientation'         => 'nullable|in:portrait,landscape,square',
            'location'            => 'nullable|string|max:150',
            'frame_index'         => 'nullable|integer',
            'frame_asset_path'    => 'nullable|string',
            'bg_asset_path'       => 'nullable|string',
            'mirrored_states'     => 'nullable|array',
            'filter_matrix'       => 'nullable|array',
            'people_in_photo'     => 'nullable|array',
            'event_uuid'          => 'nullable|string',
            'guest_voucher_code'  => 'nullable|string',
            'files'               => 'nullable|array',
        ]);

        $user = $request->user();
        $uuid = $request->client_session_id;

        // Resolve event & voucher if present
        $eventId = null;
        $guestVoucherId = null;

        if ($request->filled('guest_voucher_code')) {
            $voucher = EventGuestVoucher::where('voucher_code', strtolower(trim($request->guest_voucher_code)))->first();
            if ($voucher) {
                $guestVoucherId = $voucher->id;
                $eventId = $voucher->event_id;
            }
        } elseif ($request->filled('event_uuid')) {
            $event = Event::where('uuid', $request->event_uuid)->first();
            $eventId = $event?->id;
        }

        $session = PhotoSession::updateOrCreate(
            ['uuid' => $uuid],
            [
                'title'            => $request->title ?? 'Sesi Foto',
                'user_id'          => $user?->id ?? 1,
                'event_id'         => $eventId,
                'guest_voucher_id' => $guestVoucherId,
                'mode'             => $request->mode ?? ($eventId ? 'event' : 'personal'),
                'orientation'      => $request->orientation ?? 'portrait',
                'location'         => $request->location,
                'frame_asset_path' => $request->frame_asset_path,
                'bg_asset_path'    => $request->bg_asset_path,
                'mirrored_states'  => $request->mirrored_states,
                'filter_matrix'    => $request->filter_matrix,
                'people_in_photo'  => $request->people_in_photo,
                'status'           => 'active',
                'sync_status'      => 'syncing',
                'completed_at'     => now(),
            ]
        );

        $uploadSlots = [];
        $files = $request->files_meta ?? $request->files ?? [];

        foreach ($files as $file) {
            $type = $file['type'] ?? 'shot';
            $shotIndex = (int)($file['shot_index'] ?? 1);
            $mimeType = $file['mime_type'] ?? 'image/jpeg';
            $ext = str_contains($mimeType, 'png') ? 'png' : 'jpg';

            $storageKey = $type === 'strip'
                ? "strips/{$session->uuid}/photostrip_hd.{$ext}"
                : "photos/{$session->uuid}/shot_{$shotIndex}.{$ext}";

            try {
                $presigned = Storage::disk('r2')->temporaryUploadUrl($storageKey, now()->addMinutes(15), [
                    'ContentType' => $mimeType,
                ]);
                $uploadUrl = is_array($presigned) ? ($presigned['url'] ?? '') : (string)$presigned;
                $headers = is_array($presigned) ? ($presigned['headers'] ?? []) : ['Content-Type' => $mimeType];
            } catch (\Throwable $e) {
                $uploadUrl = url("/api/v1/sessions/{$session->uuid}/upload-slot?key=" . urlencode($storageKey));
                $headers = ['Content-Type' => $mimeType];
            }

            $uploadSlots[] = [
                'type'        => $type,
                'shot_index'  => $shotIndex,
                'storage_key' => $storageKey,
                'upload_url'  => $uploadUrl,
                'headers'     => $headers,
            ];
        }

        return response()->json([
            'success' => true,
            'message' => 'Sesi sinkronisasi disiapkan.',
            'data'    => [
                'session_uuid'       => $session->uuid,
                'session_code'       => $session->session_code,
                'status'             => $session->status,
                'expires_in_seconds' => 900,
                'upload_slots'       => $uploadSlots,
            ],
        ]);
    }

    /**
     * POST /api/v1/sessions/{uuid}/sync-complete
     */
    public function syncComplete(Request $request, string $uuid): JsonResponse
    {
        $session = PhotoSession::where('uuid', $uuid)->firstOrFail();
        $cdnBase = config('filesystems.disks.r2.url', env('APP_URL') . '/storage');

        // Create or update PhotoStrip record if strip was uploaded
        $stripStorageKey = "strips/{$session->uuid}/photostrip_hd.png";
        $stripUrl = rtrim($cdnBase, '/') . '/' . ltrim($stripStorageKey, '/');

        $strip = PhotoStrip::updateOrCreate(
            ['session_id' => $session->id],
            [
                'user_id'          => $session->user_id,
                'clean_url'        => $stripUrl,
                'watermarked_url'  => $stripUrl,
                'status'           => 'ready',
                'share_token'      => Str::random(64),
                'share_expires_at' => now()->addDays(7),
            ]
        );

        $session->update([
            'status'       => 'completed',
            'sync_status'  => 'synced',
            'completed_at' => now(),
        ]);

        if ($session->guest_voucher_id) {
            $voucher = $session->guestVoucher;
            if ($voucher) {
                $voucher->update([
                    'has_photo'     => true,
                    'last_photo_at' => now(),
                    'status'        => 'exhausted',
                ]);
                event(new GuestPhotoReady($voucher->fresh(), $session->fresh('photos', 'strip')));
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Sesi foto berhasil disinkronisasi ke Cloud SmileOn.',
            'data'    => [
                'session_uuid'     => $session->uuid,
                'status'           => 'completed',
                'sync_status'      => 'synced',
                'share_url'        => url('/api/v1/strips/share/' . $strip->share_token),
                'direct_strip_url' => $stripUrl,
                'completed_at'     => $session->completed_at?->toIso8601String(),
            ],
        ]);
    }

    /**
     * POST /api/v1/sessions/upload
     *
     * Fallback Multipart Upload endpoint for Photostrip and Photos.
     */
    public function uploadMultipart(Request $request): JsonResponse
    {
        $request->validate([
            'session_uuid' => 'nullable|string',
            'photostrip'   => 'nullable|file|mimes:jpeg,png,webp|max:20480',
            'title'        => 'nullable|string|max:150',
            'mode'         => 'nullable|in:personal,event',
        ]);

        try {
            $user = $request->user();
            $rawUuid = $request->session_uuid;

            $session = null;
            if ($rawUuid && Str::isUuid($rawUuid)) {
                $session = PhotoSession::where('uuid', $rawUuid)->first();
            }
            if (!$session && $rawUuid) {
                $session = PhotoSession::where('session_code', $rawUuid)->first();
            }
            if (!$session) {
                $session = PhotoSession::create([
                    'uuid'             => ($rawUuid && Str::isUuid($rawUuid)) ? $rawUuid : (string) Str::uuid(),
                    'session_code'     => 'SO-' . date('Y') . '-' . strtoupper(Str::random(4)),
                    'user_id'          => $user?->id ?? 1,
                    'mode'             => $request->mode ?? 'personal',
                    'status'           => 'completed',
                    'credits_required' => 0,
                    'photos_count'     => 4,
                    'completed_at'     => now(),
                ]);
            }

            $photostripUrl = null;
            if ($request->hasFile('photostrip')) {
                $path = $request->file('photostrip')->storePubliclyAs(
                    "strips/{$session->uuid}",
                    'photostrip_hd.' . $request->file('photostrip')->getClientOriginalExtension(),
                    'public'
                );
                $photostripUrl = Storage::disk('public')->url($path);

                $strip = PhotoStrip::where('session_id', $session->id)->first();
                if (!$strip) {
                    $strip = PhotoStrip::create([
                        'uuid'             => (string) Str::uuid(),
                        'session_id'       => $session->id,
                        'user_id'          => $session->user_id,
                        'storage_key'      => $path,
                        'clean_url'        => $photostripUrl,
                        'watermarked_url'  => $photostripUrl,
                        'status'           => 'ready',
                        'share_token'      => Str::random(64),
                        'share_expires_at' => now()->addDays(7),
                    ]);
                } else {
                    $strip->update([
                        'storage_key'      => $path,
                        'clean_url'        => $photostripUrl,
                        'watermarked_url'  => $photostripUrl,
                        'status'           => 'ready',
                    ]);
                }
            }

            // Upload multiple shots jika dilampirkan
            if ($request->hasFile('photos')) {
                foreach ($request->file('photos') as $idx => $photoFile) {
                    $shotNum = $idx + 1;
                    $ext = $photoFile->getClientOriginalExtension();
                    $path = $photoFile->storePubliclyAs(
                        "photos/{$session->uuid}",
                        "shot_{$shotNum}.{$ext}",
                        'public'
                    );
                    $url = Storage::disk('public')->url($path);
                    Photo::updateOrCreate(
                        ['session_id' => $session->id, 'shot_number' => $shotNum],
                        [
                            'user_id'         => $session->user_id,
                            'storage_key'     => $path,
                            'original_url'    => $url,
                            'watermarked_url' => $url,
                            'status'          => 'ready',
                        ]
                    );
                }
            }

            return response()->json([
                'success' => true,
                'message' => 'Upload sesi foto & photostrip berhasil.',
                'data'    => [
                    'session_uuid'     => $session->uuid,
                    'strip_uuid'       => isset($strip) ? $strip->uuid : null,
                    'photostrip_url'   => $photostripUrl,
                    'photos_count'     => $session->photos()->count(),
                    'share_url'        => isset($strip) ? url('/api/v1/strips/share/' . $strip->share_token) : null,
                ],
            ], 201);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error("[SessionController] Error uploadMultipart: " . $e->getMessage(), [
                'exception' => get_class($e),
                'trace'     => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal mengupload foto sesi: ' . $e->getMessage(),
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * POST /api/v1/sessions/{uuid}/upload-slot
     * Direct binary/file upload slot destination for Kiosk on VPS storage.
     */
    public function uploadSlot(Request $request, string $uuid): JsonResponse
    {
        $session = PhotoSession::where('uuid', $uuid)->firstOrFail();
        $key = $request->query('key') ?? "photos/{$session->uuid}/upload_" . time() . ".jpg";

        if ($request->hasFile('file')) {
            $path = $request->file('file')->storePubliclyAs(
                dirname($key),
                basename($key),
                'public'
            );
        } else {
            $raw = $request->getContent();
            Storage::disk('public')->put($key, $raw);
            $path = $key;
        }

        $url = Storage::disk('public')->url($path);

        if (str_contains($key, 'shot_')) {
            preg_match('/shot_(\d+)/', $key, $matches);
            $shotNumber = isset($matches[1]) ? (int)$matches[1] : 1;

            Photo::updateOrCreate(
                ['session_id' => $session->id, 'shot_number' => $shotNumber],
                [
                    'user_id'         => $session->user_id,
                    'storage_key'     => $path,
                    'original_url'    => $url,
                    'watermarked_url' => $url,
                    'status'          => 'ready',
                ]
            );
        }

        return response()->json([
            'success'     => true,
            'message'     => 'Slot upload tersimpan di VPS.',
            'storage_key' => $path,
            'url'         => $url,
        ]);
    }

    /**
     * POST /api/v1/sessions/{uuid}/export/drive
     * Export photostrip and shots of a session to Google Drive.
     */
    public function exportDrive(Request $request, string $uuid): JsonResponse
    {
        $session = PhotoSession::where('uuid', $uuid)->firstOrFail();

        if ($session->strip) {
            \App\Jobs\UploadPhotostripToDriveJob::dispatch($session->strip->id, config('filesystems.google.folder_id'));
        }

        return response()->json([
            'success' => true,
            'message' => 'Sinkronisasi sesi foto ke Google Drive dijadwalkan.',
            'data'    => ['session_uuid' => $session->uuid, 'status' => 'queued'],
        ]);
    }
}
