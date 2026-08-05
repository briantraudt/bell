import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const accountSid = Deno.env.get("TWILIO_ACCOUNT_SID");
    const authToken = Deno.env.get("TWILIO_AUTH_TOKEN");
    const messagingServiceSid = Deno.env.get("TWILIO_MESSAGE_SERVICE_SID");

    if (!accountSid || !authToken || !messagingServiceSid) {
      return Response.json({ error: "Emergency contact texting is not configured." }, { status: 503, headers: cors });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) return Response.json({ error: "Unauthorized" }, { status: 401, headers: cors });

    const body = await req.json();
    const firstName = String(body.firstName ?? "").trim();
    const relationship = String(body.relationship ?? "").trim();
    const phone = String(body.phone ?? "").trim();

    if (!firstName || !relationship || !/^\+1\d{10}$/.test(phone)) {
      return Response.json({ error: "A first name, relationship, and valid US phone number are required." }, { status: 400, headers: cors });
    }

    const { data: profile } = await supabase.from("profiles").select("first_name").eq("id", user.id).single();
    const ownerName = profile?.first_name || "A Bell user";

    const { error: upsertError } = await supabase.from("family_members").upsert({
      user_id: user.id,
      name: firstName,
      relationship,
      phone,
      can_view_activity: false,
      consent_status: "pending",
      consent_requested_at: new Date().toISOString(),
      consented_at: null,
      declined_at: null,
    }, { onConflict: "user_id,phone" });
    if (upsertError) throw upsertError;

    const form = new URLSearchParams({
      To: phone,
      MessagingServiceSid: messagingServiceSid,
      Body: `Bell: ${ownerName} listed you as their emergency contact. Bell may contact you if ${ownerName} asks for help. Reply Y to accept or N to decline. Reply STOP to opt out.`,
    });

    const twilioResponse = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`, {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(`${accountSid}:${authToken}`)}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: form,
    });

    const payload = await twilioResponse.json();
    if (!twilioResponse.ok) {
      return Response.json({ error: payload.message ?? "The invitation text could not be sent." }, { status: 502, headers: cors });
    }

    return Response.json({ status: "pending", messageSid: payload.sid }, { headers: cors });
  } catch (error) {
    return Response.json({ error: error instanceof Error ? error.message : "Unexpected error" }, { status: 500, headers: cors });
  }
});
