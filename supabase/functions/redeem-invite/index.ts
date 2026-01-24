// supabase/functions/redeem-invite/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { code, userId, validateOnly } = await req.json()
    
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
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Check if already used
    if (invitation.is_used) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invite code already used' }), 
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Check expiration
    if (invitation.expires_at && new Date(invitation.expires_at) < new Date()) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invite code expired' }), 
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // If validateOnly is true, just return success without redeeming
    if (validateOnly === true) {
      return new Response(
        JSON.stringify({ success: true, error: null }), 
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Actual redemption - require userId
    if (!userId) {
      return new Response(
        JSON.stringify({ success: false, error: 'User ID required for redemption' }), 
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Mark as used
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
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})
