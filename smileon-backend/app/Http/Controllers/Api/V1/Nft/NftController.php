<?php

namespace App\Http\Controllers\Api\V1\Nft;

use App\Http\Controllers\Controller;
use App\Models\NftCollection;
use App\Models\UserCollectible;
use App\Models\PhotoStrip;
use App\Services\MonadNftService;
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
 *   1. User calls POST /api/v1/nft/mint with recipient_address & session/strip uuid
 *   2. Backend uploads metadata JSON to IPFS via Pinata or prepares HTTPS tokenURI
 *   3. Backend calls Monad relayer to mint ERC-721 token on Monad Testnet (Chain ID 10143)
 *   4. Collectible record created with real tx_hash and real on-chain token_id
 *   5. Response returns MonadVision & Explorer links for instant verification
 */
class NftController extends Controller
{
    /**
     * POST /api/v1/nft/mint
     *
     * Mint a photostrip as an on-chain NFT on Monad Testnet.
     */
    public function mint(Request $request): JsonResponse
    {
        $request->validate([
            'strip_uuid'        => 'nullable|string',
            'session_uuid'      => 'nullable|string',
            'recipient_address' => 'nullable|string|regex:/^0x[a-fA-F0-9]{40}$/',
            'name'              => 'nullable|string|max:100',
            'description'       => 'nullable|string|max:500',
            'image_url'         => 'nullable|string|url',
            'frame_id'          => 'nullable|integer',
            'attributes'        => 'nullable|array',
            'force'             => 'nullable|boolean',
        ]);        try {
            $user = $request->user('sanctum') ?? $request->user();
            if (!$user) {
                $user = \App\Models\User::first() ?? \App\Models\User::create([
                    'name'     => 'SmileOn Guest',
                    'email'    => 'guest@smileon-dapps.my.id',
                    'password' => bcrypt(Str::random(16)),
                ]);
            }
            $userId = $user->id;
            $stripUuid = $request->input('strip_uuid');
            $sessionUuid = $request->input('session_uuid');

            $strip = null;
            if ($stripUuid && Str::isUuid($stripUuid)) {
                $strip = PhotoStrip::where('uuid', $stripUuid)->first();
            }
            if (!$strip && $sessionUuid) {
                $session = Str::isUuid($sessionUuid)
                    ? \App\Models\PhotoSession::where('uuid', $sessionUuid)->first()
                    : \App\Models\PhotoSession::where('session_code', $sessionUuid)->first();
                if ($session) {
                    $strip = PhotoStrip::where('session_id', $session->id)->first();
                }
            }
            if (!$strip && $user) {
                $strip = PhotoStrip::where('user_id', $user->id)->latest()->first();
            }

            // Jika strip belum terdaftar di database, buat record default photostrip
            if (!$strip) {
                $session = \App\Models\PhotoSession::firstOrCreate(
                    ['uuid' => ($sessionUuid && Str::isUuid($sessionUuid)) ? $sessionUuid : (string) Str::uuid()],
                    [
                        'user_id'          => $user?->id ?? 1,
                        'mode'             => 'personal',
                        'status'           => 'completed',
                        'credits_required' => 0,
                        'photos_count'     => 4,
                    ]
                );

                $strip = PhotoStrip::create([
                    'uuid'            => (string) Str::uuid(),
                    'session_id'      => $session->id,
                    'user_id'         => $userId,
                    'storage_key'     => "strips/{$session->uuid}/photostrip_hd.png",
                    'clean_url'       => $request->image_url ?? 'https://smileon-dapps.my.id/storage/strips/default.png',
                    'watermarked_url' => $request->image_url ?? 'https://smileon-dapps.my.id/storage/strips/default.png',
                    'status'          => 'ready',
                    'share_token'     => Str::random(64),
                ]);
            }

            $userId = $user?->id ?? $strip->user_id ?? 1;

            // Tentukan alamat penerima (recipient wallet)
            $recipient = $request->input('recipient_address')
                ?? $user?->wallet_address
                ?? '0xFeff727205Fe524A3A8A16C404FeC9Cfe4124aCd';

            // Validasi format alamat
            if (!preg_match('/^0x[a-fA-F0-9]{40}$/', $recipient)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Alamat wallet Monad tidak valid. Harap sambungkan wallet Anda.',
                ], 422);
            }

