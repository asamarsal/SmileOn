<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

/**
 * Idempotency Middleware
 *
 * Enforces the Idempotency-Key header on all mutating financial/session endpoints.
 * Stores the first response in `idempotency_keys` table and returns cached result
 * on duplicate requests within the TTL window (24 hours).
 *
 * Required Header: Idempotency-Key: <UUIDv4>
 */
class EnsureIdempotency
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $key = $request->header('Idempotency-Key');

        if (empty($key)) {
            return response()->json([
                'success' => false,
                'message' => 'Header Idempotency-Key wajib disertakan pada request ini.',
                'error_code' => 'IDEMPOTENCY_KEY_MISSING',
            ], 422);
        }

        // Validate key format (UUID v4)
        if (!preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i', $key)) {
            return response()->json([
                'success' => false,
                'message' => 'Format Idempotency-Key tidak valid. Gunakan UUID v4.',
                'error_code' => 'IDEMPOTENCY_KEY_INVALID_FORMAT',
            ], 422);
        }

        $userId = $request->user()?->id;
        $cacheKey = 'idempotency:' . ($userId ?? 'anon') . ':' . $key;
        $endpoint = $request->path();

        // Check for existing cached response
        $existing = DB::table('idempotency_keys')
            ->where('key', $key)
            ->where('user_id', $userId)
            ->where('expires_at', '>', now())
            ->first();

        if ($existing) {
            // Return cached response
            $cachedResponse = json_decode($existing->response_body, true);
            return response()->json($cachedResponse, $existing->response_status)
                ->header('Idempotency-Key', $key)
                ->header('X-Idempotency-Replayed', 'true');
        }

        // Check if a request with this key is currently in-flight (processing)
        $inFlight = DB::table('idempotency_keys')
            ->where('key', $key)
            ->where('user_id', $userId)
            ->where('status', 'processing')
            ->exists();

        if ($inFlight) {
            return response()->json([
                'success' => false,
                'message' => 'Request dengan Idempotency-Key yang sama sedang diproses.',
                'error_code' => 'IDEMPOTENCY_REQUEST_IN_FLIGHT',
            ], 409);
        }

        // Store as in-flight
        DB::table('idempotency_keys')->insert([
            'key'         => $key,
            'user_id'     => $userId,
            'endpoint'    => $endpoint,
            'status'      => 'processing',
            'created_at'  => now(),
            'expires_at'  => now()->addHours(24),
        ]);

        // Process the actual request
        $response = $next($request);

        // Cache the response
        try {
            DB::table('idempotency_keys')
                ->where('key', $key)
                ->where('user_id', $userId)
                ->update([
                    'status'          => 'completed',
                    'response_status' => $response->getStatusCode(),
                    'response_body'   => $response->getContent(),
                ]);
        } catch (\Throwable $e) {
            // Non-blocking — don't fail the response if cache update fails
        }

        return $response->header('Idempotency-Key', $key);
    }
}
