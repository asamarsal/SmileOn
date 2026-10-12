<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default Filesystem Disk
    |--------------------------------------------------------------------------
    |
    | Pilihan default disk:
    | - "public" / "vps" : Local storage VPS di storage/app/public
    | - "s3"             : AWS S3 / MinIO
    | - "r2"             : Cloudflare R2 (S3-compatible)
    |
    */

    'default' => env('FILESYSTEM_DISK', 'public'),

    /*
    | Target penyimpanan default untuk photostrip & upload:
    | 'vps' (Storage VPS), 's3' (AWS S3), 'r2' (Cloudflare R2), 'google' (Google Drive Admin)
    */
    'default_save_target' => env('STORAGE_SAVE_TARGET', 'vps'),

    /*
    |--------------------------------------------------------------------------
    | Filesystem Disks
    |--------------------------------------------------------------------------
    */

    'disks' => [

        'local' => [
            'driver' => 'local',
            'root'   => storage_path('app/private'),
            'serve'  => true,
            'throw'  => false,
            'report' => false,
        ],

        // 1. Storage VPS Laravel (Local Public Disk)
        'public' => [
            'driver'     => 'local',
            'root'       => storage_path('app/public'),
            'url'        => rtrim(env('VPS_STORAGE_URL', env('APP_URL', 'http://localhost') . '/storage'), '/'),
            'visibility' => 'public',
            'throw'      => false,
            'report'     => false,
        ],

        // Alias eksplisit untuk Storage VPS
        'vps' => [
            'driver'     => 'local',
            'root'       => storage_path('app/public'),
            'url'        => rtrim(env('VPS_STORAGE_URL', env('APP_URL', 'http://localhost') . '/storage'), '/'),
            'visibility' => 'public',
            'throw'      => false,
            'report'     => false,
        ],

        // 2. AWS S3 / MinIO Object Storage
        's3' => [
            'driver'                  => 's3',
            'key'                     => env('AWS_ACCESS_KEY_ID'),
            'secret'                  => env('AWS_SECRET_ACCESS_KEY'),
            'region'                  => env('AWS_DEFAULT_REGION', 'ap-southeast-1'),
            'bucket'                  => env('AWS_BUCKET', 'smileon-storage'),
            'url'                     => env('AWS_URL'),
            'endpoint'                => env('AWS_ENDPOINT'),
            'use_path_style_endpoint' => env('AWS_USE_PATH_STYLE_ENDPOINT', false),
            'throw'                   => false,
            'report'                  => false,
        ],

        // 3. Cloudflare R2 Object Storage (S3-Compatible)
        'r2' => [
            'driver'                  => 's3',
            'key'                     => env('CLOUDFLARE_R2_ACCESS_KEY'),
            'secret'                  => env('CLOUDFLARE_R2_SECRET_KEY'),
            'region'                  => 'auto',
            'bucket'                  => env('CLOUDFLARE_R2_BUCKET', 'smileon-storage'),
            'url'                     => env('CLOUDFLARE_R2_URL', rtrim(env('APP_URL', 'https://smileon-dapps.my.id'), '/') . '/storage'),
            'endpoint'                => env('CLOUDFLARE_R2_ENDPOINT'),
            'use_path_style_endpoint' => env('CLOUDFLARE_R2_USE_PATH_STYLE_ENDPOINT', false),
            'throw'                   => false,
            'report'                  => false,
        ],

    ],

    /*
    |--------------------------------------------------------------------------
    | Google Drive Admin Configuration
    |--------------------------------------------------------------------------
    | Digunakan untuk upload otomatis photostrip & backup sesi ke Google Drive Admin.
    */
    'google' => [
        'enabled'              => env('GOOGLE_DRIVE_ENABLED', true),
        'admin_email'          => env('GOOGLE_DRIVE_ADMIN_EMAIL', 'admin@smileon-dapps.my.id'),
        'folder_id'            => env('GOOGLE_DRIVE_FOLDER_ID', ''),
        'client_id'            => env('GOOGLE_DRIVE_CLIENT_ID', ''),
        'client_secret'        => env('GOOGLE_DRIVE_CLIENT_SECRET', ''),
        'refresh_token'        => env('GOOGLE_DRIVE_REFRESH_TOKEN', ''),
        'service_account_json' => env('GOOGLE_DRIVE_SERVICE_ACCOUNT_JSON', 'storage/app/google-service-account.json'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Symbolic Links
    |--------------------------------------------------------------------------
    | Jalankan `php artisan storage:link` pada VPS untuk menghubungkan link ini.
    */

    'links' => [
        public_path('storage') => storage_path('app/public'),
    ],

];
