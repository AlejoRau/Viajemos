import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Called via pg_net from the on_notification_inserted trigger.
// Secured with a shared WEBHOOK_SECRET env var instead of JWT
// because the caller is a DB trigger, not an authenticated client.

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

interface NotificationRecord {
  id: string;
  user_id: string;
  type: string;
  title: string;
  body: string;
  data: Record<string, unknown>;
}

interface WebhookPayload {
  record: NotificationRecord;
}

Deno.serve(async (req: Request) => {
  // Validate webhook secret
  const secret = Deno.env.get("WEBHOOK_SECRET");
  if (secret) {
    const auth = req.headers.get("x-webhook-secret");
    if (auth !== secret) {
      return new Response("Unauthorized", { status: 401 });
    }
  }

  const payload: WebhookPayload = await req.json();
  const notification = payload.record;

  if (!notification?.user_id) {
    return new Response("Invalid payload", { status: 400 });
  }

  // Fetch all push tokens for this user
  const { data: tokens, error } = await supabase
    .from("push_tokens")
    .select("token, platform")
    .eq("user_id", notification.user_id);

  if (error) {
    console.error("Error fetching tokens:", error);
    return new Response("DB error", { status: 500 });
  }

  if (!tokens || tokens.length === 0) {
    return new Response(JSON.stringify({ sent: 0, reason: "no_tokens" }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  const fcmKey = Deno.env.get("FCM_SERVER_KEY");
  if (!fcmKey) {
    console.warn("FCM_SERVER_KEY not set — skipping push delivery");
    return new Response(JSON.stringify({ sent: 0, reason: "fcm_not_configured" }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  const staleTokens: string[] = [];

  const results = await Promise.allSettled(
    tokens.map(async ({ token }: { token: string }) => {
      const res = await fetch("https://fcm.googleapis.com/fcm/send", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `key=${fcmKey}`,
        },
        body: JSON.stringify({
          to: token,
          notification: {
            title: notification.title,
            body: notification.body,
            sound: "default",
          },
          data: {
            notification_type: notification.type,
            notification_id: notification.id,
            ...(notification.data ?? {}),
          },
          priority: "high",
          content_available: true,
        }),
      });

      const json = await res.json();

      // Collect tokens that FCM says are no longer registered
      if (json.failure === 1 && json.results?.[0]?.error === "NotRegistered") {
        staleTokens.push(token);
      }

      return json;
    })
  );

  // Clean up stale tokens so we don't keep sending to dead registrations
  if (staleTokens.length > 0) {
    await supabase.from("push_tokens").delete().in("token", staleTokens);
    console.log(`Removed ${staleTokens.length} stale token(s)`);
  }

  const sent = results.filter((r) => r.status === "fulfilled").length;
  console.log(
    `Push sent to ${sent}/${tokens.length} device(s) for notification ${notification.id}`
  );

  return new Response(JSON.stringify({ sent, total: tokens.length }), {
    headers: { "Content-Type": "application/json" },
  });
});
