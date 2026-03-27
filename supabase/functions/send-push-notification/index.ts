import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Called via pg_net from the on_notification_inserted trigger.
// Secured with a shared WEBHOOK_SECRET env var instead of JWT
// because the caller is a DB trigger, not an authenticated client.
//
// Uses FCM HTTP v1 API (legacy /fcm/send was deprecated June 2024).
// Requires GOOGLE_SERVICE_ACCOUNT_JSON env var (Firebase service account JSON).

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

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

function base64url(input: Uint8Array | string): string {
  const bytes =
    typeof input === "string" ? new TextEncoder().encode(input) : input;
  let binary = "";
  bytes.forEach((b) => (binary += String.fromCharCode(b)));
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = atob(base64);
  const buffer = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) buffer[i] = binary.charCodeAt(i);
  return buffer.buffer;
}

async function getFcmAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    })
  );

  const signingInput = `${header}.${payload}`;
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const signatureBytes = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    new TextEncoder().encode(signingInput)
  );
  const jwt = `${signingInput}.${base64url(new Uint8Array(signatureBytes))}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth2:grant_type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const { access_token } = await tokenRes.json();
  return access_token;
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

  const saJson = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON");
  if (!saJson) {
    console.warn("GOOGLE_SERVICE_ACCOUNT_JSON not set — skipping push delivery");
    return new Response(
      JSON.stringify({ sent: 0, reason: "fcm_not_configured" }),
      { headers: { "Content-Type": "application/json" } }
    );
  }

  const sa: ServiceAccount = JSON.parse(saJson);
  const accessToken = await getFcmAccessToken(sa);
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

  // FCM v1 data values must all be strings
  const dataPayload = Object.fromEntries(
    Object.entries({
      notification_type: notification.type,
      notification_id: notification.id,
      ...(notification.data ?? {}),
    }).map(([k, v]) => [k, typeof v === "string" ? v : JSON.stringify(v)])
  );

  const staleTokens: string[] = [];

  const results = await Promise.allSettled(
    tokens.map(async ({ token }: { token: string }) => {
      const res = await fetch(fcmUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token,
            notification: {
              title: notification.title,
              body: notification.body,
            },
            data: dataPayload,
            android: { priority: "high" },
            apns: {
              payload: { aps: { "content-available": 1, sound: "default" } },
            },
          },
        }),
      });

      const json = await res.json();

      // FCM v1 marks dead tokens with errorCode UNREGISTERED
      if (
        json.error?.details?.some(
          (d: Record<string, string>) => d.errorCode === "UNREGISTERED"
        )
      ) {
        staleTokens.push(token);
      }

      return json;
    })
  );

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
