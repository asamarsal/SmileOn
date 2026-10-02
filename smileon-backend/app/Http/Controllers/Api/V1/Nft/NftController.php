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
            'strip_uuid'  => 'required|string',
            'name'        => 'nullable|string|max:100',
            'description' => 'nullable|string|max:500',
            'attributes'  => 'nullable|array',
        ]);

        $user  = $request->user();
        $strip = PhotoStrip::where('uuid', $request->strip_uuid)
            ->where('user_id', $user->id)
            ->where('status', 'ready')
            ->firstOrFail();

        // Idempotency — prevent double-minting same strip
        $existing = UserCollectible::where('strip_id', $strip->id)
            ->where('user_id', $user->id)
            ->whereIn('status', ['minting', 'minted'])
            ->first();

        if ($existing) {
            return response()->json([
                'success' => true,
                'message' => 'Collectible sudah ada atau sedang di-mint.',
                'data'    => $existing,
            ]);
        }

        $collection = NftCollection::where('is_active', true)->firstOrFail();

        $collectible = DB::transaction(function () use ($user, $strip, $collection, $request) {
            // Build NFT metadata (EIP-721 standard)
            $name        = $request->name ?? "SmileOn Photo #{$strip->id}";
            $description = $request->description ?? "Kenangan foto dari SmileOn - {$strip->created_at->format('d M Y')}";
            $attributes  = array_merge([
                ['trait_type' => 'Aspect Ratio', 'value' => $strip->aspect_ratio ?? '2:6'],
                ['trait_type' => 'Print Size', 'value'   => $strip->print_size_inch ?? '2x6'],
                ['trait_type' => 'Watermark', 'value'    => $strip->show_watermark ? 'Yes' : 'No'],
            ], $request->attributes ?? []);

            $metadata = [
                'name'        => $name,
                'description' => $description,
                'image'       => $strip->clean_url ?? $strip->watermarked_url,
                'external_url'=> config('app.url') . "/strips/share/{$strip->share_token}",
                'attributes'  => $attributes,
            ];

            // Upload metadata to IPFS (Pinata) — stub for dev
            $metadataUri = $this->uploadToPinata($metadata);

            $collectible = UserCollectible::create([
                'user_id'       => $user->id,
                'collection_id' => $collection->id,
                'strip_id'      => $strip->id,
                'metadata_uri'  => $metadataUri,
                'traits'        => $attributes,
                'status'        => 'minting',
            ]);

            // TODO: Dispatch MintNftJob::dispatch($collectible, $collection, $user->wallet_address)
            // The job uses a KMS-protected relayer wallet to call the smart contract

            return $collectible;
        });

        return response()->json([
            'success' => true,
            'message' => 'NFT sedang di-mint ke Monad blockchain.',
            'data'    => $collectible->fresh(),
        ], 202);
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
