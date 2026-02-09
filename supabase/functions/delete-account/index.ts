// supabase/functions/delete-account/index.ts
// Self-service account deletion: verifies the user via JWT, then deletes them via service role.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const cors = { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }

serve(async (req) => {
  try {
    const authHeader = req.headers.get("Authorization") || req.headers.get("authorization")
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing Authorization" }),
        { status: 401, headers: cors }
      )
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
    if (!supabaseUrl || !anonKey || !serviceKey) {
      return new Response(
        JSON.stringify({ success: false, error: "Server configuration error" }),
        { status: 500, headers: cors }
      )
    }

    const token = authHeader.replace("Bearer ", "")
    const authClient = createClient(supabaseUrl, anonKey)
    const {
      data: { user },
      error: userError,
    } = await authClient.auth.getUser(token)
    if (userError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: "Unauthorized" }),
        { status: 401, headers: cors }
      )
    }

    const serviceClient = createClient(supabaseUrl, serviceKey)
    const { error: deleteError } = await serviceClient.auth.admin.deleteUser(user.id)
    if (deleteError) {
      return new Response(
        JSON.stringify({ success: false, error: deleteError.message }),
        { status: 400, headers: cors }
      )
    }

    return new Response(JSON.stringify({ success: true }), { status: 200, headers: cors })
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: (error as Error).message }),
      { status: 500, headers: cors }
    )
  }
})
