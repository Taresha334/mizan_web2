// filepath: supabase/functions/verify-guest-post/index.ts
// MIZAN PLC: NON-PARTNER POSTING VERIFICATION
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  // 1. Initialize Admin Client
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!serviceKey) {
    console.error("CRITICAL: SUPABASE_SERVICE_ROLE_KEY is missing from environment.");
    return new Response(JSON.stringify({ error: "Configuration Error" }), { status: 500, headers: corsHeaders });
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceKey);

  try {
    const payload = await req.json();
    const { tx_id, listing_payload, amount } = payload;
    
    // Strict validation
    const phone = listing_payload.contact_phone;
    if (!phone || phone.toString().trim() === "") {
        throw new Error(`Contact phone number is missing.`);
    }

    const sanitizedTxId = tx_id.trim().toUpperCase();

    // 2. Transaction & Duplicate Check
    const { data: existingListing } = await supabaseAdmin
      .from('market_listings')
      .select('id')
      .eq('transaction_ref', sanitizedTxId)
      .maybeSingle();
      
    if (existingListing) throw new Error("Transaction ID already used.");

    const { data: records } = await supabaseAdmin
      .from('mizan_inbox_raw')
      .select('id, raw_message')
      .ilike('raw_message', `%${sanitizedTxId}%`)
      .maybeSingle();
      
    if (!records) throw new Error("Transaction ID not found.");

    const amountPaid = parseFloat(records.raw_message.match(/ETB\s?(\d+(\.\d+)?)/i)?.[1] || "0");
    
    // 3. Pricing Calculation
    const { data: pricing } = await supabaseAdmin
      .from('visibility_pricing')
      .select('base_unit_price')
      .eq('weeks', 1)
      .eq('user_role', 'non-partner')
      .single();
      
    if (!pricing) throw new Error("Pricing configuration missing.");

    const dailyRate = Number(pricing.base_unit_price) / 7;
    const { data: existingShortfall } = await supabaseAdmin
      .from('listing_shortfalls')
      .select('*')
      .eq('phone', phone)
      .maybeSingle();
      
    const currentTotal = amountPaid + (existingShortfall?.amount_collected || 0);

    if (currentTotal < amount) {
      const needed = (amount - currentTotal).toFixed(2);
      await supabaseAdmin.from('listing_shortfalls').upsert({ 
        phone, 
        amount_collected: currentTotal, 
        product_title: listing_payload.title 
      });
      return new Response(JSON.stringify({ success: false, error: `Partial payment. Need ${needed} ETB more.` }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    const totalDays = Math.floor(currentTotal / dailyRate);
    await supabaseAdmin.from('listing_shortfalls').delete().eq('phone', phone).eq('product_title', listing_payload.title);

    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + totalDays);
    const dateStr = expiryDate.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });

    // 4. Atomic Insertion
    const { error: insertError } = await supabaseAdmin.from('market_listings').insert({
      ...listing_payload,
      contact_phone: phone,
      transaction_ref: sanitizedTxId,
      status: 'approved',
      payment_status: 'auto_verified',
      is_partner_account: false,
      visibility_duration_weeks: Math.floor(totalDays / 7),
      visibility_expires_at: expiryDate.toISOString()
    });

    if (insertError) throw new Error(`DB Error: ${insertError.message}`);

    // 5. Finalization & SMS Notification
    await supabaseAdmin.from('mizan_inbox_raw').update({ processed_status: 'verified' }).eq('id', records.id);
    
    const smsMessage = `Dear customer: Your product '${listing_payload.title}' is now LIVE on MIZAN marketplace. Your listing is active for ${totalDays} days, visible until ${dateStr}. Thank you for choosing Mizan PLC.`;
    
    await supabaseAdmin.from('sms_outbox').insert({ 
      phone: phone, 
      message: smsMessage 
    });

    return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  } catch (error: any) {
    console.error("FUNCTION ERROR:", error.message);
    return new Response(JSON.stringify({ success: false, error: error.message }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }
});