<?php

namespace App\Services\Notification;

use App\Models\Event;
use App\Models\EventGuestVoucher;
use App\Models\PhotoSession;
use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    protected ?string $serverKey;
    protected ?string $projectId;

    public function __construct()
    {
        $this->serverKey = config('services.fcm.server_key') ?: env('FCM_SERVER_KEY');
        $this->projectId = config('services.fcm.project_id') ?: env('FCM_PROJECT_ID', 'smileon-hackathon');
    }

    /**
     * Cek apakah kredensial FCM server key sudah disetel.
     */
    public function isConfigured(): bool
    {
        return !empty($this->serverKey);
    }

    /**
     * Kirim push notification ke FCM token device secara langsung.
     */
    public function sendToToken(string $fcmToken, string $title, string $body, array $data = []): bool
    {
        if (empty($fcmToken)) {
            return false;
        }

        if (!$this->isConfigured()) {
            Log::info("FcmService: FCM_SERVER_KEY belum diisi di .env. Notifikasi disimulasikan.", [
                'token' => substr($fcmToken, 0, 15) . '...',
                'title' => $title,
                'body'  => $body,
            ]);
            return true;
        }

        try {
            $payload = [
                'to'           => $fcmToken,
                'priority'     => 'high',
                'notification' => [
                    'title'        => $title,
                    'body'         => $body,
                    'sound'        => 'default',
                    'badge'        => 1,
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                ],
                'data'         => array_merge($data, [
                    'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                    'timestamp'    => now()->toIso8601String(),
                ]),
            ];

            $response = Http::withHeaders([
                'Authorization' => 'key=' . $this->serverKey,
                'Content-Type'  => 'application/json',
            ])->timeout(10)->post('https://fcm.googleapis.com/fcm/send', $payload);

            if ($response->successful()) {
                Log::info("FcmService: Berhasil mengirim push notification ke token.", [
                    'title' => $title,
                ]);
                return true;
            }

            Log::warning("FcmService: Gagal mengirim push notification.", [
                'status'   => $response->status(),
                'response' => $response->body(),
            ]);
            return false;
        } catch (\Throwable $e) {
            Log::error("FcmService Exception: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Kirim push notification ke User terdaftar (sekaligus catat ke tabel user_notifications).
     */
    public function sendToUser(User $user, string $title, string $body, array $data = [], string $type = 'general'): bool
    {
        // 1. Selalu simpan ke database UserNotification agar tampil di inbox aplikasi
        UserNotification::create([
            'user_id'    => $user->id,
            'type'       => $type,
            'title'      => $title,
            'body'       => $body,
            'icon'       => $data['icon'] ?? 'camera',
            'action_url' => $data['action_url'] ?? null,
            'metadata'   => $data,
            'read_at'    => null,
        ]);

        // 2. Jika user memiliki FCM token, kirim push notification ke HP-nya
        if ($user->fcm_token) {
            return $this->sendToToken($user->fcm_token, $title, $body, $data);
        }

        return true;
    }

    /**
     * Notifikasi push otomatis ketika sesi foto / photostrip selesai diproses.
     */
    public function sendPhotoReady(PhotoSession $session): void
    {
        $session->loadMissing('user', 'strip', 'event');

        $title = "Foto Kamu Sudah Siap! 📸✨";
        $body = "Photostrip untuk sesi '{$session->title}' ({$session->session_code}) siap dilihat dan diunduh.";

        $data = [
            'type'           => 'photo_ready',
            'session_uuid'   => $session->uuid,
            'session_code'   => $session->session_code,
            'photostrip_url' => $session->strip?->clean_url ?? $session->strip?->watermarked_url,
            'action_url'     => "/sessions/{$session->uuid}",
        ];

        if ($session->user) {
            $this->sendToUser($session->user, $title, $body, $data, 'photo_ready');
        }
    }

    /**
     * Notifikasi push undangan / split voucher untuk tamu acara.
     */
    public function sendGuestInvite(EventGuestVoucher $voucher, ?string $fcmToken = null): void
    {
        $event = $voucher->event;
        $title = "Tiket Foto Acara: {$event->name} 🎟️";
        $body = "Halo {$voucher->guest_name}! Kamu mendapatkan {$voucher->quota_limit} kuota sesi foto gratis di {$event->name}.";

        $data = [
            'type'         => 'event_guest_voucher',
            'voucher_code' => $voucher->voucher_code,
            'event_uuid'   => $event->uuid,
            'invite_url'   => "https://smileon-dapps.my.id/events/join/{$event->access_code}",
            'action_url'   => "/events/{$event->uuid}",
        ];

        if ($fcmToken) {
            $this->sendToToken($fcmToken, $title, $body, $data);
        }
    }

    /**
     * Notifikasi push pengingat acara (Event Reminder).
     */
    public function sendEventReminder(Event $event, User $user): void
    {
        $title = "Acara Dimulai Hari Ini: {$event->name} ⏰";
        $body = "Acara di {$event->venue} telah dibuka. Kunjungi booth SmileOn untuk berfoto bersama!";

        $data = [
            'type'       => 'event_reminder',
            'event_uuid' => $event->uuid,
            'venue'      => $event->venue,
            'action_url' => "/events/{$event->uuid}",
        ];

        $this->sendToUser($user, $title, $body, $data, 'event_reminder');
    }
}
