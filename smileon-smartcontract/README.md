# SmileOn Smart Contracts (Monad Testnet) 🟣✨

Smart Contract Payment Hub dan Commemorative Photostrip NFT untuk ekosistem **SmileOn Photobox**, dibangun khusus untuk **Monad Testnet** (`Chain ID: 10143`).

Dikembangkan dengan mengikuti standar resmi **Monad Skills (`monskills`)** dari repository `therealharpaljadeja/monskills`.

---

## 📋 Ikhtisar Kontrak

### 1. `SmileOnPaymentHub.sol`
Payment Hub on-chain terpusat untuk seluruh alur transaksi ekosistem SmileOn:
- **Single Photo Session**: Pembayaran cetak photostrip satuan (misal `0.80 MON`).
- **Photo Voucher / Credits**: Pembelian paket kuota hemat (misal 50 foto `2.50 MON`, 100 foto `4.50 MON`).
- **Event Mode Quota**: Top-up kuota oleh EO/Penyelenggara untuk booth wedding/birthday (misal `15.00 MON`).
- **Custom Payment**: Fleksibilitas pembayaran dinamis terverifikasi backend.
- **Anti-Replay Protection**: Tracking `orderRef` untuk mencegah duplikasi pembayaran.
- **Optimized for Monad Gas**: Minimal storage writes untuk efisiensi gas opcode Monad.
- **Envio Indexer Ready**: Event `PaymentReceived` terindeks lengkap (`orderRef`, `payer`, `category`, `amount`).
- **Security**: Menggunakan OpenZeppelin v5.2 `Ownable2Step`, `ReentrancyGuard`, dan `Pausable`.

### 2. `SmileOnNFT.sol`
Koleksi NFT Photostrip kenangan digital (ERC-721):
- Minting sertifikat digital berkesan untuk setiap sesi photobox SmileOn.
- Menyimpan metadata sesi (`sessionId`, `frameId`, `timestamp`, dan tokenURI IPFS/Arweave).

---

## ⚡ Spesifikasi Jaringan Monad Testnet

| Parameter | Nilai |
|---|---|
| **Network Name** | Monad Testnet |
| **Chain ID** | `10143` (`0x279f`) |
| **RPC Endpoint** | `https://testnet-rpc.monad.xyz` |
| **Block Explorer** | [https://testnet.monadexplorer.com](https://testnet.monadexplorer.com) |
| **Currency Symbol** | `MON` |
| **EVM Target** | `cancun` (Solidity 0.8.24) |

---

## 🚀 Panduan Menjalankan

### 1. Instalasi Dependensi
```bash
npm install
```

### 2. Konfigurasi Lingkungan (`.env`)
Salin file `.env.example` menjadi `.env`:
```bash
cp .env.example .env
```
Isi variabel berikut:
```env
MONAD_TESTNET_RPC_URL="https://testnet-rpc.monad.xyz"
PRIVATE_KEY="your_private_key_without_0x_prefix"
TREASURY_ADDRESS="0xYourTreasuryWalletAddress"
```

### 3. Kompilasi Kontrak
```bash
npm run compile
```

### 4. Menjalankan Unit Tests
```bash
npm test
```
*Hasil: 14 passing unit tests mencakup seluruh alur pembayaran, error handling, pausable, dan NFT minting.*

### 5. Deployment ke Monad Testnet
Pastikan wallet deployer memiliki saldo `MON` testnet dari official Monad Faucet:
```bash
npm run deploy:testnet
```

File manifest hasil deploy akan otomatis tersimpan di `deployed-addresses.json`.

---

## 🛡️ Aturan Monskills yang Diterapkan

1. **`.monskills` Metadata**: Menyimpan tag resmi `built-with=monskills` dan `chain=monad-testnet`.
2. **`tsconfig.json` Target ES2020**: Menghindari BigInt literal issue (`TS2737`) pada viem/wagmi.
3. **OpenZeppelin Contracts v5.2**: Standar industri tanpa membuat kontrak ownership/ERC721 dari nol.
4. **Monad Gas Considerations**:
   - Monad menagih gas berdasarkan `gas_limit` (bukan gas used).
   - Cold state access opcodes di-pricing lebih tinggi (+6,000 gas), sehingga struktur kontrak dirancang seminimal mungkin melakukan cold slot lookups.
   - Fixed 21,000 gas limit untuk native MON transfer.

---

## 📄 Lisensi
MIT License - SmileOn Team.
