<div align="center">

<img src="smileon-mobileapps/assets/icons/smileon-border.png" alt="SmileOn Logo" height="80"/>

### Photobox Anywhere, Anytime.

*Capture your moments, create your memories, and keep them with you.*

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

## 🏗️ Architecture & Tech Stack

| Layer | Technology |
|---|---|
| **Mobile App** | Flutter (Dart) |
| **Blockchain** | Monad Testnet |
| **Authentication** | Dynamic.xyz (Email, Google, Wallet) |
| **Storage** | Google Drive API |
| **State Management** | flutter_riverpod |
| **Wallet Integration** | Dynamic SDK for Flutter |

---

## 🌐 Monad Integration

SmileOn is built natively for **Monad**, leveraging its high-throughput, EVM-compatible chain to make micropayments feel instant and painless.

**What's onchain:**
- 💳 Payment for premium frames
- 🎟️ Event Credit purchases by organizers
- 🖼️ Frame NFT ownership *(roadmap)*
- 🏆 Creator rewards *(roadmap)*

> Monad's speed and low fees make it the perfect backbone for a real-time photobox experience — users shouldn't feel a blockchain in between them and their memories.

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

## 📦 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- A Monad Testnet wallet
- Google Drive API credentials
- Dynamic.xyz Environment ID

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/smileon.git
cd smileon/smileon-mobileapps

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Environment Setup

Create a `.env` file or configure your `lib/core/config/` with:

```
DYNAMIC_ENVIRONMENT_ID=your_dynamic_env_id
MONAD_RPC_URL=https://testnet-rpc.monad.xyz
GOOGLE_DRIVE_CLIENT_ID=your_google_client_id
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
