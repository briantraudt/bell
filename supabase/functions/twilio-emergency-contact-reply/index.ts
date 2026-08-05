import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const twiml = (message: string) => new Response(
  `<?xml version="1.0" encoding="UTF-8"?><Response><Message>${message}</Message></Response>`,
  { headers: { "Content-Type": "text/xml" } },
);

async function validTwilioSignature(req: Request, params: URLSearchParams, authToken: string) {
  const signature = req.headers.get("X-Twilio-Signature") ?? "";
  let payload = req.url;
  [...params.keys()].sort().forEach((key) => {
    for (const value of params.getAll(key)) payload += key + value;
  });

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(authToken),
    { name: "HMAC", hash: "SHA-1" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(payload));
  const expected = btoa(String.fromCharCode(...new Uint8Array(digest)));

  if (expected.length !== signature.length) return false;
  let mismatch = 0;
  for (let i = 0; i < expected.length; i++) {
    mismatch |= expected.charCodeAt(i) ^ signature.charCodeAt(i);
  }
  return mismatch === 0;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const authToken = Deno.env.get("TWILIO_AUTH_TOKEN");
  if (!authToken) return new Response("Webhook not configured", { status: 503 });

  const params = new URLSearchParams(await req.text());
  if (!(await validTwilioSignature(req, params, authToken))) {
    return new Response("Invalid signature", { status: 403 });
  }

  const from = params.get("From") ?? "";
  const answer = (params.get("Body") ?? "").trim().toUpperCase();
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: contact } = await supabase
    .from("family_members")
    .select("id")
    .eq("phone", from)
    .eq("consent_status", "pending")
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!contact) return twiml("Bell could not find a pending emergency-contact invitation for this number.");

  if (["Y", "YES"].includes(answer)) {
    await supabase.from("family_members").update({
      consent_status: "accepted",
      consented_at: new Date().toISOString(),
      declined_at: null,
    }).eq("id", contact.id);
    return twiml("Thank you. You are now confirmed as this Bell user's emergency contact. Reply STOP at any time to opt out.");
  }

  if (["N", "NO"].includes(answer)) {
    await supabase.from("family_members").update({
      consent_status: "declined",
      declined_at: new Date().toISOString(),
      consented_at: null,
    }).eq("id", contact.id);
    return twiml("Understood. You were not added as an emergency contact.");
  }

  return twiml("Please reply Y to accept or N to decline the Bell emergency-contact request.");
});
