<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\Auth\AuthController;
use App\Http\Controllers\Api\V1\Admin\AdminUserController;
use App\Http\Controllers\Api\V1\Admin\AdminFrameController;
use App\Http\Controllers\Api\V1\Admin\AdminPaymentMethodController;
use App\Http\Controllers\Api\V1\Admin\AdminAuditLogController;
use App\Http\Controllers\Api\V1\Admin\AdminStorageSyncController;
use App\Http\Controllers\Api\V1\Admin\AdminReferralController;
use App\Http\Controllers\Api\V1\Frames\FrameController;
use App\Http\Controllers\Api\V1\Frames\FrameCategoryController;
use App\Http\Controllers\Api\V1\Events\EventController;
use App\Http\Controllers\Api\V1\Booths\BoothController;
use App\Http\Controllers\Api\V1\Booths\PersonalQrController;
use App\Http\Controllers\Api\V1\Sessions\SessionController;
use App\Http\Controllers\Api\V1\Photos\PhotoController;
use App\Http\Controllers\Api\V1\Photos\PhotoStripController;
use App\Http\Controllers\Api\V1\Orders\PackageController;
use App\Http\Controllers\Api\V1\Orders\OrderController;
use App\Http\Controllers\Api\V1\Orders\VoucherController;
use App\Http\Controllers\Api\V1\Loyalty\LoyaltyController;
use App\Http\Controllers\Api\V1\Loyalty\ReferralController;
use App\Http\Controllers\Api\V1\Notifications\NotificationController;
use App\Http\Controllers\Api\V1\Merchandise\MerchandiseController;
use App\Http\Controllers\Api\V1\Webhooks\PaymentWebhookController;
use App\Http\Controllers\Api\V1\Nft\NftController;

/*
|--------------------------------------------------------------------------
| API Health Check (no auth required)
|--------------------------------------------------------------------------
*/
Route::get('/health', [HealthController::class, 'check'])->name('api.health');
Route::get('/ping', [HealthController::class, 'ping'])->name('api.ping');

