/**
 * Mizan PLC - Commander SMS Relay
 * Target Device: PGmBekjIHUOpj_t4rL8Bv
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
	
const SMSGATE_USER = Deno.env.get('SMSGATE_USER');
const SMSGATE_PASS = Deno.env.get('SMSGATE_PASS');
const SMSGATE_DEVICE = Deno.env.get('SMSGATE_DEVICE');

serve(async (req) => {
  try {
    const { record } = await req.json();
    const agentPhone = record.phone; 
    const agentName = record.full_name || "Partner";

    // 1. Generation Logic for Mizan PLC Credentials
    const generatedUsername = agentName.toLowerCase().replace(/\s/g, '') + Math.floor(1000 + Math.random() * 9000);
    const generatedPassword = Math.random().toString(36).slice(-8).toUpperCase();

    const welcomeMessage = `Welcome to Mizan PLC!\n\nYour Agent Account is ACTIVE.\nUser: ${generatedUsername}\nPass: ${generatedPassword}\n\nLogin to the Mizan app to begin.`;

    // 2. Authentication Header (Basic Auth)
    const authHeader = `Basic ${btoa(`${SMSGATE_USER}:${SMSGATE_PASS}`)}`;

    // 3. Dispatch command to the Mizan SMS Server (Your Phone)
    const response = await fetch("https://api.sms-gate.app/3rdparty/v1/messages", {
      method: "POST",
      headers: {
        "Authorization": authHeader,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        "phoneNumbers": [agentPhone],
        "textMessage": {
          "text": welcomeMessage
        },
        "deviceId": SMSGATE_DEVICE // Explicitly targeting your Admin phone
      }),
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(`Gateway Error: ${JSON.stringify(errorData)}`);
    }

    return new Response(JSON.stringify({ 
        status: "Relayed to Admin Phone", 
        target_device: "PGmBekjIHUOpj_t4rL8Bv" 
    }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error) {
    console.error("Mizan Commander Error:", error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 400,
    });
  }
})