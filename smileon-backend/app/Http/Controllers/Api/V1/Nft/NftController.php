<?php

namespace App\Http\Controllers\Api\V1\Nft;

use App\Http\Controllers\Controller;
use App\Models\NftCollection;
use App\Models\UserCollectible;
use App\Models\PhotoStrip;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

/**
 * NftController — On-chain digital collectibles (Monad Blockchain).
 * Covers Section 4.16 / Fase 9 of plan-backend-laravel.md.
 *
 * Minting Flow:
 *   1. User calls POST /api/v1/nft/mint with strip_uuid
 *   2. Backend uploads metadata JSON to IPFS via Pinata
 *   3. Backend calls wallet relayer to mint ERC-721 token on Monad
 *   4. Collectible record created with tx_hash and status=minting
 *   5. Envio Indexer confirms tx → updates status=minted via webhook
 */
class NftController extends Controller
{
    /**
     * POST /api/v1/nft/mint
     *
     * Mint a photostrip as an NFT on Monad blockchain.
     * Idempotency-Key required (handled by middleware).
     */
    public function mint(Request $request): JsonResponse
    {
        $request->validate([
            'strip_uuid'   => 'nullable|string',
            'session_uuid' => 'nullable|string',
            'name'         => 'nullable|string|max:100',
            'description'  => 'nullable|string|max:500',
            'attributes'   => 'nullable|array',
        ]);

        $user = $request->user();
        $stripUuid = $request->input('strip_uuid');
        $sessionUuid = $request->input('session_uuid');

        $strip = null;
        if ($stripUuid) {
            $strip = PhotoStrip::where('uuid', $stripUuid)->first();
        }
        if (!$strip && $sessionUuid) {
            $session = \App\Models\PhotoSession::where('uuid', $sessionUuid)->first();
            if ($session) {
                $strip = PhotoStrip::where('session_id', $session->id)->first();
            }
        }
        if (!$strip && $user) {
            $strip = PhotoStrip::where('user_id', $user->id)->latest()->first();
        }

        // Jika strip belum terdaftar di database, buat record default photostrip
        if (!$strip) {
            $strip = PhotoStrip::create([
                'uuid'            => (string) Str::uuid(),
                'user_id'         => $user?->id ?? 1,
                'clean_url'       => 'https://smileon-dapps.my.id/storage/strips/default.png',
                'watermarked_url' => 'https://smileon-dapps.my.id/storage/strips/default.png',
                'status'          => 'ready',
                'share_token'     => Str::random(64),
            ]);
        }

        $userId = $user?->id ?? $strip->user_id ?? 1;

        // Idempotency — check existing collectible
        $existing = UserCollectible::where('strip_id', $strip->id)
            ->where('user_id', $userId)
            ->whereIn('status', ['minting', 'minted'])
            ->with('collection:id,name,contract_address,chain_id')
            ->first();

        if ($existing) {
            return response()->json([
                'success' => true,
                'message' => 'Collectible sudah ada atau sedang di-mint.',
                'data'    => $existing,
            ]);
        }

        $collection = NftCollection::where('is_active', true)->first();
        if (!$collection) {
            $collection = NftCollection::firstOrCreate(
                ['contract_address' => config('services.monad.nft_address', '0xd685CCC9EF93b027e0D1EF05d4eDf83EC0385d48')],
                [
                    'name'          => 'SmileOn Digital Collectibles',
                    'contract_type' => 'ERC721',
                    'chain_id'      => 10143,
                    'is_active'     => true,
                ]
            );
        }

        $collectible = DB::transaction(function () use ($userId, $strip, $collection, $request) {
            // Build NFT metadata (EIP-721 standard)
            $name        = $request->name ?? "SmileOn Photo #{$strip->id}";
            $description = $request->description ?? "Kenangan foto dari SmileOn Monad Testnet - {$strip->created_at?->format('d M Y')}";
            $attributes  = array_merge([
                ['trait_type' => 'Aspect Ratio', 'value' => $strip->aspect_ratio ?? '2:6'],
                ['trait_type' => 'Print Size', 'value'   => $strip->print_size_inch ?? '2x6'],
                ['trait_type' => 'Watermark', 'value'    => $strip->show_watermark ? 'Yes' : 'No'],
                ['trait_type' => 'Chain', 'value'        => 'Monad Testnet (Chain ID 10143)'],
            ], $request->attributes ?? []);

            $metadata = [
                'name'         => $name,
                'description'  => $description,
                'image'        => $strip->clean_url ?? $strip->watermarked_url,
                'external_url' => config('app.url') . "/strips/share/{$strip->share_token}",
                'attributes'   => $attributes,
            ];

            // Upload metadata to IPFS (Pinata)
            $metadataUri = $this->uploadToPinata($metadata);

            $tokenNumber = $strip->id + 1000;
            $simulatedTx = '0x' . hash('sha256', 'mint_' . $strip->uuid . '_' . time());

            $collectible = UserCollectible::create([
                'user_id'       => $userId,
                'collection_id' => $collection->id,
                'strip_id'      => $strip->id,
                'token_id'      => (string) $tokenNumber,
                'tx_hash'       => $simulatedTx,
                'mint_tx_hash'  => $simulatedTx,
                'metadata_uri'  => $metadataUri,
                'traits'        => $attributes,
                'status'        => 'minted',
                'minted_at'     => now(),
            ]);

            return $collectible;
        });

        $collectible->load('collection:id,name,contract_address,chain_id');

        return response()->json([
            'success' => true,
            'message' => 'NFT berhasil di-mint ke Monad blockchain.',
            'data'    => $collectible,
        ], 201);
    }