            // Idempotency — jika sudah pernah di-mint secara nyata di Monad
            if (!$request->boolean('force')) {
                $existing = UserCollectible::where('strip_id', $strip->id)
                    ->where('user_id', $userId)
                    ->where('status', 'minted')
                    ->whereNotNull('tx_hash')
                    ->with('collection:id,name,contract_address,chain_id')
                    ->first();

                // Cek apakah tx_hash adalah hash nyata (bukan simulated sha256 lama)
                if ($existing && strlen($existing->tx_hash) === 66 && (int)$existing->token_id < 1000) {
                    return response()->json([
                        'success' => true,
                        'message' => 'Collectible sudah pernah di-mint ke Monad Testnet.',
                        'data'    => [
                            'id'               => $existing->id,
                            'uuid'             => $existing->uuid,
                            'token_id'         => (string) $existing->token_id,
                            'tx_hash'          => $existing->tx_hash,
                            'mint_tx_hash'     => $existing->mint_tx_hash ?? $existing->tx_hash,
                            'metadata_uri'     => $existing->metadata_uri,
                            'recipient_address'=> $recipient,
                            'contract_address' => $existing->collection?->contract_address ?? config('services.monad.nft_address'),
                            'chain_id'         => 10143,
                            'explorer_tx_url'  => "https://testnet.monadexplorer.com/tx/{$existing->tx_hash}",
                            'vision_tx_url'    => "https://testnet.monadvision.com/tx/{$existing->tx_hash}",
                            'vision_nft_url'   => "https://testnet.monadvision.com/token/" . ($existing->collection?->contract_address ?? config('services.monad.nft_address')) . "/instance/{$existing->token_id}",
                            'traits'           => $existing->traits,
                            'status'           => 'minted',
                            'minted_at'        => $existing->minted_at?->toIso8601String(),
                        ],
                    ]);
                }
            }

            $collection = NftCollection::where('is_active', true)->first();
            if (!$collection) {
                $collection = NftCollection::firstOrCreate(
                    ['contract_address' => config('services.monad.nft_address', '0xd685CCC9EF93b027e0D1EF05d4eDf83EC0385d48')],
                    [
                        'name'          => 'SmileOn Moments',
                        'contract_type' => 'ERC721',
                        'chain_id'      => 10143,
                        'is_active'     => true,
                    ]
                );
            }

            // Build NFT metadata (EIP-721 standard)
            $name        = $request->name ?? "SmileOn Photo #{$strip->id}";
            $description = $request->description ?? "Kenangan foto resmi SmileOn pada Monad Testnet - " . ($strip->created_at?->format('d M Y') ?? date('d M Y'));
            $imageUrl    = $request->input('image_url') ?? $strip->clean_url ?? $strip->watermarked_url ?? 'https://smileon-dapps.my.id/storage/strips/default.png';

            $attributes  = array_merge([
                ['trait_type' => 'Aspect Ratio', 'value' => $strip->aspect_ratio ?? '2:6'],
                ['trait_type' => 'Print Size', 'value'   => $strip->print_size_inch ?? '2x6'],
                ['trait_type' => 'Watermark', 'value'    => $strip->show_watermark ? 'Yes' : 'No'],
                ['trait_type' => 'Chain', 'value'        => 'Monad Testnet (Chain ID 10143)'],
                ['trait_type' => 'Contract', 'value'     => 'SmileOnNFT (ERC-721)'],
            ], (array) $request->input('attributes', []));

            $metadata = [
                'name'         => $name,
                'description'  => $description,
                'image'        => $imageUrl,
                'external_url' => config('app.url') . "/strips/share/{$strip->share_token}",
                'attributes'   => $attributes,
            ];

            // Upload metadata to IPFS (Pinata) jika tersedia, fallback ke HTTPS tokenURI
            $ipfsUri = $this->uploadToPinata($metadata);
            if (str_starts_with($ipfsUri, 'ipfs://') && !str_contains($ipfsUri, 'QmError') && !str_contains($ipfsUri, 'QmPlaceholder')) {
                $metadataUri = $ipfsUri;
            } else {
                $metadataUri = url("/api/v1/nft/metadata/{$strip->uuid}");
            }

            $frameId = (int) ($request->input('frame_id') ?? 1);
            $sessionIdForContract = $sessionUuid ?? $strip->uuid;

            // Eksekusi mint nyata on-chain ke Monad Testnet via relayer
            $mintResult = MonadNftService::mintPhotostrip(
                recipientAddress: $recipient,
                metadataUri: $metadataUri,
                sessionId: $sessionIdForContract,
                frameId: $frameId
            );

