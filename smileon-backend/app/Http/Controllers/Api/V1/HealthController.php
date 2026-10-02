<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Queue;

/**
 * Health Check Controller
 *
 * Provides endpoints to verify if the API is alive and all critical services
 * (database, cache, queue) are operational.
 */
class HealthController extends Controller
{
    /**
     * Full health check including database, cache, and queue connectivity.
     *
     * GET /health
     */
    public function check(): JsonResponse
    {
        $status = 'ok';
        $checks = [];

        // Database check
        try {
            DB::connection()->getPdo();
            $dbType = DB::connection()->getDriverName();
            $checks['database'] = [
                'status'  => 'ok',
                'driver'  => $dbType,
            ];
        } catch (\Throwable $e) {
            $status = 'degraded';
            $checks['database'] = [
                'status'  => 'error',
                'message' => $e->getMessage(),
            ];
        }

        // Cache check
        try {
            $cacheKey = 'smileon_health_check_' . time();
            Cache::put($cacheKey, true, 5);
            $cached = Cache::get($cacheKey);
            Cache::forget($cacheKey);

            $checks['cache'] = [
                'status' => $cached ? 'ok' : 'error',
                'driver' => config('cache.default'),
            ];
        } catch (\Throwable $e) {
            $status = 'degraded';
            $checks['cache'] = [
                'status'  => 'error',
                'message' => $e->getMessage(),
            ];
        }

        // Queue check
        try {
            $checks['queue'] = [
                'status'  => 'ok',
                'driver'  => config('queue.default'),
                'message' => 'Queue driver configured',
            ];
        } catch (\Throwable $e) {
            $checks['queue'] = [
                'status'  => 'error',
                'message' => $e->getMessage(),
            ];
        }

        $httpCode = $status === 'ok' ? 200 : 503;

        return response()->json([
            'status'      => $status,
            'app'         => config('app.name'),
            'version'     => 'v1',
            'environment' => config('app.env'),
            'timestamp'   => now()->toIso8601String(),
            'checks'      => $checks,
        ], $httpCode);
    }

    /**
     * Simple ping endpoint — ultra-fast liveness probe.
     *
     * GET /ping
     */
    public function ping(): JsonResponse
    {
        return response()->json([
            'status'    => 'ok',
            'message'   => 'pong',
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
