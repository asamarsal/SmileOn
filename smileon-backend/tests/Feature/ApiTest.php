<?php

namespace Tests\Feature;

use App\Models\Event;
use App\Models\FrameCategory;
use App\Models\Frame;
use App\Models\LoyaltyAccount;
use App\Models\Package;
use App\Models\PersonalQrToken;
use App\Models\PhotoCredit;
use App\Models\PhotoSession;
use App\Models\User;
use App\Models\UserShippingAddress;
use App\Models\Voucher;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use PHPUnit\Framework\Attributes\Test;
use Tests\TestCase;

/**
 * Comprehensive API Feature Tests for SmileOn Backend.
 * Covers plan-backend-laravel.md Fase 1–9.
 */
class ApiTest extends TestCase
{
    use RefreshDatabase;

    // ──────────────────────────────────────────────────────────────
    // HELPERS
    // ──────────────────────────────────────────────────────────────

    private function makeUser(array $attrs = []): array
    {
        $user  = User::factory()->create(array_merge(['is_active' => true, 'role' => 'user'], $attrs));
        $token = $user->createToken('test')->plainTextToken;
        return [$user, $token];
    }

    private function makeAdmin(): array
    {
        $user  = User::factory()->create(['is_active' => true, 'role' => 'admin']);
        $token = $user->createToken('test')->plainTextToken;
        return [$user, $token];
    }

    private function iKey(): array
    {
        return ['Idempotency-Key' => (string) Str::uuid()];
    }

    // ──────────────────────────────────────────────────────────────
    // HEALTH CHECK
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function health_check_returns_ok(): void
    {
        $this->getJson('/api/health')->assertOk()->assertJsonPath('status', 'ok');
    }

    #[Test]
    public function ping_returns_pong(): void
    {
        $this->getJson('/api/ping')->assertOk()->assertJsonPath('message', 'pong');
    }

    // ──────────────────────────────────────────────────────────────
    // AUTH
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function google_auth_with_invalid_token_returns_401(): void
    {
        $this->postJson('/api/v1/auth/google', ['id_token' => 'bad-token'])
            ->assertStatus(401)->assertJsonPath('success', false);
    }

    #[Test]
    public function wallet_auth_with_invalid_signature_returns_403(): void
    {
        $this->postJson('/api/v1/auth/wallet', [
            'wallet_address' => '0x' . str_repeat('1', 40),
            'signature'      => 'bad-sig',
            'message'        => 'Sign in to SmileOn: ' . now()->timestamp,
        ])->assertStatus(403)->assertJsonPath('success', false);
    }

    #[Test]
    public function unauthenticated_request_to_protected_route_returns_401(): void
    {
        $this->getJson('/api/v1/auth/me')->assertUnauthorized();
    }

    #[Test]
    public function authenticated_user_can_get_profile(): void
    {
        [$user, $token] = $this->makeUser(['email' => 'u@smileon.app']);

        $this->withToken($token)->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.email', 'u@smileon.app');
    }

    #[Test]
    public function authenticated_user_can_update_profile(): void
    {
        [$user, $token] = $this->makeUser();

        $this->withToken($token)->patchJson('/api/v1/auth/me', ['name' => 'New Name'])
            ->assertOk()->assertJsonPath('success', true);

        $this->assertDatabaseHas('users', ['id' => $user->id, 'name' => 'New Name']);
    }

    #[Test]
    public function authenticated_user_can_list_sessions(): void
    {
        [$user, $token] = $this->makeUser();

        $this->withToken($token)->getJson('/api/v1/auth/sessions')
            ->assertOk()->assertJsonPath('success', true);
    }

    #[Test]
    public function user_can_logout(): void
    {
        [$user, $token] = $this->makeUser();

        $this->withToken($token)->postJson('/api/v1/auth/logout')
            ->assertOk()->assertJsonPath('success', true);
    }

