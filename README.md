<div align="center">

<img src="smileon-mobileapps/assets/icons/smileon-border.png" alt="SmileOn Logo" height="80"/>

### Photobox Anywhere, Anytime.

*Capture your moments, create your memories, and keep them with you.*

<img src="picture/cover_readme_smileon_github_animation.gif" alt="SmileOn Banner" width="100%"/>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Monad](https://img.shields.io/badge/Network-Monad_Testnet-836EF9?style=for-the-badge)](https://monad.xyz)
[![Dynamic](https://img.shields.io/badge/Auth-Dynamic.xyz-000000?style=for-the-badge)](https://dynamic.xyz)
[![Google Drive](https://img.shields.io/badge/Storage-Google_Drive-4285F4?style=for-the-badge&logo=googledrive)](https://drive.google.com)
[![Status](https://img.shields.io/badge/Status-Active_Development-22c55e?style=for-the-badge)]()

</div>

---

## 🌟 Overview

**SmileOn** is a digital photobox application designed to make the photo experience simpler, more joyful, and effortlessly shareable. It merges the nostalgia of modern photobox experiences with cloud storage and **onchain payments on Monad**.

SmileOn is currently live on **Monad Testnet** and provides two core modes: **Personal Mode** and **Event Mode**.

> **Why SmileOn?**
> Because every memory deserves to be captured beautifully — and owned permanently.

---

## 🌐 Live Deployments & Smart Contracts

| Component | Status | Production Link / Contract Address | Description |
| :--- | :---: | :--- | :--- |
| **Frontend** | ![Live](https://img.shields.io/badge/Status-LIVE-success?style=flat-square) | [smileon-dapps.my.id](https://smileon-dapps.my.id) | Web DApp & Event Landing Portal (Next.js) |
| **Backend** | ![Live](https://img.shields.io/badge/Status-LIVE-success?style=flat-square) | [api.smileon-dapps.my.id](https://api.smileon-dapps.my.id/api/health) | REST API & Storage Engine (Laravel 11 & PostgreSQL) |
| **Smart Contract (Payment)** | ![Live](https://img.shields.io/badge/Monad-LIVE-836EF9?style=flat-square) | [`0xFAB484e78053e3FE88351A6a8A9dD545bb6a41ff`](https://testnet.monadexplorer.com/address/0xFAB484e78053e3FE88351A6a8A9dD545bb6a41ff) | `SmileOnPaymentHub` — Monad Testnet (`10143`) |
| **Smart Contract (NFT)** | ![Live](https://img.shields.io/badge/Monad-LIVE-836EF9?style=flat-square) | [`0xd685CCC9EF93b027e0D1EF05d4eDf83EC0385d48`](https://testnet.monadexplorer.com/address/0xd685CCC9EF93b027e0D1EF05d4eDf83EC0385d48) | `SmileOnNFT` (ERC-721) — Monad Testnet (`10143`) |

---

## ✨ Key Features

- 📷 **In-app camera** — Take photos directly within the app, no external camera needed
- 🖼️ **Frames & Layouts** — Choose from a variety of frames and photostrip layouts
- ✏️ **Edit & Preview** — Crop, adjust, and preview your final photostrip before saving
- ☁️ **Google Drive Storage** — Automatically save your photos to the cloud
- ⛓️ **Onchain Payments** — Pay for premium frames and features using Monad
- 🎉 **Event Mode** — Host photo events with a credit-based system
- 🎨 **GIF Support** — Animate your photostrip memories *(where available)*
- 🔐 **Secure Auth** — Login via Email, Google, or Web3 Wallet (powered by Dynamic.xyz)

---

## 🚀 How It Works

### Personal Mode

For users who want to use the photobox independently.

```
Take Photos
    ↓
Choose Frame / Edit
    ↓
Preview Final Result
    ↓
Download (Free) or Pay for Premium (Monad)
    ↓
Save to Google Drive
```

- **Free frames** → Download immediately, no payment required.
- **Premium frames** → Pay via Monad wallet to unlock and download.

---

### Event Mode

For organizers who want to provide a photobox experience at their events.

```
Organizer creates Event
    ↓
Organizer purchases Photo Credits (onchain via Monad)
    ↓
Guests scan QR Code / join Event
    ↓
Guests take photos (credits are consumed per session)
    ↓
Photos saved to Google Drive
```

**Photo Credits System:**
| | |
|---|---|
| **Event Credits** | 300 |
| **Used** | 127 |
| **Remaining** | 173 |

> One credit = one photobox session. A session can include multiple shots and produce one final photostrip.

---

### 📱 Event Mode — Detailed Mobile Flow (4 Steps)

When a guest starts a photo session, the **mobile screen** guides them through 4 sequential steps:

```
Step 1 — Waiting for Session
   Waiting view: event info, frame preview, 4-dot session stepper.
   Auto-navigates to Step 2 after a brief standby.
    ↓
Step 2 — Start Photo (Countdown)
   Animated circular countdown (3 → 2 → 1).
   Ring sweeps 0° → 360° per number with sparkle particles.
   Auto-navigates to Step 3 when countdown finishes.
    ↓
Step 3 — Taking Photos
   Shows 4 photo slots in a 9:16 photostrip ratio.
   Captured slots display the photo; pending slots show a ghost overlay with dashed spinner.
   4-segment horizontal progress bar reflects current session progress.
    ↓
Step 4 — Session Complete (All Done)
   Session complete confirmation. [In Progress]
```

> **Two-device setup**: The camera runs on a **tablet/PC** (`HorizontalActiveCamScreen`), while the guest's **mobile phone** displays the step-by-step flow above.

---

## 🏗️ Architecture & Tech Stack

| Layer | Technology | Description |
|---|---|---|
| **Mobile App** | Flutter (Dart 3.x), Riverpod | Two-device camera controller & guest companion app |
| **Blockchain** | Monad Testnet (Chain ID 10143) | Sub-second execution for micropayments & NFT minting |
| **Smart Contracts** | Solidity ^0.8.24, OpenZeppelin, Hardhat | `SmileOnPaymentHub.sol` & `SmileOnNFT.sol` (Sourcify Verified) |
| **Indexing** | Envio HyperIndex / HyperSync (GraphQL) | High-speed batch block event indexing & webhooks |
| **Backend API** | Laravel 11, PHP, MySQL/PostgreSQL | Dual-Rail instant verifier, outbox pattern, auth & quotas |
| **Authentication** | Dynamic.xyz | Multi-modal login: Google Social Login, Email, Embedded Wallet |
| **Storage** | Google Drive API & Cloudflare R2 | Automated photostrip cloud backup & high-res sync |

### 📁 Repository Structure

```
SmileOn/
├── smileon-mobileapps/     # Flutter mobile application (Personal & Event Photobox)
├── smileon-smartcontract/   # Hardhat smart contracts (PaymentHub, NFT, unit tests, deployment)
├── smileon-backend/        # Laravel REST API (Dual-Rail verifier, webhooks, orders)
├── smileon-indexer/        # Envio HyperIndex indexer configuration & event handlers
└── docs/                   # Architectural blueprints & Monad implementation plans
```

### 📐 Two-Device Architecture

SmileOn uses a **dual-screen design** where the camera device and guest's phone work in tandem:

```
┌────────────────────────┐     ┌─────────────────────────┐
│   Tablet / Computer    │     │     Guest's Mobile       │
│  HorizontalActiveCam   │     │   Vertical Event Steps   │
│  ────────────────────  │     │  ─────────────────────── │
│  • Live camera preview │     │  • Step 1: Waiting view  │
│  • 4-shot capture      │ ←── │  • Step 2: Countdown     │
│  • Photostrip render   │     │  • Step 3: Taking photos │
│  • Frame overlay       │     │  • Step 4: All done      │
└────────────────────────┘     └─────────────────────────┘
```

### 🧩 Reusable UI Component Library

SmileOn ships a dedicated design system under `lib/core/components/` with 21+ shared widgets:

| Component | Description |
|---|---|
| `SmileButton` | Primary CTA button with pink gradient |
| `SmileToast` | Success / warning / error toast notifications |
| `SmileDialog` | Confirmation & info modal dialogs |
| `SmileCard` | General-purpose content card |
| `SmileCircularProgressBar` | Animated loading indicator |
| `SmileChooseFrame` | Frame picker (horizontal & vertical variants) |
| `SmileSliderViewFrame` | Horizontal frame carousel |
| `SmileDialogPreviewPhotostrip` | In-app photostrip preview dialog |
| `SmileGlassmorphismTabs` | Frosted-glass tab switcher |
| `SmilePromoCard` | Promotional banner card |
| `SmileCtaCard` | Event & activity call-to-action cards |

---

## 🌐 Monad Testnet Integration & Smart Contracts

SmileOn is built natively for **Monad Testnet (Chain ID: 10143)**, leveraging Monad's 10,000 TPS and 1-second block time to provide instant onchain checkout for photobox sessions, credit top-ups, and commemorative NFTs.

### 📜 Verified Smart Contracts (Full Match on MonadExplorer)

| Smart Contract | Address | Verification |
|---|---|:---:|
| **SmileOnPaymentHub** | [`0xFAB484e78053e3FE88351A6a8A9dD545bb6a41ff`](https://testnet.monadexplorer.com/contracts/full_match/10143/0xFAB484e78053e3FE88351A6a8A9dD545bb6a41ff/) | ✅ Full Match (Sourcify) |
| **SmileOnNFT (ERC-721)** | [`0xd685CCC9EF93b027e0D1EF05d4eDf83EC0385d48`](https://testnet.monadexplorer.com/contracts/full_match/10143/0xd685CCC9EF93b027e0D1EF05d4eDf83EC0385d48/) | ✅ Full Match (Sourcify) |
| **Treasury & Deployer** | `0xFeff727205Fe524A3A8A16C404FeC9Cfe4124aCd` | — |

### 💰 Onchain Pricing Matrix (Standard Rates)

| Item / Package | Onchain MON Price | Item ID Hash | Equivalent IDR | Details |
|---|:---:|---|:---:|---|
| **1 Single Photo Session** | **`0.80 MON`** | `keccak256("PHOTO_SESSION_STANDARD")` | Rp 25.000 | 1 full photostrip session with instant print & digital download |
| **50 Photo Credits Package** | **`2.50 MON`** | `keccak256("CREDIT_50")` | Rp 78.000 | Voucher package (~0.05 MON / photo) |
| **100 Photo Credits Package** | **`4.50 MON`** | `keccak256("CREDIT_100")` | Rp 140.000 | Most popular voucher package (~0.045 MON / photo) |
| **200 Photo Credits Package** | **`8.50 MON`** | `keccak256("CREDIT_200")` | Rp 265.000 | Community & VIP membership package |
| **Wedding / Event Mode (300 Quota)** | **`15.00 MON`** | `keccak256("EVENT_WEDDING_300")` | Rp 470.000 | Dedicated event package for wedding & corporate photobooths |

> **Dynamic Pricing & Rate Updates**: Contracts support `setPriceTier` for owner rate updates and `payCustom(orderRef, itemId)` for real-time oracle rate conversions.

### ⚡ Dual-Rail Payment Verification Architecture

To guarantee both a **sub-second user experience** and **100% financial auditability**, SmileOn implements a Dual-Rail verification engine:

```
                       User Taps "Pay with Monad"
                                   │
                                   ▼
                       Sign & Broadcast Tx (Dynamic)
                                   │
                    ┌──────────────┴──────────────┐
                    ▼                             ▼
       [RAIL 1: INSTANT OPTIMISTIC]   [RAIL 2: ENVIO ASYNC GUARANTEE]
       Mobile App triggers:           Envio HyperSync indexes block
       POST /api/v1/payments/         event `PaymentReceived`
       verify-monad                   and fires webhook:
                    │                 POST /api/v1/webhooks/
       Backend queries RPC node       payment/monad
       `eth_getTransactionReceipt`                  │
       Status == 1 -> PAID (< 1s)!    Guarantees order completion
       Instant photo download!        even if mobile disconnects!
```

1. **Rail 1 (Instant RPC Verifier)**: Direct JSON-RPC `eth_getTransactionReceipt` query to `https://testnet-rpc.monad.xyz` via `OrderController@verifyMonad`. Verified in under 1 second.
2. **Rail 2 (Envio HyperIndex Indexer)**: Production-grade indexer in [`smileon-indexer/`](smileon-indexer) capturing `PaymentReceived`, `FundsWithdrawn`, and `PriceTierUpdated` events via Monad HyperSync.

---

## 🗺️ Roadmap

### ✅ Current (Monad Testnet)
- [x] Personal Mode — full photo session flow
- [x] Event Mode — credit-based event photobox
- [x] Google Drive integration
- [x] Onchain payments via Monad
- [x] Authentication (Email, Wallet, Google Social Login)
- [x] Frame selection & photostrip layouts

### 🔜 Upcoming
- [ ] **Creator Mode** — Designers can upload and monetize custom frames
- [ ] **Frame NFTs** — Own a frame as an NFT; earn royalties when others use it
- [ ] **Referral & Creator Rewards** — Earn MONAD by bringing creators and events onboard
- [ ] **AI-Powered Photobox** — AI backgrounds, filters, and style transfers
- [ ] **Expanded Onchain Creator Economy** — Full marketplace for frames and themes

---

## 🎨 Frames & Photobox Layouts

SmileOn supports various frame types and photostrip layouts. Creators can design and contribute:

- **Single Shot** frames
- **Multi-photo strip** layouts (2×, 3×, 4×)
- **Branded event frames** for corporate or community events
- **Seasonal & themed** frames

---

## 👥 Stakeholder Model

```
┌─────────────┐     ┌──────────────┐     ┌────────────────┐
│    Users    │     │   Creators   │     │   Organizers   │
│  (Guests)   │     │  (Designers) │     │ (Event Hosts)  │
└──────┬──────┘     └──────┬───────┘     └───────┬────────┘
       │                   │                     │
       ▼                   ▼                     ▼
  Take photos         Design frames        Create events
  Pay for premium     Earn royalties       Buy photo credits
  Save to Drive       Upload to SmileOn    Distribute access

                    ┌──────────────┐
                    │     Monad    │
                    │  (Payments + │
                    │  Ownership)  │
                    └──────────────┘
```

> **Users** capture memories. **Creators** craft visual experiences. **Events** distribute photobox access through credits. **Monad** powers the payment and ownership infrastructure.

---

## 🔐 Authentication

SmileOn uses **Dynamic.xyz** for a seamless multi-modal auth experience:

| Method | Status |
|---|---|
| 📧 Email (magic link / OTP) | ✅ Available |
| 🦊 Web3 Wallet (MetaMask, etc.) | ✅ Available |
| 🔵 Google Social Login | ✅ Available |

---

## 🌍 Multi-Language Support

SmileOn supports **Bahasa Indonesia** and **English** out of the box, managed through a lightweight in-app translation system (`lib/core/localization/app_translations.dart`).

| Language | Code | Status |
|---|---|---|
| 🇮🇩 Bahasa Indonesia | `id` | ✅ Default |
| 🇬🇧 English | `en` | ✅ Available |

Language can be switched from **Settings → Language** within the app at any time without restarting.

---

## 📦 Getting Started

### Prerequisites

- **Mobile**: Flutter SDK `>=3.0.0`, Dart SDK `>=3.0.0`
- **Smart Contracts**: Node.js `>=18`, npm / pnpm, Hardhat
- **Indexer**: `envio@3.0.0-alpha.21`, pnpm
- **Backend**: PHP `>=8.2`, Composer, MySQL / PostgreSQL
- A Monad Testnet wallet (with testnet MON from faucet)
- Dynamic.xyz Environment ID & Google Drive API credentials

---

### 1. Mobile Application (`smileon-mobileapps`)

```bash
cd smileon-mobileapps
flutter pub get
flutter run
```

Configure `.env` in `smileon-mobileapps/`:
```env
DYNAMIC_ENVIRONMENT_ID=your_dynamic_env_id
MONAD_RPC_URL=https://testnet-rpc.monad.xyz
GOOGLE_DRIVE_CLIENT_ID=your_google_client_id
```

---

### 2. Smart Contracts (`smileon-smartcontract`)

```bash
cd smileon-smartcontract
npm install

# Run unit tests (14/14 tests covering PaymentHub & NFT)
npx hardhat test

# Deploy to Monad Testnet
npx hardhat run scripts/deploy.ts --network monadTestnet
```

---

### 3. Envio HyperIndex Indexer (`smileon-indexer`)

```bash
cd smileon-indexer
pnpm install
pnpm codegen
pnpm start
# GraphQL endpoint: http://localhost:8080/v1/graphql
```

---

### 4. Backend REST API (`smileon-backend`)

```bash
cd smileon-backend
composer install
php artisan migrate
php artisan serve
```

Configured Monad environment in `smileon-backend/.env`:
```env
MONAD_CHAIN_ID=10143
MONAD_RPC_URL=https://testnet-rpc.monad.xyz
MONAD_PAYMENT_HUB_ADDRESS=0xFAB484e78053e3FE88351A6a8A9dD545bb6a41ff
MONAD_NFT_ADDRESS=0xd685CCC9EF93b027e0D1EF05d4eDf83EC0385d48
```

---

## 📸 Screenshots

> *SmileOn — where every session is a memory worth keeping.*

---

## 📄 License

This project is built for the Monad hackathon ecosystem.

---

## ⚠️ Disclaimer

SmileOn is currently a **testnet product**. Blockchain transactions, balances, NFTs, and related onchain functionality may change during development.

Creator Mode, referral system, creator rewards, NFT functionality, and other roadmap items are **planned features** and may not be available in the current version.

---

<div align="center">

**Made for More Smiles 😄**

*SmileOn 📸 — Photobox Anywhere, Anytime.*

</div>
