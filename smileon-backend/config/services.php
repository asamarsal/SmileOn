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
        'explorer_url' => env('MONAD_EXPLORER_URL', 'https://testnet.monadexplorer.com'),
    ],

];
