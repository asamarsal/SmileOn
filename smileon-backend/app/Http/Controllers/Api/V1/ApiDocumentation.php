<?php

namespace App\Http\Controllers\Api\V1;

use OpenApi\Attributes as OA;

#[OA\Info(version: "1.0.0", title: "SmileOn Backend API", description: "Dokumentasi resmi untuk backend photobox web3 SmileOn.")]
#[OA\Server(url: L5_SWAGGER_CONST_HOST, description: "Main API Server")]
#[OA\SecurityScheme(securityScheme: "BearerAuth", type: "http", scheme: "bearer", bearerFormat: "JWT")]
class ApiDocumentation
{

    #[OA\Post(path: "/api/v1/auth/google", summary: "Login via Google", tags: ["Auth"])]
    #[OA\Response(response: 200, description: "Success")]
    public function loginviaGoogle0() {}

    #[OA\Post(path: "/api/v1/auth/wallet", summary: "Login via Web3 Wallet", tags: ["Auth"])]
    #[OA\Response(response: 200, description: "Success")]
    public function loginviaWeb3Wallet1() {}

    #[OA\Get(path: "/api/v1/auth/me", summary: "Get User Profile", tags: ["Auth"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function getUserProfile2() {}

    #[OA\Patch(path: "/api/v1/auth/me", summary: "Update Profile", tags: ["Auth"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function updateProfile3() {}

    #[OA\Post(path: "/api/v1/auth/logout", summary: "Logout", tags: ["Auth"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function logout4() {}

    #[OA\Get(path: "/api/v1/auth/sessions", summary: "Get Active Sessions", tags: ["Auth"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function getActiveSessions5() {}

    #[OA\Delete(path: "/api/v1/auth/sessions/{id}", summary: "Revoke session", tags: ["Auth"], security: [["BearerAuth" => []]])]
    #[OA\PathParameter(name: "id", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Success")]
    public function revokesession6() {}

    #[OA\Get(path: "/api/v1/frames", summary: "List all frames", tags: ["Frames"])]
    #[OA\Response(response: 200, description: "Success")]
    public function listallframes7() {}

    #[OA\Get(path: "/api/v1/frames/{uuid}", summary: "Frame Detail", tags: ["Frames"])]
    #[OA\PathParameter(name: "uuid", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Success")]
    public function frameDetail8() {}

    #[OA\Post(path: "/api/v1/user/frames/save", summary: "Save favorite frame", tags: ["Frames"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function savefavoriteframe9() {}

    #[OA\Delete(path: "/api/v1/user/frames/{uuid}/unsave", summary: "Unsave favorite frame", tags: ["Frames"], security: [["BearerAuth" => []]])]
    #[OA\PathParameter(name: "uuid", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Success")]
    public function unsavefavoriteframe10() {}

    #[OA\Get(path: "/api/v1/user/frames/saved", summary: "Get favorite frames", tags: ["Frames"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function getfavoriteframes11() {}

    #[OA\Post(path: "/api/v1/frames/{uuid}/report", summary: "Report a frame", tags: ["Frames"], security: [["BearerAuth" => []]])]
    #[OA\PathParameter(name: "uuid", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Success")]
    public function reportaframe12() {}

    #[OA\Get(path: "/api/v1/events", summary: "Get organizer events", tags: ["Events"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function getorganizerevents13() {}

    #[OA\Post(path: "/api/v1/events", summary: "Create event", tags: ["Events"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function createevent14() {}

    #[OA\Post(path: "/api/v1/events/{uuid}/frames/custom", summary: "Upload custom frame", tags: ["Events"], security: [["BearerAuth" => []]])]
    #[OA\PathParameter(name: "uuid", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Success")]
    public function uploadcustomframe15() {}

    #[OA\Get(path: "/api/v1/events/join/{access_code}", summary: "Join event via QR", tags: ["Events"], security: [["BearerAuth" => []]])]
    #[OA\PathParameter(name: "access_code", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Success")]
    public function joineventviaQR16() {}

    #[OA\Get(path: "/api/v1/user/events/joined", summary: "History of joined events", tags: ["Events"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function historyofjoinedevents17() {}

    #[OA\Post(path: "/api/v1/booths/heartbeat", summary: "Booth telemetry heartbeat", tags: ["Events"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function boothtelemetryheartbeat18() {}

    #[OA\Post(path: "/api/v1/booths/revoke", summary: "Revoke booth remotely", tags: ["Events"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function revokeboothremotely19() {}

