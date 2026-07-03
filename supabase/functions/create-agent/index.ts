// MIZAN PLC: CREATE-AGENT EDGE FUNCTION (FINAL PRODUCTION BUILD - V4.4)
// FIXED: Column alignment and Auth-to-Profile Atomic Sync

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface CreateAgentBody {
  email: string;
  password?: string;
  username: string;
  phone: string;
  city_name?: string;
  category?: string;
  latitude?: number;
  longitude?: number;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''; 
    
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { autoRefreshToken: false, persistSession: false }
    });

    const body: CreateAgentBody = await req.json();
    const { email, password, username, phone, city_name, category, latitude, longitude } = body;

    // --- STEP 0: VALIDATION ---
    if (!email || !username || !phone) {
      throw new Error("Missing required fields: email, username, or phone.");
    }

    const { data: existingPhone } = await supabaseAdmin
      .from('profiles')
      .select('id')
      .eq('phone', phone.trim())
      .maybeSingle();

    if (existingPhone) {
      throw new Error(`The phone number ${phone} is already registered.`);
    }

    // --- STEP 1: CREATE AUTH USER ---
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: email.trim(),
      password: password?.trim() || "Mizan2026!",
      email_confirm: true,
      user_metadata: { full_name: username, phone: phone },
      app_metadata: { role: 'agent' }
    });

    if (authError) throw authError;
    const userId = authData.user.id;

    try {
      // --- STEP 2: CREATE PROFILE ---
      const { error: profileError } = await supabaseAdmin
        .from('profiles')
        .upsert({
          id: userId,
          full_name: username,
          phone: phone.trim(),
          email: email.trim().toLowerCase(),
          city_name: city_name || 'Mizan Territory',
          role: 'agent',
          category: category || 'agent',
          is_active: true,
          is_verified: true,
          latitude: latitude || 8.9806,
          longitude: longitude || 38.7578,
          updated_at: new Date().toISOString(),
        });

      if (profileError) throw profileError;

      // --- STEP 3: STATUS UPDATE (The Trigger Zone) ---
      // This update must avoid firing old triggers that look for 'trans_id'
      await Promise.all([
        supabaseAdmin.from('notifications').insert({
          user_id: userId,
          title: "Account Activated 🚀",
          message: `Welcome ${username}! Your Mizan Partner account is ready.`,
          type: 'activation',
        }),
        supabaseAdmin.from('agent_applications')
          .update({ 
            status: 'approved',
            updated_at: new Date().toISOString() 
          })
          .eq('phone', phone.trim())
      ]);

    } catch (dbError: any) {
      await supabaseAdmin.auth.admin.deleteUser(userId);
      throw dbError;
    }

    return new Response(
      JSON.stringify({ success: true, userId, message: "Agent activated successfully." }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 201 }
    );

  } catch (error: any) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    );
  }
});