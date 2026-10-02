<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ============================================================
        // PACKAGES — Credit packages for purchase
        // ============================================================
        Schema::create('packages', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
            $table->string('category', 50)->default('personal'); // personal | event | bundle
            $table->unsignedInteger('credits_amount');
            $table->decimal('price', 15, 2);
            $table->string('currency', 10)->default('IDR');
            $table->string('badge_label', 30)->nullable(); // e.g. "POPULAR", "BEST VALUE"
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        // ============================================================
        // ORDERS — Purchase orders
        // ============================================================
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('order_number', 30)->unique(); // SO-ORD-XXXXXX
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('payment_method_id')->nullable()->constrained('payment_methods')->nullOnDelete();
            $table->foreignId('voucher_id')->nullable()->constrained('vouchers')->nullOnDelete();
            $table->decimal('subtotal', 15, 2)->default(0);
            $table->decimal('discount_amount', 15, 2)->default(0);
            $table->decimal('admin_fee', 15, 2)->default(0);
            $table->decimal('total', 15, 2)->default(0);
            $table->string('currency', 10)->default('IDR');
            // status: pending | paid | failed | expired | refunded
            $table->string('status', 20)->default('pending');
            // type: credit_package | voucher | print_job | merchandise
            $table->string('type', 30)->default('credit_package');
            $table->json('payment_details')->nullable(); // gateway response snapshot
            $table->timestamp('paid_at')->nullable();
            $table->timestamp('expired_at')->nullable();
            $table->softDeletes();
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });

        // ============================================================
        // ORDER ITEMS
        // ============================================================
        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
            $table->string('item_type', 50); // Package, Frame, PrintJob
            $table->unsignedBigInteger('item_id');
            $table->string('item_name');
            $table->unsignedSmallInteger('quantity')->default(1);
            $table->decimal('unit_price', 15, 2);
            $table->decimal('total', 15, 2);
            $table->timestamps();

            $table->index(['order_id']);
        });

        // ============================================================
        // PAYMENT WEBHOOKS — Webhook Inbox (idempotent processing)
        // ============================================================
        Schema::create('payment_webhooks', function (Blueprint $table) {
            $table->id();
            $table->string('provider', 30); // midtrans | xendit | monad
            $table->string('event_id', 100); // provider's event/notification ID
            $table->string('event_type', 50)->nullable();
            $table->foreignId('order_id')->nullable()->constrained('orders')->nullOnDelete();
            $table->json('raw_payload');
            $table->string('signature', 100)->nullable();
            $table->boolean('signature_verified')->default(false);
            // status: received | processing | processed | failed | rejected
            $table->string('status', 20)->default('received');
            $table->text('processing_error')->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->timestamp('received_at')->useCurrent();

            $table->unique(['provider', 'event_id']); // Idempotency constraint
            $table->index(['status', 'received_at']);
        });

        // ============================================================
        // MERCHANDISE PRODUCTS
        // ============================================================
        Schema::create('merchandise_products', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug', 100)->unique();
            $table->text('description')->nullable();
            $table->string('category', 50)->default('print'); // print | apparel | accessories
            $table->string('thumbnail_url')->nullable();
            $table->json('mockup_urls')->nullable();
            $table->decimal('base_price', 15, 2);
            $table->decimal('weight_grams', 8, 2)->default(0);
            $table->json('print_area')->nullable(); // {width_mm, height_mm, x, y}
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // ============================================================
        // USER SHIPPING ADDRESSES
        // ============================================================
        Schema::create('user_shipping_addresses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('label', 50)->default('Rumah'); // Rumah, Kantor, etc.
            $table->string('recipient_name');
            $table->string('phone_number', 20);
            $table->string('address_line1');
            $table->string('address_line2')->nullable();
            $table->string('village')->nullable();
            $table->string('district');
            $table->string('city');
            $table->string('province');
            $table->string('postal_code', 10);
            $table->boolean('is_default')->default(false);
            $table->timestamps();

            $table->index('user_id');
        });

        // ============================================================
        // MERCHANDISE ORDERS
        // ============================================================
        Schema::create('merchandise_orders', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('order_id')->constrained('orders')->cascadeOnDelete();
            $table->foreignId('address_id')->nullable()->constrained('user_shipping_addresses')->nullOnDelete();
            $table->json('address_snapshot'); // Snapshot at time of order
            $table->string('courier', 30)->nullable(); // JNE, J&T, SiCepat
            $table->string('courier_service', 50)->nullable();
            $table->decimal('shipping_cost', 15, 2)->default(0);
            $table->string('tracking_number', 100)->nullable();
            $table->string('high_res_print_url')->nullable();
            $table->json('crop_config')->nullable();
            // status: pending | manufacturing | shipped | delivered | cancelled
            $table->string('status', 20)->default('pending');
            $table->timestamp('shipped_at')->nullable();
            $table->timestamp('delivered_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });

        // ============================================================
        // NFT COLLECTIONS & COLLECTIBLES
        // ============================================================
        Schema::create('nft_collections', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('contract_address', 100)->unique();
            $table->string('contract_type', 20)->default('ERC721'); // ERC721 | ERC1155
            $table->string('chain_id', 20)->default('10143'); // Monad Testnet
            $table->json('abi')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('user_collectibles', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('collection_id')->constrained('nft_collections')->cascadeOnDelete();
            $table->foreignId('strip_id')->nullable()->constrained('photo_strips')->nullOnDelete();
            $table->unsignedBigInteger('token_id');
            $table->string('metadata_uri')->nullable(); // IPFS URI
            $table->json('traits')->nullable();
            $table->string('tx_hash', 66)->nullable();
            $table->string('mint_tx_hash', 66)->nullable();
            // status: minting | minted | failed
            $table->string('status', 20)->default('minting');
            $table->timestamp('minted_at')->nullable();
            $table->timestamps();

            $table->unique(['collection_id', 'token_id']);
            $table->index('user_id');
        });

        // ============================================================
        // LOYALTY SYSTEM
        // ============================================================
        Schema::create('loyalty_accounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedBigInteger('points_balance')->default(0);
            $table->unsignedBigInteger('lifetime_earned')->default(0);
            $table->unsignedBigInteger('lifetime_redeemed')->default(0);
            // tier: bronze | silver | gold | platinum
            $table->string('tier', 20)->default('bronze');
            $table->unsignedInteger('streak_days')->default(0);
            $table->date('last_check_in_date')->nullable();
            $table->timestamps();

            $table->unique('user_id');
        });

        Schema::create('loyalty_rewards', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
            // type: credits | voucher | print | discount
            $table->string('type', 30);
            $table->unsignedInteger('points_required');
            $table->decimal('value', 10, 2)->default(0);
            $table->boolean('is_active')->default(true);
            $table->unsignedInteger('stock')->nullable();
            $table->timestamps();
        });

        Schema::create('loyalty_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            // type: earn | redeem | expire | admin_adjust
            $table->string('type', 20);
            $table->bigInteger('points');   // positive = earn, negative = redeem
            $table->unsignedBigInteger('balance_before');
            $table->unsignedBigInteger('balance_after');
            $table->string('reference_type', 50)->nullable(); // Order, Session
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->string('description')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['user_id', 'type']);
        });

        // ============================================================
        // REFERRALS
        // ============================================================
        Schema::create('referrals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('referrer_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('referred_id')->constrained('users')->cascadeOnDelete();
            // status: pending | rewarded | cancelled
            $table->string('status', 20)->default('pending');
            $table->timestamp('rewarded_at')->nullable();
            $table->timestamps();

            $table->unique(['referrer_id', 'referred_id']);
        });

        // ============================================================
        // NOTIFICATIONS
        // ============================================================
        Schema::create('notifications', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('type', 100);
            $table->foreignId('notifiable_id')->constrained('users')->cascadeOnDelete();
            $table->json('data');
            $table->timestamp('read_at')->nullable();
            $table->timestamps();

            $table->index(['notifiable_id', 'read_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('referrals');
        Schema::dropIfExists('loyalty_transactions');
        Schema::dropIfExists('loyalty_rewards');
        Schema::dropIfExists('loyalty_accounts');
        Schema::dropIfExists('user_collectibles');
        Schema::dropIfExists('nft_collections');
        Schema::dropIfExists('merchandise_orders');
        Schema::dropIfExists('user_shipping_addresses');
        Schema::dropIfExists('merchandise_products');
        Schema::dropIfExists('payment_webhooks');
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('packages');
    }
};
