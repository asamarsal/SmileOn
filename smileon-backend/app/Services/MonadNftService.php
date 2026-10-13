<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Process;

class MonadNftService
{
    /**
     * Mint a photostrip NFT on Monad Testnet via relayer script.
     *
     * @param string $recipientAddress 0x address of recipient (42 hex chars)
     * @param string $metadataUri URI of metadata (IPFS or HTTPS)
     * @param string $sessionId Unique session ID
     * @param int $frameId Frame template ID
     * @return array [success => bool, tx_hash => string|null, token_id => string|null, block_number => int|null, error => string|null]
     */
    public static function mintPhotostrip(
        string $recipientAddress,
        string $metadataUri,
        string $sessionId,
        int $frameId = 1
    ): array {
        // Validate recipient address format
        if (!preg_match('/^0x[a-fA-F0-9]{40}$/', $recipientAddress)) {
            return [
                'success' => false,
                'error'   => "Alamat wallet penerima tidak valid: {$recipientAddress}",
            ];
        }

        $scriptPath = base_path('scripts/mint_nft.cjs');
        $privateKey = config('services.monad.deployer_private_key', env('MONAD_DEPLOYER_PRIVATE_KEY', 'd20ec36a1c43f1404b89f4651d5a4ec50fe6e5c363e63788e09e9aea4556215f'));
        $contractAddress = config('services.monad.nft_address', '0xd685CCC9EF93b027e0D1EF05d4eDf83EC0385d48');
        $rpcUrl = config('services.monad.fallback_rpc_url', 'https://monad-testnet.drpc.org');

        $command = [
            'node',
            $scriptPath,
            "--to={$recipientAddress}",
            "--uri={$metadataUri}",
            "--session={$sessionId}",
            "--frame={$frameId}",
            "--key={$privateKey}",
            "--contract={$contractAddress}",
            "--rpc={$rpcUrl}",
        ];

        try {
            $result = Process::timeout(60)->run($command);
            $output = trim($result->output());
            $errorOutput = trim($result->errorOutput());

            if ($result->successful() && !empty($output)) {
                $data = json_decode($output, true);
                if (is_array($data) && ($data['success'] ?? false)) {
                    Log::info("[MonadNftService] Mint success tx={$data['tx_hash']} token={$data['token_id']} to={$recipientAddress}");
                    return [
                        'success'      => true,
                        'tx_hash'      => $data['tx_hash'],
                        'token_id'     => (string) ($data['token_id'] ?? '1'),
                        'block_number' => $data['block_number'] ?? null,
                        'recipient'    => $recipientAddress,
                        'metadata_uri' => $metadataUri,
                        'error'        => null,
                    ];
                }
            }

            // Fallback parsing from output or errorOutput
            $errData = json_decode($output ?: $errorOutput, true);
            $errMsg = $errData['error'] ?? ($errorOutput ?: $output ?: 'Relayer script execution failed.');
            Log::error("[MonadNftService] Mint failed: {$errMsg}");

            return [
                'success' => false,
                'error'   => $errMsg,
            ];
        } catch (\Throwable $e) {
            Log::error("[MonadNftService] Exception: " . $e->getMessage());
            return [
                'success' => false,
                'error'   => $e->getMessage(),
            ];
        }
    }
}
