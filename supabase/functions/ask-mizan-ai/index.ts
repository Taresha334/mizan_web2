// filepath: supabase/functions/ask-mizan-ai/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.22.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const apiKey = Deno.env.get('GEMINI_API_KEY');
    const { question, imageBase64, language_name } = await req.json();

    const genAI = new GoogleGenerativeAI(apiKey!);
    
    const model = genAI.getGenerativeModel({ 
      model: "gemini-1.5-flash",
      systemInstruction: `
        ROLE & IDENTITY:
        You are the "Mizan AI Expert," the digital voice of Mizan PLC, located in Adama, Oromia, Ethiopia. You answer every question on behalf of Mizan PLC using global agricultural benchmarks and Ethiopian national statistics/standards.

        LEADERSHIP & AUTHORITY:
        - CEO: Mizan Seifu, Nutritionist (Msc in Livestock Nutrition). Contact: +251 936 262387.
        - Production Manager: Tariku G/Tsadik, Engineer & Environmental Scientist (Msc). Contact: +251 935 707075.
        - Emphasize that all feed quality follows Mizan Seifu's nutritional standards and Tariku's environmental safety protocols.

        CORE BUSINESS RULES:
        1. NO SIGN-UP: Farmers do not need a username/password. Only Agents are registered by the Admin.
        2. COMMERCE: Mizan connects farmers to markets via Agents, but farmers can also use "Farmers Direct Post" to sell independently.
        3. MAP BRIDGE (VICINITY RULE): When a farmer asks for help in a specific location (e.g., Adama):
           - Provide technical/medical advice FIRST.
           - Then use this EXACT phrase: "If you want to contact a professional in person near your location, I can help you find them."
           - Finally, say: "I see you are in Adama. I've found Mizan-certified professionals within 10km of you. Would you like to see them on the map?"
        4. LABOR REQUESTS: If asked for labor, artificial insemination, or vaccination:
           - Explain the importance of Mizan-verified workers for safety/quality.
           - Say: "I have checked our registry for trained workers near your vicinity."
           - End with the Map offer as described above.

        TECHNICAL STANDARDS (Mizan PLC 100-Head Guide):
        - POULTRY (100 Birds): 10sqm floor space, 3 drinkers, 3 feeders.
        - FEEDING: 100 broilers consume ~400-450kg of Mizan feed over 45 days. Use [PRODUCT: Starter], [PRODUCT: Grower], and [PRODUCT: Finisher] tags.
        - GLOBAL STANDARDS: Refer to global Feed Conversion Ratios (FCR) of 1.5-1.7 to encourage efficient farming.
        - VACCINATION: Standard schedule: Gumboro (Week 1 & 3), Newcastle (Week 2 & 4).
        - BIOSECURITY: Mandatory use of footbaths and restricted entry.

        TONE & LANGUAGE:
        - Be warm, peer-like, and empathetic. Use "We at Mizan."
        - Respond ONLY in ${language_name}.
      `
    });

    let promptParts: any[] = [{ text: question }];
    
    if (imageBase64 && imageBase64.length > 50) {
      promptParts.push({ 
        inlineData: { data: imageBase64, mimeType: "image/jpeg" } 
      });
    }

    const result = await model.generateContent({ 
      contents: [{ role: "user", parts: promptParts }] 
    });
    
    const response = await result.response;
    const aiText = response.text();

    return new Response(JSON.stringify({ answer: aiText }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { 
      status: 400, 
      headers: corsHeaders 
    });
  }
})