// supabase/functions/redeem-invite/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const cors = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }

serve(async (req) => {
  try {
    const body = await req.json().catch(() => ({}))
    const { code, userId, validateOnly, checkUserStatus } = body

    // Mode: check whether the authenticated user has already redeemed an invite
    if (checkUserStatus === true) {
      const authHeader = req.headers.get('Authorization') || req.headers.get('authorization')
      if (!authHeader) {
        return new Response(JSON.stringify({ success: false, hasRedeemed: false, error: 'Missing Authorization' }), { status: 401, headers: cors })
      }
      const supabaseUrl = Deno.env.get('SUPABASE_URL')
      const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
      const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
      if (!supabaseUrl || !anonKey || !serviceKey) {
        return new Response(JSON.stringify({ success: false, hasRedeemed: false, error: 'Server configuration error' }), { status: 500, headers: cors })
      }
      const authClient = createClient(supabaseUrl, anonKey, {
        global: { headers: { Authorization: authHeader } },
      })
      const { data: { user }, error: userError } = await authClient.auth.getUser()
      if (userError || !user) {
        return new Response(JSON.stringify({ success: false, hasRedeemed: false, error: 'Unauthorized' }), { status: 401, headers: cors })
      }
      const serviceClient = createClient(supabaseUrl, serviceKey)
      const { data: rows } = await serviceClient
        .from('invitations')
        .select('id')
        .eq('used_by', user.id)
        .limit(1)
      const hasRedeemed = Array.isArray(rows) && rows.length > 0
      return new Response(JSON.stringify({ success: true, hasRedeemed }), { status: 200, headers: cors })
    }

    // Validate/redeem mode: require code
    if (!code) {
      return new Response(JSON.stringify({ success: false, error: 'Code required' }), { status: 400, headers: cors })
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Get invitation
    const { data: invitation, error: fetchError } = await supabaseClient
      .from('invitations')
      .select('*')
      .eq('code', code.toUpperCase())
      .single()

    if (fetchError || !invitation) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid invite code' }),
        { status: 200, headers: cors }
      )
    }

    // Check if already used
    if (invitation.is_used) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invite code already used' }),
        { status: 200, headers: cors }
      )
    }

    if (invitation.expires_at && new Date(invitation.expires_at) < new Date()) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invite code expired' }),
        { status: 200, headers: cors }
      )
    }

    if (validateOnly === true) {
      return new Response(
        JSON.stringify({ success: true, error: null }),
        { status: 200, headers: cors }
      )
    }

    if (!userId) {
      return new Response(
        JSON.stringify({ success: false, error: 'User ID required for redemption' }),
        { status: 400, headers: cors }
      )
    }

    const { error: updateError } = await supabaseClient
      .from('invitations')
      .update({
        is_used: true,
        used_by: userId,
        used_at: new Date().toISOString()
      })
      .eq('id', invitation.id)

    if (updateError) throw updateError

    return new Response(
      JSON.stringify({ success: true, invitation }),
      { status: 200, headers: cors }
    )

  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      status: 400,
      headers: cors
    })
  }
})
