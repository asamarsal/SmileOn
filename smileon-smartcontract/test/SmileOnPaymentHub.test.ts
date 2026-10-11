import { expect } from "chai";
import { ethers } from "hardhat";
import { SmileOnPaymentHub, SmileOnNFT } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("SmileOn Monad Smart Contracts", function () {
  let paymentHub: SmileOnPaymentHub;
  let nft: SmileOnNFT;
  let owner: SignerWithAddress;
  let treasury: SignerWithAddress;
  let user: SignerWithAddress;
  let otherUser: SignerWithAddress;

  const ITEM_SESSION = ethers.keccak256(ethers.toUtf8Bytes("PHOTO_SESSION_STANDARD"));
  const ITEM_VOUCHER_100 = ethers.keccak256(ethers.toUtf8Bytes("CREDIT_100"));
  const ITEM_EVENT_WEDDING = ethers.keccak256(ethers.toUtf8Bytes("EVENT_WEDDING_300"));

  beforeEach(async function () {
    [owner, treasury, user, otherUser] = await ethers.getSigners();

    const PaymentHubFactory = await ethers.getContractFactory("SmileOnPaymentHub");
    paymentHub = (await PaymentHubFactory.deploy(owner.address, treasury.address)) as SmileOnPaymentHub;
    await paymentHub.waitForDeployment();

    const NFTFactory = await ethers.getContractFactory("SmileOnNFT");
    nft = (await NFTFactory.deploy(owner.address)) as SmileOnNFT;
    await nft.waitForDeployment();
  });

  describe("SmileOnPaymentHub", function () {
    it("Harus memiliki konfigurasi awal yang benar", async function () {
      expect(await paymentHub.owner()).to.equal(owner.address);
      expect(await paymentHub.treasuryAddress()).to.equal(treasury.address);
      expect(await paymentHub.MONAD_CHAIN_ID()).to.equal(10143n);

      const sessionTier = await paymentHub.itemPrices(ITEM_SESSION);
      expect(sessionTier.priceInWei).to.equal(ethers.parseEther("0.80"));
      expect(sessionTier.isActive).to.be.true;
    });

    it("User dapat membayar 1 sesi foto photobox (0.80 MON) dan memancarkan event PaymentReceived", async function () {
      const orderRef = "ORD-SSN-TEST-001";
      const price = ethers.parseEther("0.80");

      await expect(
        paymentHub.connect(user).payForSession(orderRef, ITEM_SESSION, { value: price })
      )
        .to.emit(paymentHub, "PaymentReceived")
        .withArgs(
          orderRef,
          user.address,
          0, // PaymentCategory.SINGLE_SESSION
          price,
          ITEM_SESSION,
          await ethers.provider.getBlock("latest").then((b) => b!.timestamp + 1),
          10143n
        );

      expect(await paymentHub.processedOrders(orderRef)).to.be.true;
    });

    it("Harus gagal jika pembayaran sesi foto kurang dari harga tier", async function () {
      const orderRef = "ORD-SSN-FAIL-001";
      const insufficientPrice = ethers.parseEther("0.50");

      await expect(
        paymentHub.connect(user).payForSession(orderRef, ITEM_SESSION, { value: insufficientPrice })
      ).to.be.revertedWithCustomError(paymentHub, "InvalidAmount");
    });

    it("Harus gagal jika orderRef yang sama dibayar kembali (Anti-Replay)", async function () {
      const orderRef = "ORD-SSN-DUP-001";
      const price = ethers.parseEther("0.80");

      await paymentHub.connect(user).payForSession(orderRef, ITEM_SESSION, { value: price });

      await expect(
        paymentHub.connect(user).payForSession(orderRef, ITEM_SESSION, { value: price })
      ).to.be.revertedWithCustomError(paymentHub, "OrderAlreadyProcessed");
    });

    it("User dapat membayar voucher kuota 100 foto (4.50 MON)", async function () {
      const orderRef = "ORD-VCHR-100-001";
      const price = ethers.parseEther("4.50");

      await expect(
        paymentHub.connect(user).payForVoucher(orderRef, ITEM_VOUCHER_100, { value: price })
      )
        .to.emit(paymentHub, "PaymentReceived")
        .withArgs(
          orderRef,
          user.address,
          1, // PaymentCategory.VOUCHER_PURCHASE
          price,
          ITEM_VOUCHER_100,
          await ethers.provider.getBlock("latest").then((b) => b!.timestamp + 1),
          10143n
        );
    });

    it("Penyelenggara event dapat membayar kuota wedding mode (15.00 MON)", async function () {
      const orderRef = "ORD-EVT-WEDDING-001";
      const price = ethers.parseEther("15.00");

      await expect(
        paymentHub.connect(user).payForEventQuota(orderRef, ITEM_EVENT_WEDDING, { value: price })
      )
        .to.emit(paymentHub, "PaymentReceived")
        .withArgs(
          orderRef,
          user.address,
          2, // PaymentCategory.EVENT_QUOTA
          price,
          ITEM_EVENT_WEDDING,
          await ethers.provider.getBlock("latest").then((b) => b!.timestamp + 1),
          10143n
        );
    });

    it("Owner dapat menarik dana ke Treasury", async function () {
      const orderRef = "ORD-WITHDRAW-001";
      const price = ethers.parseEther("0.80");

      await paymentHub.connect(user).payForSession(orderRef, ITEM_SESSION, { value: price });

      const treasuryBalanceBefore = await ethers.provider.getBalance(treasury.address);

      await expect(paymentHub.connect(owner).withdrawAll())
        .to.emit(paymentHub, "FundsWithdrawn")
        .withArgs(treasury.address, price);

      const treasuryBalanceAfter = await ethers.provider.getBalance(treasury.address);
      expect(treasuryBalanceAfter - treasuryBalanceBefore).to.equal(price);
    });

    it("Fungsi pause menghentikan pembayaran sementara", async function () {
      await paymentHub.connect(owner).pause();

      await expect(
        paymentHub.connect(user).payForSession("ORD-PAUSE-001", ITEM_SESSION, { value: ethers.parseEther("0.80") })
      ).to.be.revertedWithCustomError(paymentHub, "EnforcedPause");

      await paymentHub.connect(owner).unpause();

      await expect(
        paymentHub.connect(user).payForSession("ORD-PAUSE-001", ITEM_SESSION, { value: ethers.parseEther("0.80") })
      ).to.not.be.reverted;
    });

    it("User dapat membayar custom dinamis dengan payCustom", async function () {
      const orderRef = "ORD-CUSTOM-001";
      const customAmount = ethers.parseEther("1.25");

      await expect(
        paymentHub.connect(user).payCustom(orderRef, 0, customAmount, { value: customAmount })
      )
        .to.emit(paymentHub, "PaymentReceived")
        .withArgs(
          orderRef,
          user.address,
          0,
          customAmount,
          ethers.keccak256(ethers.toUtf8Bytes(orderRef)),
          await ethers.provider.getBlock("latest").then((b) => b!.timestamp + 1),
          10143n
        );

      expect(await paymentHub.processedOrders(orderRef)).to.be.true;
    });

    it("Harus gagal jika orderRef kosong pada payCustom", async function () {
      await expect(
        paymentHub.connect(user).payCustom("", 0, ethers.parseEther("1.0"), { value: ethers.parseEther("1.0") })
      ).to.be.revertedWithCustomError(paymentHub, "EmptyOrderRef");
    });

    it("Harus gagal jika itemId tidak aktif atau belum terdaftar", async function () {
      const invalidItem = ethers.keccak256(ethers.toUtf8Bytes("NON_EXISTING_ITEM"));
      await expect(
        paymentHub.connect(user).payForSession("ORD-ERR-ITEM", invalidItem, { value: ethers.parseEther("1.0") })
      ).to.be.revertedWithCustomError(paymentHub, "ItemInactiveOrNotFound");
    });

    it("Owner dapat memperbarui PriceTier dan Treasury address", async function () {
      const newPrice = ethers.parseEther("1.10");
      await expect(paymentHub.connect(owner).setPriceTier(ITEM_SESSION, newPrice, true, "Updated Price"))
        .to.emit(paymentHub, "PriceTierUpdated")
        .withArgs(ITEM_SESSION, newPrice, true, "Updated Price");

      const tier = await paymentHub.itemPrices(ITEM_SESSION);
      expect(tier.priceInWei).to.equal(newPrice);

      await expect(paymentHub.connect(owner).setTreasury(otherUser.address))
        .to.emit(paymentHub, "TreasuryUpdated")
        .withArgs(treasury.address, otherUser.address);

      expect(await paymentHub.treasuryAddress()).to.equal(otherUser.address);
    });

    it("Owner dapat menarik sebagian dana dengan withdrawAmount", async function () {
      await paymentHub.connect(user).payForSession("ORD-WITHDRAW-PARTIAL", ITEM_SESSION, { value: ethers.parseEther("0.80") });

      const withdrawAmount = ethers.parseEther("0.30");
      const initialTreasuryBal = await ethers.provider.getBalance(treasury.address);

      await expect(paymentHub.connect(owner).withdrawAmount(withdrawAmount))
        .to.emit(paymentHub, "FundsWithdrawn")
        .withArgs(treasury.address, withdrawAmount);

      const afterTreasuryBal = await ethers.provider.getBalance(treasury.address);
      expect(afterTreasuryBal - initialTreasuryBal).to.equal(withdrawAmount);
    });
  });

  describe("SmileOnNFT", function () {
    it("Owner dapat me-mint commemorative photostrip NFT ke user", async function () {
      const sessionId = "SSN-2026-VALENTINE-992";
      const frameId = 1;
      const tokenUri = "ipfs://QmSmileOnPhotoStripMetadata123";

      await expect(
        nft.connect(owner).mintPhotostrip(user.address, tokenUri, sessionId, frameId)
      )
        .to.emit(nft, "PhotostripMinted")
        .withArgs(1, user.address, sessionId, frameId, tokenUri);

      expect(await nft.ownerOf(1)).to.equal(user.address);
      expect(await nft.tokenURI(1)).to.equal(tokenUri);
      expect(await nft.totalSupply()).to.equal(1n);

      const details = await nft.photostripDetails(1);
      expect(details.sessionId).to.equal(sessionId);
      expect(details.frameId).to.equal(frameId);
    });
  });
});