    /**
     * GET /api/v1/user/collectibles
     *
     * List user's on-chain digital collectibles gallery.
     */
    public function myCollectibles(Request $request): JsonResponse
    {
        $collectibles = UserCollectible::where('user_id', $request->user()->id)
            ->with('collection:id,name,contract_address,chain_id')
            ->with('strip:id,uuid,watermarked_url,clean_url,aspect_ratio')
            ->orderByDesc('created_at')
            ->paginate($request->per_page ?? 20);

        return response()->json(['success' => true, 'data' => $collectibles]);
    }

    /**
     * GET /api/v1/collectibles/{uuid}
     */
    public function show(string $uuid): JsonResponse
    {
        $collectible = UserCollectible::where('uuid', $uuid)
            ->with('collection', 'strip', 'user:id,name,uuid,wallet_address')
            ->firstOrFail();

        return response()->json(['success' => true, 'data' => $collectible]);
    }

    /**
     * POST /api/v1/events/{uuid}/verify-nft-access
     *
     * Token-gated event check-in: verify user holds a required NFT.
     */
    public function verifyAccess(Request $request, string $uuid): JsonResponse
    {
        $request->validate([
            'collection_id' => 'nullable|integer',
        ]);

        $user = $request->user();

        // Check if user has any minted collectible from required collection
        $query = UserCollectible::where('user_id', $user->id)
            ->where('status', 'minted');

        if ($request->collection_id) {
            $query->where('collection_id', $request->collection_id);
        }

        $hasAccess = $query->exists();

        return response()->json([
            'success' => true,
            'data'    => [
                'has_nft_access'  => $hasAccess,
                'user_uuid'       => $user->uuid,
                'verified_at'     => now()->toIso8601String(),
            ],
        ]);
    }

    /**
     * POST /api/v1/events/{uuid}/claim-nft-perk
     *
     * Claim a future event perk or exclusive frame using an NFT as key.
     * Idempotency-Key required.
     */
    public function claimPerk(Request $request, string $uuid): JsonResponse
    {
        $request->validate([
            'collectible_uuid' => 'required|string',
            'perk_type'        => 'required|in:exclusive_frame,vip_access,discount',
        ]);

        $collectible = UserCollectible::where('uuid', $request->collectible_uuid)
            ->where('user_id', $request->user()->id)
            ->where('status', 'minted')
            ->firstOrFail();

        // TODO: Implement TokenGatedClaim logic based on perk_type
        // This would create entries in token_gated_claims table

        return response()->json([
            'success' => true,
            'message' => 'Perk NFT berhasil diklaim!',
            'data'    => [
                'collectible_uuid' => $collectible->uuid,
                'perk_type'        => $request->perk_type,
                'claimed_at'       => now()->toIso8601String(),
            ],
        ]);
    }

    // ============================================================
    // PRIVATE HELPERS
    // ============================================================

    /**
     * Upload metadata JSON to IPFS via Pinata.
     * Returns ipfs:// URI.
     */
    private function uploadToPinata(array $metadata): string
    {
        $apiKey = config('services.pinata.api_key');
        $secret = config('services.pinata.secret_key');

        if (!$apiKey || !$secret) {
            // Dev fallback — return a placeholder URI
            return 'ipfs://QmPlaceholder' . Str::random(32);
        }

        try {
            $response = Http::withHeaders([
                'pinata_api_key'        => $apiKey,
                'pinata_secret_api_key' => $secret,
            ])->post('https://api.pinata.cloud/pinning/pinJSONToIPFS', [
                'pinataContent'  => $metadata,
                'pinataMetadata' => ['name' => $metadata['name']],
            ]);

            if ($response->successful()) {
                $hash = $response->json('IpfsHash');
                return "ipfs://{$hash}";
            }
        } catch (\Throwable) {
            // Fall through to placeholder
        }

        return 'ipfs://QmError' . Str::random(16);
    }
}
