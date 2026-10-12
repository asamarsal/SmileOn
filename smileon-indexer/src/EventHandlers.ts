/*
 * Event handlers for SmileOn Payment Hub smart contracts on Monad Testnet (Chain ID 10143)
 */
import { SmileOnPaymentHub } from "generated";

SmileOnPaymentHub.PaymentReceived.handler(async ({ event, context }) => {
  const entityId = `${event.transaction.hash}_${event.logIndex}`;

  const paymentEntity = {
    id: entityId,
    orderRef: event.params.orderRef,
    payer: event.params.payer,
    category: Number(event.params.category),
    amount: event.params.amount,
    itemId: event.params.itemId,
    timestamp: event.params.timestamp,
    chainId: event.params.chainId,
    txHash: event.transaction.hash,
    blockNumber: event.block.number,
  };

  context.Payment.set(paymentEntity);

  // Webhook forwarding ke Backend SmileOn (Rail 2)
  const webhookUrl = process.env.SMILEON_WEBHOOK_URL || "http://127.0.0.1:8000/api/v1/webhooks/payment/monad";
  const webhookSecret = process.env.ENVIO_WEBHOOK_SECRET || "";

  try {
    await fetch(webhookUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Envio-Secret": webhookSecret,
      },
      body: JSON.stringify({
        event_name: "PaymentReceived",
        tx_hash: event.transaction.hash,
        block_number: event.block.number,
        chain_id: Number(event.params.chainId),
        from_address: event.params.payer,
        amount: event.params.amount.toString(),
        order_ref: event.params.orderRef,
        category: Number(event.params.category),
        item_id: event.params.itemId,
      }),
    });
  } catch (err) {
    context.log.warn(`[SmileOn Indexer] Gagal meneruskan webhook ke backend: ${err}`);
  }
});

SmileOnPaymentHub.FundsWithdrawn.handler(async ({ event, context }) => {
  const entityId = `${event.transaction.hash}_${event.logIndex}`;
  context.Withdrawal.set({
    id: entityId,
    recipient: event.params.recipient,
    amount: event.params.amount,
    txHash: event.transaction.hash,
    blockNumber: event.block.number,
  });
});

SmileOnPaymentHub.PriceTierUpdated.handler(async ({ event, context }) => {
  context.PriceTier.set({
    id: event.params.itemId,
    itemId: event.params.itemId,
    priceInWei: event.params.priceInWei,
    isActive: event.params.isActive,
    description: event.params.description,
  });
});
