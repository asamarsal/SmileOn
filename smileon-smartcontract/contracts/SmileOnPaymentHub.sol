// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title SmileOnPaymentHub
 * @author SmileOn Team
 * @notice Centralized On-chain Payment Hub for the SmileOn Photobox Ecosystem on Monad Testnet (Chain ID 10143).
 * @dev Handles native MON payments for single photo sessions, event vouchers, quota top-ups, and custom orders.
 * Emits PaymentReceived events indexed by orderRef and payer, compatible with Envio HyperSync indexer.
 */
contract SmileOnPaymentHub is Ownable2Step, ReentrancyGuard, Pausable {

    // --- ENUMS & STRUCTS ---

    enum PaymentCategory {
        SINGLE_SESSION,    // 0: Bayar 1 sesi cetak photostrip satuan (misal 0.80 MON)
        VOUCHER_PURCHASE,  // 1: Beli voucher paket kuota / member (misal 2.50, 4.50 MON)
        EVENT_QUOTA,       // 2: Top-up kuota event / wedding mode (misal 15.00 MON)
        NFT_MINT_FEE       // 3: Biaya cetak digital koleksi NFT kenangan
    }

    struct PriceTier {
        uint256 priceInWei; // Harga dalam WEI (1 MON = 1e18 WEI)
        bool isActive;
        string description;
    }

    // --- CONSTANTS & STATE VARIABLES ---

    uint256 public constant MONAD_CHAIN_ID = 10143;
    address payable public treasuryAddress;

    // Mapping item identifier hash -> PriceTier
    mapping(bytes32 => PriceTier) public itemPrices;

    // Mapping orderRef -> processed status to prevent replay on-chain
    mapping(string => bool) public processedOrders;

    // --- EVENTS (Ditangkap oleh Envio HyperSync & Backend Webhook) ---

    event PaymentReceived(
        string indexed orderRef,
        address indexed payer,
        PaymentCategory indexed category,
        uint256 amount,
        bytes32 itemId,
        uint256 timestamp,
        uint256 chainId
    );

    event PriceTierUpdated(
        bytes32 indexed itemId,
        uint256 priceInWei,
        bool isActive,
        string description
    );

    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // --- CUSTOM ERRORS ---

    error InvalidAmount(uint256 sent, uint256 requiredAmount);
    error OrderAlreadyProcessed(string orderRef);
    error ItemInactiveOrNotFound(bytes32 itemId);
    error ZeroAddress();
    error TransferFailed();
    error EmptyOrderRef();

    // --- CONSTRUCTOR ---

    constructor(
        address initialOwner,
        address payable _treasury
    ) Ownable(initialOwner) {
        if (_treasury == address(0)) revert ZeroAddress();
        treasuryAddress = _treasury;

        // Default item tiers for SmileOn Photobox Ecosystem
        // 1. Sesi Foto Satuan: 0.80 MON
        _setPriceTier(keccak256("PHOTO_SESSION_STANDARD"), 0.80 ether, true, "Standard Photo Session (1 Strip)");
        // 2. Paket Kredit Foto (50 Foto): 2.50 MON
        _setPriceTier(keccak256("CREDIT_50"), 2.50 ether, true, "50 Photo Credit Package");
        // 3. Paket Kredit Foto (100 Foto): 4.50 MON
        _setPriceTier(keccak256("CREDIT_100"), 4.50 ether, true, "100 Photo Credit Package");
        // 4. Paket Wedding Event (300 Kuota): 15.00 MON
        _setPriceTier(keccak256("EVENT_WEDDING_300"), 15.00 ether, true, "Wedding Event Mode (300 Quota)");
    }

    // --- USER PAYMENT FUNCTIONS ---

    /**
     * @notice Bayar 1 sesi foto photobox satuan (0.80 MON).
     * @param orderRef Referensi order unik dari backend (misal: "ORD-SSN-99124").
     * @param itemId Identifier paket foto (misal keccak256("PHOTO_SESSION_STANDARD")).
     */
    function payForSession(
        string calldata orderRef,
        bytes32 itemId
    ) external payable whenNotPaused nonReentrant {
        _processPayment(orderRef, itemId, PaymentCategory.SINGLE_SESSION);
    }

    /**
     * @notice Bayar pembelian voucher paket foto / membership.
     * @param orderRef Referensi order unik dari backend (misal: "ORD-VCHR-55102").
     * @param itemId Identifier paket voucher (misal keccak256("CREDIT_100")).
     */
    function payForVoucher(
        string calldata orderRef,
        bytes32 itemId
    ) external payable whenNotPaused nonReentrant {
        _processPayment(orderRef, itemId, PaymentCategory.VOUCHER_PURCHASE);
    }

    /**
     * @notice Top-up kuota event mode aktif langsung oleh penyelenggara acara.
     * @param orderRef Referensi order unik (misal: "ORD-EVT-77201").
     * @param itemId Identifier paket event (misal keccak256("EVENT_WEDDING_300")).
     */
    function payForEventQuota(
        string calldata orderRef,
        bytes32 itemId
    ) external payable whenNotPaused nonReentrant {
        _processPayment(orderRef, itemId, PaymentCategory.EVENT_QUOTA);
    }

    /**
     * @notice Pembayaran custom dinamis berdasarkan harga yang ditentukan backend.
     * @param orderRef Referensi order unik dari backend.
     * @param category Kategori pembayaran.
     * @param expectedAmount Jumlah minimum MON yang diharapkan dalam Wei.
     */
    function payCustom(
        string calldata orderRef,
        PaymentCategory category,
        uint256 expectedAmount
    ) external payable whenNotPaused nonReentrant {
        if (bytes(orderRef).length == 0) revert EmptyOrderRef();
        if (processedOrders[orderRef]) revert OrderAlreadyProcessed(orderRef);
        if (msg.value < expectedAmount || msg.value == 0) revert InvalidAmount(msg.value, expectedAmount);

        processedOrders[orderRef] = true;

        emit PaymentReceived(
            orderRef,
            msg.sender,
            category,
            msg.value,
            keccak256(bytes(orderRef)),
            block.timestamp,
            MONAD_CHAIN_ID
        );
    }

    // --- INTERNAL HELPER ---

    function _processPayment(
        string calldata orderRef,
        bytes32 itemId,
        PaymentCategory category
    ) internal {
        if (bytes(orderRef).length == 0) revert EmptyOrderRef();
        if (processedOrders[orderRef]) revert OrderAlreadyProcessed(orderRef);

        PriceTier memory tier = itemPrices[itemId];
        if (!tier.isActive) revert ItemInactiveOrNotFound(itemId);
        if (msg.value < tier.priceInWei) revert InvalidAmount(msg.value, tier.priceInWei);

        processedOrders[orderRef] = true;

        emit PaymentReceived(
            orderRef,
            msg.sender,
            category,
            msg.value,
            itemId,
            block.timestamp,
            MONAD_CHAIN_ID
        );
    }

    // --- ADMIN & CONFIGURATION ---

    function setPriceTier(
        bytes32 itemId,
        uint256 priceInWei,
        bool isActive,
        string calldata description
    ) external onlyOwner {
        _setPriceTier(itemId, priceInWei, isActive, description);
    }

    function _setPriceTier(
        bytes32 itemId,
        uint256 priceInWei,
        bool isActive,
        string memory description
    ) internal {
        itemPrices[itemId] = PriceTier({
            priceInWei: priceInWei,
            isActive: isActive,
            description: description
        });
        emit PriceTierUpdated(itemId, priceInWei, isActive, description);
    }

    function setTreasury(address payable _newTreasury) external onlyOwner {
        if (_newTreasury == address(0)) revert ZeroAddress();
        address old = treasuryAddress;
        treasuryAddress = _newTreasury;
        emit TreasuryUpdated(old, _newTreasury);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Penarikan seluruh saldo kas kontrak ke Treasury SmileOn.
     */
    function withdrawAll() external nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert InvalidAmount(0, 1);

        (bool success, ) = treasuryAddress.call{value: balance}("");
        if (!success) revert TransferFailed();

        emit FundsWithdrawn(treasuryAddress, balance);
    }

    /**
     * @notice Penarikan sebagian saldo kas kontrak ke Treasury SmileOn.
     */
    function withdrawAmount(uint256 amount) external nonReentrant {
        if (amount == 0 || amount > address(this).balance) revert InvalidAmount(amount, address(this).balance);

        (bool success, ) = treasuryAddress.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit FundsWithdrawn(treasuryAddress, amount);
    }

    // Fallback receive
    receive() external payable {}
}
