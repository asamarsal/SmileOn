<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Resend, Postmark, AWS, and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'monad' => [
        'chain_id' => env('MONAD_CHAIN_ID', 10143),
        'rpc_url' => env('MONAD_RPC_URL', 'https://testnet-rpc.monad.xyz'),
        'payment_hub_address' => env('MONAD_PAYMENT_HUB_ADDRESS', '0xFAB484e78053e3FE88351A6a8A9dD545bb6a41ff'),
        'nft_address' => env('MONAD_NFT_ADDRESS', '0xd685CCC9EF93b027e0D1EF05d4eDf83EC0385d48'),
        'deployer_private_key' => env('MONAD_DEPLOYER_PRIVATE_KEY', 'd20ec36a1c43f1404b89f4651d5a4ec50fe6e5c363e63788e09e9aea4556215f'),
        'fallback_rpc_url' => env('MONAD_FALLBACK_RPC_URL', 'https://monad-testnet.drpc.org'),
        'explorer_url' => env('MONAD_EXPLORER_URL', 'https://testnet.monadexplorer.com'),
        'vision_url' => env('MONAD_VISION_URL', 'https://testnet.monadvision.com'),
    ],

    'fcm' => [
        'server_key' => env('FCM_SERVER_KEY'),
        'sender_id' => env('FCM_SENDER_ID'),
        'project_id' => env('FCM_PROJECT_ID', 'smileon-hackathon'),
        'service_account_json' => env('FCM_SERVICE_ACCOUNT_JSON'),
    ],

    'pinata' => [
        'api_key' => env('PINATA_API_KEY'),
        'secret_key' => env('PINATA_SECRET_KEY'),
    ],

];