/*
|--------------------------------------------------------------------------
| API Version 1
|--------------------------------------------------------------------------
*/
Route::prefix('v1')->name('api.v1.')->group(function () {

    /*
    |----------------------------------------------------------------------
    | 4.1 Auth, Multi-Device Sessions & Profil Pengguna
    |----------------------------------------------------------------------
    */
    Route::prefix('auth')->name('auth.')->group(function () {
        Route::post('google', [AuthController::class, 'loginGoogle'])->name('google');
        Route::post('wallet', [AuthController::class, 'loginWallet'])->name('wallet');

        Route::middleware('auth:sanctum')->group(function () {
            Route::post('logout', [AuthController::class, 'logout'])->name('logout');
            Route::get('me', [AuthController::class, 'me'])->name('me');
            Route::patch('me', [AuthController::class, 'updateProfile'])->name('me.update');
            Route::get('sessions', [AuthController::class, 'sessions'])->name('sessions');
            Route::delete('sessions/other', [AuthController::class, 'revokeOtherSessions'])->name('sessions.other');
            Route::delete('sessions/{id}', [AuthController::class, 'revokeSession'])->name('sessions.revoke');
        });
    });

    /*
    |----------------------------------------------------------------------
    | 4.2 Admin Management, Moderation & Audit Trail
    |----------------------------------------------------------------------
    */
    Route::prefix('admin')->name('admin.')->middleware(['auth:sanctum', 'role:admin'])->group(function () {
        // Users
        Route::get('users', [AdminUserController::class, 'index'])->name('users.index');
        Route::delete('users/{uuid}', [AdminUserController::class, 'destroy'])->name('users.destroy');
        Route::post('users/{uuid}/restore', [AdminUserController::class, 'restore'])->name('users.restore');
        Route::patch('users/{uuid}/toggle-active', [AdminUserController::class, 'toggleActive'])->name('users.toggle-active');
        Route::post('users/{id}/credits/adjust', [AdminUserController::class, 'adjustCredits'])->name('users.credits.adjust');
        Route::get('users/{uuid}/activity-logs', [AdminUserController::class, 'activityLogs'])->name('users.activity-logs');

        // Audit & Activity Logs
        Route::get('audit-logs', [AdminAuditLogController::class, 'index'])->name('audit-logs.index');
        Route::get('activity-logs', [AdminAuditLogController::class, 'activityFeed'])->name('activity-logs.index');

        // Frame Moderation
        Route::get('frames/reports', [AdminFrameController::class, 'reports'])->name('frames.reports');
        Route::post('frames/{uuid}/reports/resolve', [AdminFrameController::class, 'resolveReport'])->name('frames.reports.resolve');
        Route::post('frames/{uuid}/promote', [AdminFrameController::class, 'promote'])->name('frames.promote');
        Route::delete('frames/{uuid}/demote', [AdminFrameController::class, 'demote'])->name('frames.demote');

        // Frame Categories
        Route::get('frame-categories', [FrameCategoryController::class, 'adminIndex'])->name('frame-categories.index');
        Route::post('frame-categories', [FrameCategoryController::class, 'store'])->name('frame-categories.store');
        Route::patch('frame-categories/{id}', [FrameCategoryController::class, 'update'])->name('frame-categories.update');
        Route::delete('frame-categories/{id}', [FrameCategoryController::class, 'destroy'])->name('frame-categories.destroy');

        // Payment Methods
        Route::get('payment-methods', [AdminPaymentMethodController::class, 'index'])->name('payment-methods.index');
        Route::post('payment-methods', [AdminPaymentMethodController::class, 'store'])->name('payment-methods.store');
        Route::patch('payment-methods/{id}', [AdminPaymentMethodController::class, 'update'])->name('payment-methods.update');
        Route::patch('payment-methods/{id}/toggle-active', [AdminPaymentMethodController::class, 'toggleActive'])->name('payment-methods.toggle-active');
        Route::delete('payment-methods/{id}', [AdminPaymentMethodController::class, 'destroy'])->name('payment-methods.destroy');

        // Referrals
        Route::get('referrals', [AdminReferralController::class, 'index'])->name('referrals.index');

        // Storage Syncs
        Route::get('storage-syncs', [AdminStorageSyncController::class, 'index'])->name('storage-syncs.index');
        Route::post('storage-syncs/{id}/retry', [AdminStorageSyncController::class, 'retry'])->name('storage-syncs.retry');
        Route::post('storage-syncs/retry-all', [AdminStorageSyncController::class, 'retryAll'])->name('storage-syncs.retry-all');

        // Web3 & NFT Admin
        Route::get('web3/sync-status', [OrderController::class, 'web3SyncStatus'])->name('web3.sync-status');

        // Merchandise Admin
        Route::patch('merchandise/orders/{uuid}/fulfill', [MerchandiseController::class, 'fulfill'])->name('merchandise.orders.fulfill');
    });

    /*
    |----------------------------------------------------------------------
    | 4.3 Frames & Marketplace
    |----------------------------------------------------------------------
    */
    Route::get('frames', [FrameController::class, 'index'])->name('frames.index');
    Route::get('frames/{uuid}', [FrameController::class, 'show'])->name('frames.show');
    Route::get('frame-categories', [FrameCategoryController::class, 'index'])->name('frame-categories.public');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('frames/{uuid}/report', [FrameController::class, 'report'])->name('frames.report');
        Route::post('user/frames/save', [FrameController::class, 'save'])->name('frames.save');
        Route::delete('user/frames/{uuid}/unsave', [FrameController::class, 'unsave'])->name('frames.unsave');
        Route::get('user/frames/saved', [FrameController::class, 'savedFrames'])->name('frames.saved');
    });

    /*
    |----------------------------------------------------------------------
    | 4.4 Events, QR Code Suite & Guest History
    |----------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('events', [EventController::class, 'index'])->name('events.index');
        Route::post('events', [EventController::class, 'store'])->name('events.store');
        Route::get('events/{uuid}', [EventController::class, 'show'])->name('events.show');
        Route::patch('events/{uuid}', [EventController::class, 'update'])->name('events.update');
        Route::delete('events/{uuid}', [EventController::class, 'destroy'])->name('events.destroy');
        Route::post('events/{uuid}/start', [EventController::class, 'start'])->name('events.start');
        Route::post('events/{uuid}/end', [EventController::class, 'end'])->name('events.end');
        Route::patch('events/{uuid}/watermark', [EventController::class, 'toggleWatermark'])->name('events.watermark');
        Route::get('events/{uuid}/frames', [EventController::class, 'frames'])->name('events.frames');
        Route::post('events/{uuid}/frames', [EventController::class, 'attachFrame'])->name('events.frames.attach');
        Route::post('events/{uuid}/frames/custom', [EventController::class, 'uploadCustomFrame'])->name('events.frames.custom');
        Route::delete('events/{uuid}/frames/{frame_id}', [EventController::class, 'detachFrame'])->name('events.frames.detach');
        Route::get('events/{uuid}/qr/invite', [EventController::class, 'inviteQr'])->name('events.qr.invite');
        Route::get('events/{uuid}/qr/host', [EventController::class, 'hostQr'])->name('events.qr.host');
        Route::get('events/join/{access_code}', [EventController::class, 'joinEvent'])->name('events.join');
        Route::get('user/events/joined', [EventController::class, 'joinedEvents'])->name('user.events.joined');
    });

    /*
    |----------------------------------------------------------------------
    | 4.5 Booth Hardware Security & Telemetry
    |----------------------------------------------------------------------
    */
    Route::prefix('booths')->name('booths.')->group(function () {
        // No auth — booth uses its own token system
        Route::post('pair', [BoothController::class, 'pair'])->name('pair');
        Route::post('token/refresh', [BoothController::class, 'refreshToken'])->name('token.refresh');
        Route::post('heartbeat', [BoothController::class, 'heartbeat'])->name('heartbeat');
        Route::get('health', [BoothController::class, 'health'])->name('health');
        Route::post('revoke', [BoothController::class, 'revoke'])->name('revoke');
        Route::get('config', [BoothController::class, 'config'])->name('config');
    });

    /*
    |----------------------------------------------------------------------
    | 4.6 Instant Personal Photobox QR Auth
    |----------------------------------------------------------------------
    */
    Route::prefix('personal')->name('personal.')->group(function () {
        Route::post('qr-auth/init', [PersonalQrController::class, 'init'])->name('qr-auth.init');
        Route::post('qr-auth/confirm', [PersonalQrController::class, 'confirm'])->middleware('auth:sanctum')->name('qr-auth.confirm');
        Route::get('qr-auth/status/{token}', [PersonalQrController::class, 'status'])->name('qr-auth.status');
    });

    /*
    |----------------------------------------------------------------------
    | 4.7 Sessions (Sesi Foto - State Machine)
    |----------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->prefix('sessions')->name('sessions.')->group(function () {
        Route::post('/', [SessionController::class, 'store'])->middleware('idempotency')->name('store');
        Route::get('/', [SessionController::class, 'index'])->name('index');
        Route::get('lookup/{session_code}', [SessionController::class, 'lookup'])->name('lookup');
        Route::get('{uuid}', [SessionController::class, 'show'])->name('show');
        Route::patch('{uuid}', [SessionController::class, 'update'])->name('update');
        Route::post('{uuid}/start-personal', [SessionController::class, 'startPersonal'])->middleware('idempotency')->name('start-personal');
        Route::post('{uuid}/start-event', [SessionController::class, 'startEvent'])->middleware('idempotency')->name('start-event');
        Route::post('{uuid}/complete', [SessionController::class, 'complete'])->middleware('idempotency')->name('complete');
        Route::post('{uuid}/cancel', [SessionController::class, 'cancel'])->middleware('idempotency')->name('cancel');
    });

    /*
    |----------------------------------------------------------------------
    | 4.8 Direct Cloudflare R2 Upload & Photo Management
    |----------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->group(function () {
        Route::prefix('photos')->name('photos.')->group(function () {
            Route::post('presigned-url', [PhotoController::class, 'presignedUrl'])->name('presigned-url');
            Route::post('complete-upload', [PhotoController::class, 'completeUpload'])->name('complete-upload');
            Route::get('recent', [PhotoController::class, 'recent'])->name('recent');
            Route::patch('{uuid}/watermark', [PhotoController::class, 'toggleWatermark'])->name('watermark');
            Route::delete('{uuid}', [PhotoController::class, 'destroy'])->name('destroy');
        });
        Route::get('sessions/{uuid}/photos', [PhotoController::class, 'sessionPhotos'])->name('sessions.photos');
    });

    /*
    |----------------------------------------------------------------------
    | 4.9 Photo Strips, Dimensi & Cetak Fisik
    |----------------------------------------------------------------------
    */
    // Public share link — no auth
    Route::get('strips/share/{token}', [PhotoStripController::class, 'shareLink'])->name('strips.share');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('sessions/{uuid}/strip', [PhotoStripController::class, 'generate'])->name('strips.generate');
        Route::get('strips/{uuid}', [PhotoStripController::class, 'show'])->name('strips.show');
        Route::patch('strips/{uuid}/watermark', [PhotoStripController::class, 'toggleWatermark'])->name('strips.watermark');
        Route::post('strips/{uuid}/print', [PhotoStripController::class, 'print'])->name('strips.print');
        Route::post('strips/{uuid}/share', [PhotoStripController::class, 'createShareLink'])->name('strips.share.create');
        Route::post('strips/{uuid}/export/email', [PhotoStripController::class, 'exportEmail'])->name('strips.export.email');
        Route::post('strips/{uuid}/export/drive', [PhotoStripController::class, 'exportDrive'])->name('strips.export.drive');
    });

    /*
    |----------------------------------------------------------------------
    | 4.10 Packages, Orders & Dynamic Payment Channels
    |----------------------------------------------------------------------
    */
    Route::get('packages', [PackageController::class, 'index'])->name('packages.index');
    Route::get('packages/{id}', [PackageController::class, 'show'])->name('packages.show');
    Route::get('payment-methods', [AdminPaymentMethodController::class, 'publicIndex'])->name('payment-methods.public');
    Route::get('web3/contracts', [OrderController::class, 'web3Contracts'])->name('web3.contracts');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('orders', [OrderController::class, 'store'])->middleware('idempotency')->name('orders.store');
        Route::get('orders', [OrderController::class, 'index'])->name('orders.index');
        Route::get('user/orders/latest', [OrderController::class, 'latest'])->name('orders.latest');
        Route::get('orders/{uuid}', [OrderController::class, 'show'])->name('orders.show');
        Route::post('orders/{uuid}/verify-payment', [OrderController::class, 'verifyPayment'])->name('orders.verify-payment');
        Route::get('orders/{uuid}/onchain-status', [OrderController::class, 'onchainStatus'])->name('orders.onchain-status');
    });

    /*
    |----------------------------------------------------------------------
    | Payment Webhooks (no Sanctum auth — verified via HMAC signature)
    |----------------------------------------------------------------------
    */
    Route::post('webhooks/payment/monad', [PaymentWebhookController::class, 'monad'])->name('webhooks.payment.monad');
    Route::post('webhooks/payment/{provider}', [PaymentWebhookController::class, 'receive'])->name('webhooks.payment');

    /*
    |----------------------------------------------------------------------
    | 4.11 Vouchers & Diskon
    |----------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('vouchers/validate', [VoucherController::class, 'validate'])->name('vouchers.validate');
        Route::post('vouchers/redeem', [VoucherController::class, 'redeem'])->middleware('idempotency')->name('vouchers.redeem');
        Route::get('user/credits', [VoucherController::class, 'credits'])->name('user.credits');
        Route::get('user/credits/ledger', [VoucherController::class, 'creditLedger'])->name('user.credits.ledger');
    });

    /*
    |----------------------------------------------------------------------
    | 4.12 Loyalty Points & Rewards Gamification
    |----------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->prefix('loyalty')->name('loyalty.')->group(function () {
        Route::get('points', [LoyaltyController::class, 'points'])->name('points');
        Route::get('history', [LoyaltyController::class, 'history'])->name('history');
        Route::get('rewards', [LoyaltyController::class, 'rewards'])->name('rewards');
        Route::post('rewards/{id}/redeem', [LoyaltyController::class, 'redeem'])->middleware('idempotency')->name('rewards.redeem');
        Route::post('check-in', [LoyaltyController::class, 'checkIn'])->name('check-in');
    });

    /*
    |----------------------------------------------------------------------
    | 4.13 Notifications & Activity Logs
    |----------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('notifications', [NotificationController::class, 'index'])->name('notifications.index');
        Route::get('notifications/unread-count', [NotificationController::class, 'unreadCount'])->name('notifications.unread-count');
        Route::patch('notifications/{id}/read', [NotificationController::class, 'markRead'])->name('notifications.read');
        Route::post('notifications/read-all', [NotificationController::class, 'markAllRead'])->name('notifications.read-all');
        Route::delete('notifications/{id}', [NotificationController::class, 'destroy'])->name('notifications.destroy');
        Route::get('user/activity-logs', [NotificationController::class, 'activityLogs'])->name('user.activity-logs');
    });

    /*
    |----------------------------------------------------------------------
    | 4.14 Referral System
    |----------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('user/referral', [ReferralController::class, 'show'])->name('referral.show');
        Route::post('user/referral/claim', [ReferralController::class, 'claim'])->middleware('idempotency')->name('referral.claim');
    });

    /*
    |----------------------------------------------------------------------
    | 4.15 Online Photo Printing & Custom Merchandise
    |----------------------------------------------------------------------
    */
    Route::get('merchandise/products', [MerchandiseController::class, 'products'])->name('merchandise.products');
    Route::get('merchandise/products/{slug}', [MerchandiseController::class, 'productDetail'])->name('merchandise.products.show');

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('user/shipping-addresses', [MerchandiseController::class, 'addresses'])->name('user.shipping-addresses');
        Route::post('user/shipping-addresses', [MerchandiseController::class, 'storeAddress'])->name('user.shipping-addresses.store');
        Route::patch('user/shipping-addresses/{id}', [MerchandiseController::class, 'updateAddress'])->name('user.shipping-addresses.update');
        Route::delete('user/shipping-addresses/{id}', [MerchandiseController::class, 'destroyAddress'])->name('user.shipping-addresses.destroy');
        Route::post('merchandise/calculate-shipping', [MerchandiseController::class, 'calculateShipping'])->name('merchandise.calculate-shipping');
        Route::post('merchandise/orders', [MerchandiseController::class, 'placeOrder'])->middleware('idempotency')->name('merchandise.orders.store');
        Route::get('merchandise/orders', [MerchandiseController::class, 'orders'])->name('merchandise.orders.my');
    });

    /*
    |----------------------------------------------------------------------
    | 4.16 NFT & Digital Collectibles (Monad Blockchain)
    |----------------------------------------------------------------------
    */
    Route::get('collectibles/{uuid}', [NftController::class, 'show'])->name('collectibles.show');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('nft/mint', [NftController::class, 'mint'])->middleware('idempotency')->name('nft.mint');
        Route::get('user/collectibles', [NftController::class, 'myCollectibles'])->name('user.collectibles');
        Route::post('events/{uuid}/verify-nft-access', [NftController::class, 'verifyAccess'])->name('events.verify-nft-access');
        Route::post('events/{uuid}/claim-nft-perk', [NftController::class, 'claimPerk'])->middleware('idempotency')->name('events.claim-nft-perk');
    });
});