    // ──────────────────────────────────────────────────────────────
    // ADMIN ACCESS CONTROL
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function non_admin_is_forbidden_from_admin_routes(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)->getJson('/api/v1/admin/users')->assertForbidden();
    }

    #[Test]
    public function admin_can_list_users(): void
    {
        [$admin, $token] = $this->makeAdmin();
        $this->withToken($token)->getJson('/api/v1/admin/users')
            ->assertOk()->assertJsonPath('success', true);
    }

    #[Test]
    public function admin_can_view_audit_logs(): void
    {
        [$admin, $token] = $this->makeAdmin();
        $this->withToken($token)->getJson('/api/v1/admin/audit-logs')
            ->assertOk()->assertJsonPath('success', true);
    }

    #[Test]
    public function admin_can_create_frame_category(): void
    {
        [$admin, $token] = $this->makeAdmin();

        $this->withToken($token)->postJson('/api/v1/admin/frame-categories', [
            'name' => 'Birthday',
            'slug' => 'birthday',
        ])->assertCreated()->assertJsonPath('success', true);

        $this->assertDatabaseHas('frame_categories', ['slug' => 'birthday']);
    }

    // ──────────────────────────────────────────────────────────────
    // FRAMES & MARKETPLACE
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function public_can_list_frame_categories(): void
    {
        FrameCategory::create(['name' => 'Wedding', 'slug' => 'wedding', 'is_active' => true]);
        $this->getJson('/api/v1/frame-categories')->assertOk()->assertJsonPath('success', true);
    }

    #[Test]
    public function public_can_list_frames(): void
    {
        $this->getJson('/api/v1/frames')->assertOk()->assertJsonPath('success', true);
    }

    #[Test]
    public function user_can_save_and_unsave_a_frame(): void
    {
        [$user, $token] = $this->makeUser();
        $category = FrameCategory::create(['name' => 'General', 'slug' => 'general', 'is_active' => true]);
        $frame    = Frame::create([
            'uuid'          => (string) Str::uuid(),
            'title'         => 'Test Frame',
            'slug'          => 'test-frame',
            'category_id'   => $category->id,
            'orientation'   => 'portrait',
            'thumbnail_url' => 'http://example.com/thumb.jpg',
            'frame_url'     => 'http://example.com/frame.png',
            'status'        => 'active',
            'is_free'       => true,
            'creator_id'    => $user->id,
        ]);

        $this->withToken($token)->postJson('/api/v1/user/frames/save', ['frame_uuid' => $frame->uuid])
            ->assertStatus(201)->assertJsonPath('success', true);

        $this->withToken($token)->deleteJson('/api/v1/user/frames/' . $frame->uuid . '/unsave')
            ->assertOk()->assertJsonPath('success', true);
    }

    // ──────────────────────────────────────────────────────────────
    // PACKAGES & PAYMENT METHODS
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function public_can_list_packages(): void
    {
        Package::create(['name' => 'Starter', 'credits_amount' => 5, 'price' => 15000, 'is_active' => true]);
        $this->getJson('/api/v1/packages')->assertOk()->assertJsonPath('success', true);
    }

    #[Test]
    public function public_can_get_package_detail(): void
    {
        $pkg = Package::create(['name' => 'Pro', 'credits_amount' => 20, 'price' => 50000, 'is_active' => true]);
        $this->getJson("/api/v1/packages/{$pkg->id}")->assertOk()->assertJsonPath('success', true);
    }

    #[Test]
    public function public_can_list_payment_methods(): void
    {
        $this->getJson('/api/v1/payment-methods')->assertOk()->assertJsonPath('success', true);
    }

    // ──────────────────────────────────────────────────────────────
    // VOUCHERS
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function user_can_validate_a_valid_voucher(): void
    {
        [$user, $token] = $this->makeUser();
        Voucher::create(['code' => 'TESTV001', 'name' => 'T', 'type' => 'credit_bonus', 'value' => 3, 'is_active' => true, 'max_uses' => 100, 'used_count' => 0]);

        $this->withToken($token)->postJson('/api/v1/vouchers/validate', ['code' => 'TESTV001'])
            ->assertOk()->assertJsonPath('success', true)->assertJsonPath('data.code', 'TESTV001');
    }

    #[Test]
    public function user_can_redeem_credit_bonus_voucher(): void
    {
        [$user, $token] = $this->makeUser();
        PhotoCredit::create(['user_id' => $user->id, 'balance' => 0]);
        Voucher::create(['code' => 'REDEEM01', 'name' => 'R', 'type' => 'credit_bonus', 'value' => 5, 'is_active' => true, 'max_uses' => 10, 'used_count' => 0]);

        $this->withToken($token)
            ->postJson('/api/v1/vouchers/redeem', ['code' => 'REDEEM01'], $this->iKey())
            ->assertOk()->assertJsonPath('success', true);

        $this->assertDatabaseHas('photo_credits', ['user_id' => $user->id, 'balance' => 5]);
    }

    #[Test]
    public function redeeming_nonexistent_voucher_returns_422(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)
            ->postJson('/api/v1/vouchers/redeem', ['code' => 'NOTEXIST'], $this->iKey())
            ->assertStatus(422)->assertJsonPath('success', false);
    }

    #[Test]
    public function user_can_get_credit_balance(): void
    {
        [$user, $token] = $this->makeUser();
        PhotoCredit::create(['user_id' => $user->id, 'balance' => 10, 'reserved_balance' => 2]);

        $this->withToken($token)->getJson('/api/v1/user/credits')
            ->assertOk()
            ->assertJsonPath('data.balance', 10)
            ->assertJsonPath('data.reserved_balance', 2);
    }

    #[Test]
    public function user_can_get_credit_ledger(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)->getJson('/api/v1/user/credits/ledger')
            ->assertOk()->assertJsonPath('success', true);
    }

    // ──────────────────────────────────────────────────────────────
    // LOYALTY / SMILEPOINTS
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function user_can_view_loyalty_points(): void
    {
        [$user, $token] = $this->makeUser();
        LoyaltyAccount::create(['user_id' => $user->id, 'points_balance' => 250, 'tier' => 'Bronze']);

        $this->withToken($token)->getJson('/api/v1/loyalty/points')
            ->assertOk()->assertJsonPath('data.points_balance', 250)->assertJsonPath('data.tier', 'Bronze');
    }

    #[Test]
    public function user_can_do_daily_check_in(): void
    {
        [$user, $token] = $this->makeUser();
        LoyaltyAccount::create(['user_id' => $user->id, 'points_balance' => 0, 'streak_days' => 0]);

        $this->withToken($token)->postJson('/api/v1/loyalty/check-in')
            ->assertOk()->assertJsonPath('success', true);

        $account = LoyaltyAccount::where('user_id', $user->id)->first();
        $this->assertGreaterThan(0, $account->points_balance);
    }

    #[Test]
    public function double_check_in_same_day_is_rejected(): void
    {
        [$user, $token] = $this->makeUser();
        LoyaltyAccount::create(['user_id' => $user->id, 'points_balance' => 10, 'streak_days' => 1, 'last_check_in_date' => now()->toDateString()]);

        $this->withToken($token)->postJson('/api/v1/loyalty/check-in')
            ->assertStatus(409)->assertJsonPath('error_code', 'ALREADY_CHECKED_IN');
    }

    #[Test]
    public function user_can_view_loyalty_rewards(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)->getJson('/api/v1/loyalty/rewards')
            ->assertOk()->assertJsonPath('success', true);
    }

    #[Test]
    public function user_can_view_loyalty_history(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)->getJson('/api/v1/loyalty/history')
            ->assertOk()->assertJsonPath('success', true);
    }

    // ──────────────────────────────────────────────────────────────
    // PERSONAL QR
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function booth_can_init_personal_qr(): void
    {
        $this->postJson('/api/v1/personal/qr-auth/init')
            ->assertOk()->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['token', 'qr_payload', 'expires_at', 'ttl_seconds']]);
    }

    #[Test]
    public function pending_qr_token_returns_pending_status(): void
    {
        PersonalQrToken::create(['token' => 'abc123', 'status' => 'pending', 'expires_at' => now()->addMinutes(2)]);
        $this->getJson('/api/v1/personal/qr-auth/status/abc123')
            ->assertOk()->assertJsonPath('data.status', 'pending');
    }

    #[Test]
    public function expired_qr_token_returns_expired(): void
    {
        PersonalQrToken::create(['token' => 'expired123', 'status' => 'pending', 'expires_at' => now()->subMinutes(5)]);
        $this->getJson('/api/v1/personal/qr-auth/status/expired123')
            ->assertOk()->assertJsonPath('data.status', 'expired');
    }

    #[Test]
    public function missing_qr_token_returns_404(): void
    {
        $this->getJson('/api/v1/personal/qr-auth/status/does-not-exist')->assertNotFound();
    }

    // ──────────────────────────────────────────────────────────────
    // NOTIFICATIONS
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function user_can_list_notifications(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)->getJson('/api/v1/notifications')
            ->assertOk()->assertJsonPath('success', true);
    }

    #[Test]
    public function user_can_get_unread_count(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)->getJson('/api/v1/notifications/unread-count')
            ->assertOk()->assertJsonPath('data.unread_count', 0);
    }

    #[Test]
    public function user_can_mark_all_notifications_read(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)->postJson('/api/v1/notifications/read-all')
            ->assertOk()->assertJsonPath('success', true);
    }

    #[Test]
    public function user_can_view_activity_logs(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)->getJson('/api/v1/user/activity-logs')
            ->assertOk()->assertJsonPath('success', true);
    }

    // ──────────────────────────────────────────────────────────────
    // REFERRAL
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function user_can_get_referral_info(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)->getJson('/api/v1/user/referral')
            ->assertOk()->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['referral_code', 'share_url', 'total_referred']]);
    }

    #[Test]
    public function claiming_referral_with_none_pending_returns_422(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)
            ->postJson('/api/v1/user/referral/claim', [], $this->iKey())
            ->assertStatus(422)->assertJsonPath('error_code', 'NO_PENDING_REFERRALS');
    }

    // ──────────────────────────────────────────────────────────────
    // MERCHANDISE
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function public_can_view_product_catalog(): void
    {
        $response = $this->getJson('/api/v1/merchandise/products');
        $response->assertOk()->assertJsonPath('success', true);
        $this->assertNotEmpty($response->json('data'));
    }

    #[Test]
    public function public_can_view_product_detail(): void
    {
        $this->getJson('/api/v1/merchandise/products/polaroid-4x6')
            ->assertOk()->assertJsonPath('success', true);
    }

    #[Test]
    public function unknown_product_returns_404(): void
    {
        $this->getJson('/api/v1/merchandise/products/nonexistent-product')->assertNotFound();
    }

    #[Test]
    public function user_can_add_shipping_address(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)->postJson('/api/v1/user/shipping-addresses', [
            'label'          => 'Rumah',
            'recipient_name' => 'Budi Santoso',
            'phone_number'   => '081234567890',
            'address_line1'  => 'Jl. Mawar No. 1',
            'district'       => 'Menteng',
            'city'           => 'Jakarta Pusat',
            'province'       => 'DKI Jakarta',
            'postal_code'    => '10310',
        ])->assertCreated()->assertJsonPath('success', true);

        $this->assertDatabaseHas('user_shipping_addresses', ['user_id' => $user->id, 'city' => 'Jakarta Pusat']);
    }

    #[Test]
    public function user_can_list_shipping_addresses(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)->getJson('/api/v1/user/shipping-addresses')
            ->assertOk()->assertJsonPath('success', true);
    }

    // ──────────────────────────────────────────────────────────────
    // WEBHOOKS
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function webhook_accepts_midtrans(): void
    {
        $this->postJson('/api/v1/webhooks/payment/midtrans', [
            'transaction_id'     => 'TRX-' . Str::random(10),
            'transaction_status' => 'settlement',
            'order_id'           => 'ORD-001',
            'gross_amount'       => '50000',
            'signature_key'      => 'local-sig',
        ])->assertOk()->assertJsonPath('status', 'ok');
    }

    #[Test]
    public function webhook_accepts_xendit(): void
    {
        $this->postJson('/api/v1/webhooks/payment/xendit', [
            'id'          => 'EVT-' . Str::random(10),
            'external_id' => 'ORD-002',
            'status'      => 'PAID',
            'amount'      => 50000,
        ])->assertOk()->assertJsonPath('status', 'ok');
    }

    #[Test]
    public function webhook_rejects_unknown_provider(): void
    {
        $this->postJson('/api/v1/webhooks/payment/unknown_provider', [])->assertStatus(400);
    }

    #[Test]
    public function monad_envio_webhook_is_accepted(): void
    {
        $this->postJson('/api/v1/webhooks/payment/monad', [
            'event_name'   => 'PaymentReceived',
            'tx_hash'      => '0x' . str_repeat('a', 64),
            'block_number' => 12345,
            'chain_id'     => 10143,
            'from_address' => '0x' . str_repeat('b', 40),
            'amount'       => '50000000000000000000',
            'order_ref'    => null,
        ])->assertOk()->assertJsonPath('status', 'ok');
    }

    #[Test]
    public function duplicate_monad_webhook_is_deduplicated(): void
    {
        $txHash  = '0x' . str_repeat('c', 64);
        $payload = [
            'event_name'   => 'PaymentReceived',
            'tx_hash'      => $txHash,
            'block_number' => 12346,
            'chain_id'     => 10143,
            'from_address' => '0x' . str_repeat('d', 40),
            'amount'       => '1000',
        ];

        $this->postJson('/api/v1/webhooks/payment/monad', $payload)->assertOk();
        $this->postJson('/api/v1/webhooks/payment/monad', $payload)
            ->assertOk()->assertJsonPath('message', 'Already processed.');
    }

    // ──────────────────────────────────────────────────────────────
    // NFT
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function user_can_list_their_collectibles(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)->getJson('/api/v1/user/collectibles')
            ->assertOk()->assertJsonPath('success', true);
    }

    #[Test]
    public function missing_collectible_returns_404(): void
    {
        $this->getJson('/api/v1/collectibles/' . Str::uuid())->assertNotFound();
    }

    // ──────────────────────────────────────────────────────────────
    // SESSIONS (State Machine)
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function user_with_no_credits_cannot_create_session(): void
    {
        [$user, $token] = $this->makeUser();

        $this->withToken($token)
            ->postJson('/api/v1/sessions', ['credits_required' => 1, 'orientation' => 'portrait'], $this->iKey())
            ->assertStatus(402)->assertJsonPath('error_code', 'INSUFFICIENT_CREDITS');
    }

    #[Test]
    public function user_with_credits_can_create_session(): void
    {
        [$user, $token] = $this->makeUser();
        PhotoCredit::create(['user_id' => $user->id, 'balance' => 10, 'reserved_balance' => 0]);

        $this->withToken($token)
            ->postJson('/api/v1/sessions', ['credits_required' => 1, 'orientation' => 'portrait'], $this->iKey())
            ->assertCreated()->assertJsonPath('success', true);
    }

    #[Test]
    public function user_can_list_their_sessions(): void
    {
        [$user, $token] = $this->makeUser();
        $this->withToken($token)->getJson('/api/v1/sessions')
            ->assertOk()->assertJsonPath('success', true);
    }

    #[Test]
    public function user_can_cancel_an_active_session(): void
    {
        [$user, $token] = $this->makeUser();
        PhotoCredit::create(['user_id' => $user->id, 'balance' => 5, 'reserved_balance' => 1]);

        $session = PhotoSession::create([
            'uuid'             => (string) Str::uuid(),
            'user_id'          => $user->id,
            'session_code'     => 'SO-' . now()->year . '-TEST',
            'status'           => 'active',
            'credits_required' => 1,
            'orientation'      => 'portrait',
        ]);

        $this->withToken($token)
            ->postJson("/api/v1/sessions/{$session->uuid}/cancel", [], $this->iKey())
            ->assertOk()->assertJsonPath('success', true);

        $this->assertDatabaseHas('photo_sessions', ['id' => $session->id, 'status' => 'cancelled']);
    }

    // ──────────────────────────────────────────────────────────────
    // IDEMPOTENCY
    // ──────────────────────────────────────────────────────────────

    #[Test]
    public function same_idempotency_key_returns_cached_response(): void
    {
        [$user, $token] = $this->makeUser();
        PhotoCredit::create(['user_id' => $user->id, 'balance' => 0]);
        Voucher::create(['code' => 'IDEM001', 'name' => 'I', 'type' => 'credit_bonus', 'value' => 3, 'is_active' => true, 'max_uses' => 5, 'used_count' => 0]);

        $key = (string) Str::uuid();

        $this->withToken($token)
            ->postJson('/api/v1/vouchers/redeem', ['code' => 'IDEM001'], ['Idempotency-Key' => $key])
            ->assertOk();

        // Second request with same key — response cached, balance not charged again
        $this->withToken($token)
            ->postJson('/api/v1/vouchers/redeem', ['code' => 'IDEM001'], ['Idempotency-Key' => $key])
            ->assertOk();

        // Balance must be 3 (not 6)
        $this->assertDatabaseHas('photo_credits', ['user_id' => $user->id, 'balance' => 3]);
    }
}
