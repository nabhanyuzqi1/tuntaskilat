import { DocHeader, DocPage, H2, P, Table, Callout, Code, PrevNext } from '../components/Kit'

const TOC = [
  { id: 'fcm-events', label: 'FCM Push Events' },
  { id: 'whatsapp', label: 'WhatsApp (Fonnte)' },
  { id: 'in-app', label: 'In-App Notification Feed' },
]

export default function Notifications() {
  return (
    <DocPage toc={TOC}>
      <DocHeader
        eyebrow="Integrations"
        title="Notifications"
        description="Two independent notification channels — Firebase Cloud Messaging for push, and WhatsApp via Fonnte for a persistent paper trail."
      />

      <H2 id="fcm-events">FCM Push Events</H2>
      <Table
        head={['Function', 'Recipient', 'Trigger']}
        rows={[
          ['onOrderAssigned', 'assigned crew', "order enters 'ditugaskan'"],
          ['pushStatusPelanggan', 'customer', 'terverifikasi / ditugaskan / dalam_perjalanan / dikerjakan / selesai / ditolak'],
          ['onChatMessageCreate', 'the other chat participant', 'any new message in orders/{id}/messages'],
          ['reminderKru', 'assigned crew', 'every 30 min, if jadwal is 90–150 min away'],
          ['onBroadcastCreate', 'all pelanggan with a token', 'admin creates a broadcasts/{id} doc'],
        ]}
      />
      <Callout type="info">
        Invalid/expired tokens are cleaned from{' '}
        <Code>kru.fcmTokens</Code> automatically whenever a push fails with{' '}
        <Code>registration-token-not-registered</Code> or{' '}
        <Code>invalid-argument</Code>.
      </Callout>

      <H2 id="whatsapp">WhatsApp (Fonnte) — waNotifOrder</H2>
      <P>
        A thin abstraction, <Code>WaSender</Code>, with{' '}
        <Code>FonnteSender</Code> as the active implementation — swap the
        class if you switch WhatsApp providers without touching call sites.
        Fires on the same order-status transitions as the push notification
        (terverifikasi / ditugaskan / selesai), sending a formatted text
        message to the customer's phone. No-op — safely, silently — if{' '}
        <Code>FONNTE_TOKEN</Code> is unset in{' '}
        <Code>firebase/functions/.env</Code>.
      </P>

      <H2 id="in-app">In-App Notification Feed</H2>
      <P>
        Every push additionally writes a <Code>notifications</Code> document
        (see Data Model) so the customer/crew has a persistent, scrollable
        history inside the app — not just a transient system notification.
        Notifications are deep-linkable via the <Code>orderId</Code> field.
      </P>

      <PrevNext
        prev={{ to: '/ai', label: 'AI Features' }}
        next={{ to: '/deployment', label: 'Deployment' }}
      />
    </DocPage>
  )
}
