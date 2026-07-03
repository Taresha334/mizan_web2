// filepath: supabase/functions/verify-partner-post/index.ts
// MIZAN PLC: PARTNER POSTING VERIFICATION (DEBUG TRACE ENABLED)

import { createClient } from 'jsr:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const payload = await req.json();
    console.log("DEBUG PAYLOAD:", JSON.stringify(payload)); 
    
    const { tx_id, requested_weeks, agent_id, agent_phone, listing_payload, amount } = payload;
    
    // Strict validation to prevent null/empty phone issues
    if (!agent_phone || agent_phone.toString().trim() === "") {
        throw new Error(`Agent phone number is missing in request payload.`);
    }

    const supabaseAdmin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)
    const sanitizedTxId = tx_id.trim().toUpperCase()

    // 1. Transaction & Duplicate Check
    const { data: existingListing } = await supabaseAdmin.from('market_listings').select('id').eq('transaction_ref', sanitizedTxId).maybeSingle()
    if (existingListing) throw new Error("Transaction ID already used.")

    const { data: records } = await supabaseAdmin.from('mizan_inbox_raw').select('id, raw_message').ilike('raw_message', `%${sanitizedTxId}%`).maybeSingle()
    if (!records) throw new Error("Transaction ID not found.")

    const amountPaid = parseFloat(records.raw_message.match(/ETB\s?(\d+(\.\d+)?)/i)?.[1] || "0")
    
    // 2. Pricing & Precision Calculation
    const { data: pricing } = await supabaseAdmin.from('visibility_pricing').select('base_unit_price').eq('weeks', 1).eq('user_role', 'partner').single()
    if (!pricing) throw new Error("Pricing configuration missing.")

    const dailyRate = Number(pricing.base_unit_price) / 7;

    const { data: existingShortfall } = await supabaseAdmin.from('registration_shortfalls').select('*').eq('phone', agent_phone).maybeSingle()
    const currentTotal = amountPaid + (existingShortfall?.amount_collected || 0)

    if (currentTotal < amount) {
      const needed = (amount - currentTotal).toFixed(2)
      await supabaseAdmin.from('registration_shortfalls').upsert({ phone: agent_phone, amount_collected: currentTotal })
      return new Response(JSON.stringify({ success: false, error: `Partial payment. Need ${needed} ETB more.` }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const totalDays = Math.floor(currentTotal / dailyRate);
    await supabaseAdmin.from('registration_shortfalls').delete().eq('phone', agent_phone)

    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + totalDays);
    const dateStr = expiryDate.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });

    // 3. Atomic Insertion
    const { error: insertError } = await supabaseAdmin.from('market_listings').insert({
      ...listing_payload,
      agent_id,
      contact_phone: agent_phone,
      transaction_ref: sanitizedTxId,
      status: 'approved',
      payment_status: 'auto_verified',
      visibility_duration_weeks: Math.floor(totalDays / 7),
      visibility_expires_at: expiryDate.toISOString()
    })

    if (insertError) throw new Error(`DB Error: ${insertError.message}`)

    // 4. Finalization & SMS Notification
    await supabaseAdmin.from('mizan_inbox_raw').update({ processed_status: 'verified' }).eq('id', records.id)
    
    const smsMessage = `Dear customer: Your product '${listing_payload.title}' is now LIVE on MIZAN marketplace. Your listing is active for ${totalDays} days, visible until ${dateStr}. Thank you for choosing Mizan PLC.`;
    
    await supabaseAdmin.from('sms_outbox').insert({ 
      phone: agent_phone, 
      message: smsMessage 
    })

    return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (error: any) {
    console.error("FUNCTION ERROR:", error.message);
    return new Response(JSON.stringify({ success: false, error: error.message }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})