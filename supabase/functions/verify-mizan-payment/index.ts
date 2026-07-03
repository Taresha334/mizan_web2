// filepath: supabase/functions/verify-mizan-payment/index.ts
import { createClient } from 'jsr:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { tx_id, full_name, phone, category, location, requested_weeks, latitude, longitude } = await req.json()
    const supabaseAdmin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!)

    const sanitizedTxId = tx_id.trim().toUpperCase();
    const { data: records } = await supabaseAdmin.from('mizan_inbox_raw').select('id, raw_message').ilike('raw_message', `%${sanitizedTxId}%`).maybeSingle();

    if (!records) throw new Error("Transaction ID not found. Please wait a few seconds or check the SMS from 127.");

    const amountPaid = parseFloat(records.raw_message.match(/ETB\s?(\d+(\.\d+)?)/i)?.[1] || "0");
    const { data: tierData } = await supabaseAdmin.from('registration_pricing').select('price_etb, base_unit_price').eq('duration_weeks', requested_weeks).single();
    if (!tierData) throw new Error("Subscription plan not found.");

    const { data: existingShortfall } = await supabaseAdmin.from('registration_shortfalls').select('*').eq('phone', phone).maybeSingle();
    const currentTotal = amountPaid + (existingShortfall?.amount_collected || 0);

    if (currentTotal < tierData.price_etb) {
      const needed = (tierData.price_etb - currentTotal).toFixed(2);
      await supabaseAdmin.from('registration_shortfalls').upsert({ phone, amount_collected: currentTotal });
      await supabaseAdmin.from('sms_outbox').insert({ phone, message: `Mizan: Received ${amountPaid} ETB. Total: ${currentTotal}. Needed: ${needed} ETB.` });
      return new Response(JSON.stringify({ success: false, error: "Partial payment recorded." }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    const bonusWeeks = Math.floor((currentTotal - tierData.price_etb) / tierData.base_unit_price);
    const totalWeeks = requested_weeks + bonusWeeks;
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + (totalWeeks * 7));
    const dateStr = expiryDate.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });

    await supabaseAdmin.from('registration_shortfalls').delete().eq('phone', phone);
    const pin = Math.floor(1000 + Math.random() * 9000).toString();
    
    // Auth metadata uses "agent" to maintain your system's authorization flow
    const { data: { user } } = await supabaseAdmin.auth.admin.createUser({ 
        email: `${phone.replace('+', '')}@mizan.plc`, 
        password: `Mizan${pin}`, 
        user_metadata: { phone, full_name, role: 'agent' }, 
        email_confirm: true 
    });
    
    // Profiles table persistence with restored pin_code logic
    await supabaseAdmin.from('profiles').upsert({ 
      id: user!.id, 
      full_name, 
      phone, 
      role: 'agent',
      category: category,      
      custom_role: category,
      pin_code: pin, // Restored pin_code persistence
      city_name: location, 
      latitude: latitude,      
      longitude: longitude,
      is_active: true 
    });

    let smsMessage = `Dear ${full_name}, your account is active until ${dateStr}. PIN: ${pin}.`;
    if (bonusWeeks > 0) smsMessage += ` Bonus: ${bonusWeeks} extra week(s) granted.`;
    smsMessage += ` Welcome to Mizan.`;

    await supabaseAdmin.from('sms_outbox').insert({ phone, message: smsMessage });
    await supabaseAdmin.from('mizan_inbox_raw').update({ processed_status: 'verified' }).eq('id', records.id);

    return new Response(JSON.stringify({ success: true }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  } catch (error: any) {
    return new Response(JSON.stringify({ success: false, error: error.message }), { status: 400, headers: corsHeaders });
  }
})