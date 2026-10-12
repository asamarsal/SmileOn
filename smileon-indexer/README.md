# ⚡ SmileOn Envio HyperIndex Indexer (Monad Testnet)

Indexer resmi berbasis **Envio HyperIndex / HyperSync** untuk meng-index smart contract **`SmileOnPaymentHub.sol`** di jaringan **Monad Testnet (Chain ID 10143)**.

---

## 📌 Smart Contract Terdaftar
- **Nama:** `SmileOnPaymentHub`
- **Network:** Monad Testnet (`10143`)
- **Alamat:** `0xFAB484e78053e3FE88351A6a8A9dD545bb6a41ff`
- **Explorer:** https://testnet.monadexplorer.com/address/0xFAB484e78053e3FE88351A6a8A9dD545bb6a41ff

---

## 🚀 Cara Menjalankan Secara Lokal

1. **Install dependensi & Generate Types:**
   ```bash
   cd smileon-indexer
   pnpm install
   pnpm codegen
   ```

2. **Jalankan Indexer:**
   ```bash
   pnpm start
   ```
   Indexer akan mensinkronkan block data secara instan melalui **Monad HyperSync** dan menyediakan endpoint GraphQL di:
   `http://localhost:8080/v1/graphql`

---

## ☁️ Cara Deploy ke Envio Cloud (Monad Production)

Sesuai skill resmi Monad (`indexer` skill):

1. Pastikan `envio-cloud` CLI dan `gh` CLI terpasang dan sudah login:
   ```bash
   envio-cloud login
   gh auth login
   ```

2. Deploy indexer:
   ```bash
   envio-cloud deploy
   ```
   Envio Cloud akan memberikan URL GraphQL publik serta dashboard pemantauan transaksi on-chain.
