// Alternative version using service role key to verify JWT manually
// Use this if the main version still has auth issues

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    // Get Authorization header
    const authHeader = req.headers.get('Authorization') || req.headers.get('authorization')
    
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), { 
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // Extract token from "Bearer <token>"
    const token = authHeader.replace('Bearer ', '')

    // Create client with service role to verify the JWT
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Verify the JWT token and get user
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)
    
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid or expired token' }), { 
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      })
    }

    // Create client for database operations (using anon key with user context)
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: {
            Authorization: authHeader
          }
        }
      }
    )

    // Generate unique 6-digit code
    let code: string
    let isUnique = false
    let attempts = 0
    const maxAttempts = 10

    while (!isUnique && attempts < maxAttempts) {
      code = generateInviteCode()
      
      const { data: existing } = await supabaseClient
        .from('invitations')
        .select('code')
        .eq('code', code)
        .single()

      if (!existing) {
        isUnique = true
      } else {
        attempts++
      }
    }

    if (!isUnique) {
      throw new Error('Failed to generate unique invite code')
    }

    // Set expiration (7 days from now)
    const expiresAt = new Date()
    expiresAt.setDate(expiresAt.getDate() + 7)

    // Insert invitation
    const { data, error } = await supabaseClient
      .from('invitations')
      .insert({
        code,
        created_by: user.id,
        expires_at: expiresAt.toISOString()
      })
      .select()
      .single()

    if (error) throw error

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' }
    })
  }
})

function generateInviteCode(): string {
  const digits = '0123456789'
  let code = ''
  for (let i = 0; i < 6; i++) {
    code += digits.charAt(Math.floor(Math.random() * digits.length))
  }
  return code
}
