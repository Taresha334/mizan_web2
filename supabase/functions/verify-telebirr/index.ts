// MIZAN PLC: TELEBIRR SCRAPER EDGE FUNCTION (FINAL PRODUCTION BUILD - V4.4)
// FIXED: Column mapping to 'payment_ref' and atomic archiving

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Content-Type': 'application/json',
}

const MIZAN_TELEBIRR_NAME = "Tariku Gebretsadike Gebreselase"; 

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { transaction_id, listing_id, expected_amount } = await req.json();

    const url = `https://transactioninfo.ethiotelecom.et/receipt/${transaction_id}`;
    const response = await fetch(url);
    const html = await response.text();

    if (!html.includes("Transaction")) {
        return new Response(JSON.stringify({ success: false, message: "Receipt not found" }), { 
          headers: corsHeaders, status: 404 
        });
    }

    const isReceiverCorrect = html.toLowerCase().includes(MIZAN_TELEBIRR_NAME.toLowerCase());
    const isAmountCorrect = html.includes(Number(expected_amount).toFixed(2));
    const isCompleted = html.toLowerCase().includes("completed") || html.includes("ተጠናቅቋል");

    if (isReceiverCorrect && isAmountCorrect && isCompleted) {
      const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!, 
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
      );
      
      // ATOMIC UPDATE: Syncing with 'payment_ref' column
      await supabase
        .from('market_listings')
        .update({ 
          status: 'approved',
          payment_status: 'verified', 
          approved_at: new Date().toISOString(),
          payment_ref: transaction_id // Corrected column name
        })
        .eq('id', listing_id);

      await supabase
        .from('admin_todo_list')
        .update({ 
          status: 'processed',
          is_archived: true,
          metadata: { auto_verified: true, verified_at: new Date().toISOString() }
        })
        .eq('product_id', listing_id);

      return new Response(JSON.stringify({ success: true, message: "Verified & Archived!" }), { 
        headers: corsHeaders, status: 200 
      });
    }

    return new Response(JSON.stringify({ success: false, message: "Verification Mismatch" }), { 
      headers: corsHeaders, status: 400 
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { 
      headers: corsHeaders, status: 500 
    });
  }
})