    #[OA\Post(path: "/api/v1/sessions/init", summary: "Initialize session", tags: ["Sessions"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function initializesession20() {}

    #[OA\Post(path: "/api/v1/sessions/{uuid}/start-photo", summary: "Start public session", tags: ["Sessions"], security: [["BearerAuth" => []]])]
    #[OA\PathParameter(name: "uuid", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Success")]
    public function startpublicsession21() {}

    #[OA\Post(path: "/api/v1/sessions/{uuid}/complete", summary: "Complete session", tags: ["Sessions"], security: [["BearerAuth" => []]])]
    #[OA\PathParameter(name: "uuid", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Success")]
    public function completesession22() {}

    #[OA\Post(path: "/api/v1/sessions/{uuid}/cancel", summary: "Cancel session", tags: ["Sessions"], security: [["BearerAuth" => []]])]
    #[OA\PathParameter(name: "uuid", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Success")]
    public function cancelsession23() {}

    #[OA\Post(path: "/api/v1/photos/presigned-url", summary: "Get presigned S3/R2 URL", tags: ["Sessions"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function getpresignedS3R2URL24() {}

    #[OA\Post(path: "/api/v1/photos/complete-upload", summary: "Confirm photo upload", tags: ["Sessions"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function confirmphotoupload25() {}

    #[OA\Get(path: "/api/v1/payment-methods", summary: "List active payment methods", tags: ["Payments"])]
    #[OA\Response(response: 200, description: "Success")]
    public function listactivepaymentmethods26() {}

    #[OA\Post(path: "/api/v1/orders", summary: "Checkout order", tags: ["Payments"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function checkoutorder27() {}

    #[OA\Post(path: "/api/v1/webhooks/payment/{provider}", summary: "Payment Webhook Inbox", tags: ["Payments"])]
    #[OA\PathParameter(name: "provider", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Success")]
    public function paymentWebhookInbox28() {}

    #[OA\Post(path: "/api/v1/loyalty/check-in", summary: "Daily check-in", tags: ["Loyalty"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function dailycheckin29() {}

    #[OA\Get(path: "/api/v1/loyalty/rewards", summary: "List rewards", tags: ["Loyalty"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function listrewards30() {}

    #[OA\Post(path: "/api/v1/loyalty/rewards/{id}/redeem", summary: "Redeem reward", tags: ["Loyalty"], security: [["BearerAuth" => []]])]
    #[OA\PathParameter(name: "id", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Success")]
    public function redeemreward31() {}

    #[OA\Get(path: "/api/v1/user/referral", summary: "Get referral code", tags: ["Loyalty"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function getreferralcode32() {}

    #[OA\Get(path: "/api/v1/merchandise/products", summary: "List physical products", tags: ["Merchandise"])]
    #[OA\Response(response: 200, description: "Success")]
    public function listphysicalproducts33() {}

    #[OA\Get(path: "/api/v1/user/shipping-addresses", summary: "List address book", tags: ["Merchandise"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function listaddressbook34() {}

    #[OA\Post(path: "/api/v1/user/shipping-addresses", summary: "Add address", tags: ["Merchandise"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function addaddress35() {}

    #[OA\Post(path: "/api/v1/merchandise/calculate-shipping", summary: "Calculate shipping cost", tags: ["Merchandise"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function calculateshippingcost36() {}

    #[OA\Post(path: "/api/v1/merchandise/orders", summary: "Order merchandise", tags: ["Merchandise"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function ordermerchandise37() {}

    #[OA\Post(path: "/api/v1/nft/mint", summary: "Mint NFT on-chain", tags: ["Web3"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function mintNFTonchain38() {}

    #[OA\Get(path: "/api/v1/user/collectibles", summary: "Digital Collectibles Gallery", tags: ["Web3"], security: [["BearerAuth" => []]])]
    #[OA\Response(response: 200, description: "Success")]
    public function digitalCollectiblesGallery39() {}

    #[OA\Post(path: "/api/v1/events/{uuid}/verify-nft-access", summary: "Token-gated check-in", tags: ["Web3"], security: [["BearerAuth" => []]])]
    #[OA\PathParameter(name: "uuid", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Success")]
    public function tokengatedcheckin40() {}

    #[OA\Post(path: "/api/v1/events/{uuid}/claim-nft-perk", summary: "Claim perk with NFT", tags: ["Web3"], security: [["BearerAuth" => []]])]
    #[OA\PathParameter(name: "uuid", required: true, schema: new OA\Schema(type: "string"))]
    #[OA\Response(response: 200, description: "Success")]
    public function claimperkwithNFT41() {}
}