            if (!$mintResult['success']) {
                return response()->json([
                    'success' => false,
                    'message' => 'Gagal mencetak NFT di Monad Testnet: ' . ($mintResult['error'] ?? 'RPC relayer timeout.'),
                    'error'   => $mintResult['error'] ?? 'Relayer error',
                ], 500);
            }

            $txHash   = $mintResult['tx_hash'];
            $tokenId  = $mintResult['token_id'];

            $collectible = DB::transaction(function () use ($userId, $strip, $collection, $tokenId, $txHash, $metadataUri, $attributes) {
                return UserCollectible::updateOrCreate(
                    ['strip_id' => $strip->id],
                    [
                        'user_id'       => $userId,
                        'collection_id' => $collection->id,
                        'token_id'      => (string) $tokenId,
                        'tx_hash'       => $txHash,
                        'mint_tx_hash'  => $txHash,
                        'metadata_uri'  => $metadataUri,
                        'traits'        => $attributes,
                        'status'        => 'minted',
                        'minted_at'     => now(),
                    ]
                );
            });

            $contractAddr = $collection->contract_address ?? config('services.monad.nft_address', '0xd685CCC9EF93b027e0D1EF05d4eDf83EC0385d48');

            return response()->json([
                'success' => true,
                'message' => 'NFT berhasil di-mint ke Monad Testnet!',
                'data'    => [
                    'id'               => $collectible->id,
                    'uuid'             => $collectible->uuid,
                    'token_id'         => (string) $tokenId,
                    'tx_hash'          => $txHash,
                    'mint_tx_hash'     => $txHash,
                    'metadata_uri'     => $metadataUri,
                    'recipient_address'=> $recipient,
                    'contract_address' => $contractAddr,
                    'chain_id'         => 10143,
                    'explorer_tx_url'  => "https://testnet.monadexplorer.com/tx/{$txHash}",
                    'vision_tx_url'    => "https://testnet.monadvision.com/tx/{$txHash}",
                    'vision_nft_url'   => "https://testnet.monadvision.com/token/{$contractAddr}/instance/{$tokenId}",
                    'traits'           => $attributes,
                    'status'           => 'minted',
                    'minted_at'        => $collectible->minted_at?->toIso8601String(),
                ],
            ], 201);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error("[NftController] Error minting NFT: " . $e->getMessage(), [
                'exception' => get_class($e),
                'file'      => $e->getFile(),
                'line'      => $e->getLine(),
                'trace'     => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Gagal memproses NFT: ' . $e->getMessage(),
                'error'   => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * GET /api/v1/nft/metadata/{token_or_uuid}
     *
     * Public OpenSea/EIP-721 JSON metadata endpoint for block explorers.
     */
    public function metadata(string $tokenOrUuid): JsonResponse
    {
        $query = UserCollectible::query();
        if (Str::isUuid($tokenOrUuid)) {
            $query->where('uuid', $tokenOrUuid);
        } else {
            $query->where('token_id', $tokenOrUuid);
        }
        $collectible = $query->with('strip')->first();

        if (!$collectible) {
            return response()->json([
                'name'        => "SmileOn Moments #{$tokenOrUuid}",
                'description' => "Kenangan photobooth resmi SmileOn pada Monad Testnet.",
                'image'       => url('/storage/strips/default.png'),
                'attributes'  => [
                    ['trait_type' => 'Chain', 'value' => 'Monad Testnet (Chain ID 10143)'],
                ],
            ]);
        }

        $strip = $collectible->strip;
        $imageUrl = $strip?->clean_url ?? $strip?->watermarked_url ?? url('/storage/strips/default.png');

        return response()->json([
            'name'         => "SmileOn Photo #{$collectible->token_id}",
            'description'  => "Kenangan foto resmi SmileOn pada Monad Testnet - " . ($collectible->minted_at?->format('d M Y') ?? date('d M Y')),
            'image'        => $imageUrl,
            'external_url' => $strip ? config('app.url') . "/strips/share/{$strip->share_token}" : config('app.url'),
            'attributes'   => $collectible->traits ?? [
                ['trait_type' => 'Chain', 'value' => 'Monad Testnet (Chain ID 10143)'],
                ['trait_type' => 'Token ID', 'value' => (string) $collectible->token_id],
            ],
        ]);
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
