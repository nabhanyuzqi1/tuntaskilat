export type FnDef = {
  id: string
  name: string
  trigger: string
  path: string
  desc: string
  detail?: string
}

export type FnGroup = { title: string; fns: FnDef[] }

export const FN_GROUPS: FnGroup[] = [
  {
    title: 'Orders & Pricing Integrity',
    fns: [
      {
        id: 'onOrderCreate',
        name: 'onOrderCreate',
        trigger: 'onDocumentCreated',
        path: 'orders/{orderId}',
        desc: 'Re-reads the service document and recomputes the correct price server-side, correcting the order in place if the client-submitted totalHarga/subtotal/potongan drift by more than Rp1.',
        detail: 'Anti price-tampering: the client computes a preview price for UX, but this function is what actually decides what the customer owes.',
      },
      {
        id: 'validatePayment',
        name: 'validatePayment',
        trigger: 'onDocumentCreated',
        path: 'payments/{paymentId}',
        desc: "Confirms payment.jumlah equals the referenced order's totalHarga (tolerance Rp1); corrects it if mismatched.",
      },
      {
        id: 'onOrderFinalize',
        name: 'onOrderFinalize',
        trigger: 'onDocumentUpdated',
        path: 'orders/{orderId}',
        desc: "Fires on transition into status: 'selesai'. Computes crew payouts (weighted split, helper ratio 0.6) and, for cash orders, books the platform commission into the lead crew member's kasKru ledger.",
        detail: 'Idempotent via the kasTunaiDibukukan flag on the order document — cash commission is only ever booked once.',
      },
      {
        id: 'onOrderAssigned',
        name: 'onOrderAssigned',
        trigger: 'onDocumentUpdated',
        path: 'orders/{orderId}',
        desc: "Fires on transition into 'ditugaskan'. Sends FCM push to every assigned crew member's fcmTokens, cleaning up invalid tokens.",
      },
      {
        id: 'onOrderCancelled',
        name: 'onOrderCancelled',
        trigger: 'onDocumentUpdated',
        path: 'orders/{orderId}',
        desc: "Fires on transition into 'dibatalkan'. Decrements the booking slot's terisi counter (or deletes the slot doc) — the only permitted decrement path, since clients can only increment.",
      },
      {
        id: 'pushStatusPelanggan',
        name: 'pushStatusPelanggan',
        trigger: 'onDocumentUpdated',
        path: 'orders/{orderId}',
        desc: 'Pushes FCM to the customer on every meaningful status transition, with data.tipe=\'status\' for deep-linking into the tracking screen.',
      },
      {
        id: 'autoCancelTanpaKru',
        name: 'autoCancelTanpaKru',
        trigger: 'onSchedule',
        path: 'every 60 minutes (Asia/Makassar)',
        desc: "Cancels orders stuck in 'terverifikasi'/'menunggu_penugasan' for more than 24 hours with no crew assigned, notifying the customer.",
      },
    ],
  },
  {
    title: 'Chat & Notifications',
    fns: [
      {
        id: 'onChatMessageCreate',
        name: 'onChatMessageCreate',
        trigger: 'onDocumentCreated',
        path: 'orders/{orderId}/messages/{messageId}',
        desc: 'Determines recipients (pelanggan → all kruIds; kru → userId), writes a notification doc, and pushes FCM.',
      },
      {
        id: 'reminderKru',
        name: 'reminderKru',
        trigger: 'onSchedule',
        path: 'every 30 minutes (Asia/Makassar)',
        desc: "Finds 'ditugaskan' orders whose jadwal is 90–150 minutes away and sends a reminder push to assigned crew.",
      },
      {
        id: 'onBroadcastCreate',
        name: 'onBroadcastCreate',
        trigger: 'onDocumentCreated',
        path: 'broadcasts/{id}',
        desc: 'Mass-pushes an FCM notification to every user with role==\'pelanggan\', then writes delivery stats back onto the broadcast doc.',
      },
      {
        id: 'waNotifOrder',
        name: 'waNotifOrder',
        trigger: 'onDocumentUpdated',
        path: 'orders/{orderId}',
        desc: "Sends a WhatsApp message via Fonnte for terverifikasi/ditugaskan/selesai status transitions. No-op if FONNTE_TOKEN is unset.",
      },
    ],
  },
  {
    title: 'Reviews & Capacity',
    fns: [
      {
        id: 'onReviewCreate',
        name: 'onReviewCreate',
        trigger: 'onDocumentCreated',
        path: 'reviews/{reviewId}',
        desc: "Re-aggregates ALL reviews for the rated cleanerId and overwrites kru/{cleanerId}.rataRating / jumlahUlasan — server-authoritative, never client-computed.",
      },
      {
        id: 'onKruDitulis',
        name: 'onKruDitulis',
        trigger: 'onDocumentWritten',
        path: 'kru/{cleanerId}',
        desc: 'Any create/update/delete of a crew doc triggers recomputeKapasitasLayanan().',
      },
      {
        id: 'onLayananDibuat',
        name: 'onLayananDibuat',
        trigger: 'onDocumentCreated',
        path: 'services/{serviceId}',
        desc: 'A new service triggers recomputeKapasitasLayanan() so jumlahKru is populated immediately.',
      },
      {
        id: 'backfillKapasitasKru',
        name: 'backfillKapasitasKru',
        trigger: 'onCall',
        path: 'admin-only',
        desc: 'Manually forces a full recompute of service capacities — used after bulk keahlian edits.',
      },
    ],
  },
  {
    title: 'Admin & Referral',
    fns: [
      {
        id: 'buatAdmin',
        name: 'buatAdmin',
        trigger: 'onCall',
        path: 'admin-only',
        desc: 'Input { email, password, nama }. Creates a Firebase Auth user + users doc (role: admin) without disturbing the caller\'s session. Returns { uid }.',
      },
      {
        id: 'setNonaktifAdmin',
        name: 'setNonaktifAdmin',
        trigger: 'onCall',
        path: 'admin-only',
        desc: 'Input { uid, nonaktif }. Disables/enables the target Auth account. Cannot target self (failed-precondition).',
      },
      {
        id: 'rewardReferral',
        name: 'rewardReferral',
        trigger: 'onDocumentUpdated',
        path: 'orders/{orderId}',
        desc: "On a buyer's first completed order, mints a reward voucher for the referrer, guarded by a transaction on referralClaims/{phone} — one claim per phone number, ever.",
      },
    ],
  },
  {
    title: 'Payments (Xendit)',
    fns: [
      {
        id: 'xenditWebhook',
        name: 'xenditWebhook',
        trigger: 'onRequest',
        path: 'HTTP endpoint',
        desc: "Validates x-callback-token, then on status PAID/SETTLED marks the matching payment & order 'terverifikasi'. Returns 501 if XENDIT_CALLBACK_TOKEN is unset.",
      },
      {
        id: 'buatTagihanXendit',
        name: 'buatTagihanXendit',
        trigger: 'onCall',
        path: 'auth required',
        desc: 'Input { orderId, amount }. Verifies order ownership, calls the Xendit Invoices API, persists invoiceUrl/invoiceId on the payment doc. Requires XENDIT_SECRET_KEY.',
      },
    ],
  },
  {
    title: 'AI',
    fns: [
      {
        id: 'csAi',
        name: 'csAi',
        trigger: 'onCall',
        path: 'auth required',
        desc: 'Input { pertanyaan, orderId? }. Multi-provider chat (Gemini/OpenAI/Anthropic) grounded in the live service catalog + the caller\'s own order status. Returns { jawaban }.',
      },
      {
        id: 'analisaBisnisAi',
        name: 'analisaBisnisAi',
        trigger: 'onCall',
        path: 'admin-only',
        desc: 'Aggregates the trailing 30 days of orders (numerically, server-side) and asks the configured LLM for a concise business summary + action suggestions. Returns { ringkasan }.',
      },
    ],
  },
]

export const ALL_FNS = FN_GROUPS.flatMap((g) => g.fns)
