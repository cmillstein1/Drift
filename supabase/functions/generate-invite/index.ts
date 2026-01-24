// supabase/functions/generate-invite/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // Log immediately - before any try/catch
  console.log('🚀🚀🚀 [generate-invite] FUNCTION CALLED - FIRST LINE')
  console.log('🚀🚀🚀 [generate-invite] Timestamp:', new Date().toISOString())
  
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Authorization, Content-Type',
      },
    })
  }
  
  try {
    console.log('🚀 [generate-invite] Function called')
    console.log('🚀 [generate-invite] Request method:', req.method)
    console.log('🚀 [generate-invite] Request URL:', req.url)
    
    // Log all headers
    console.log('📋 [generate-invite] All headers:')
    req.headers.forEach((value, key) => {
      if (key.toLowerCase().includes('auth') || key.toLowerCase().includes('authorization')) {
        console.log(`  ${key}: ${value.substring(0, 50)}...`)
      } else {
        console.log(`  ${key}: ${value}`)
      }
    })
    
    // Get Authorization header (check both cases)
    const authHeader = req.headers.get('Authorization') || req.headers.get('authorization')
    
    console.log('🔐 [generate-invite] Authorization header present:', !!authHeader)
    if (authHeader) {
      console.log('🔐 [generate-invite] Auth header length:', authHeader.length)
      console.log('🔐 [generate-invite] Auth header prefix:', authHeader.substring(0, 30))
    }
    
    if (!authHeader) {
      console.error('❌ [generate-invite] Missing Authorization header')
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), { 
        status: 401,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        }
      })
    }

    // Check environment variables
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')
    console.log('🔧 [generate-invite] SUPABASE_URL present:', !!supabaseUrl)
    console.log('🔧 [generate-invite] SUPABASE_ANON_KEY present:', !!anonKey)

    // Create client with Authorization header - this will automatically verify the user
    console.log('🔍 [generate-invite] Creating Supabase client with auth header...')
    const supabaseClient = createClient(
      supabaseUrl ?? '',
      anonKey ?? '',
      {
        global: {
          headers: {
            Authorization: authHeader
          }
        }
      }
    )

    console.log('🔍 [generate-invite] Verifying user with auth header...')
    // Get the user from the authenticated client
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    
    if (userError) {
      console.error('❌ [generate-invite] Auth verification error:', userError)
      console.error('❌ [generate-invite] Error message:', userError.message)
      console.error('❌ [generate-invite] Error status:', userError.status)
      console.error('❌ [generate-invite] Full error:', JSON.stringify(userError, null, 2))
      return new Response(JSON.stringify({ error: 'Invalid or expired token: ' + userError.message }), { 
        status: 401,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        }
      })
    }
    
    if (!user) {
      console.error('❌ [generate-invite] No user returned from token verification')
      return new Response(JSON.stringify({ error: 'Invalid or expired token' }), { 
        status: 401,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        }
      })
    }
    
    console.log('✅ [generate-invite] User verified:', user.id)
    console.log('✅ [generate-invite] User email:', user.email)

    // Create service role client for database operations (bypasses RLS)
    // We've already verified the user is authenticated, so we can use service role for inserts
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
    console.log('🔧 [generate-invite] SUPABASE_SERVICE_ROLE_KEY present:', !!serviceRoleKey)
    
    const dbClient = createClient(
      supabaseUrl ?? '',
      serviceRoleKey ?? ''
    )
    console.log('🔧 [generate-invite] Using service role key for database operations (bypasses RLS)')

    // Generate unique 6-digit code
    console.log('🎲 [generate-invite] Generating unique code...')
    let code: string
    let isUnique = false
    let attempts = 0
    const maxAttempts = 10

    // Keep generating until we get a unique code
    while (!isUnique && attempts < maxAttempts) {
      code = generateInviteCode()
      console.log(`🎲 [generate-invite] Attempt ${attempts + 1}: Generated code ${code}`)
      
      // Check if code already exists (using service role to bypass RLS)
      const { data: existing, error: checkError } = await dbClient
        .from('invitations')
        .select('code')
        .eq('code', code)
        .single()

      if (checkError && checkError.code !== 'PGRST116') { // PGRST116 = no rows returned
        console.error('❌ [generate-invite] Error checking code uniqueness:', checkError)
        throw checkError
      }

      if (!existing) {
        isUnique = true
        console.log('✅ [generate-invite] Code is unique:', code)
      } else {
        attempts++
        console.log(`⚠️ [generate-invite] Code already exists, trying again...`)
      }
    }

    if (!isUnique) {
      console.error('❌ [generate-invite] Failed to generate unique code after', maxAttempts, 'attempts')
      throw new Error('Failed to generate unique invite code')
    }

    // Set expiration (7 days from now)
    const expiresAt = new Date()
    expiresAt.setDate(expiresAt.getDate() + 7)
    console.log('📅 [generate-invite] Code expires at:', expiresAt.toISOString())

    // Insert invitation using service role (bypasses RLS)
    console.log('💾 [generate-invite] Inserting invitation into database...')
    const { data, error } = await dbClient
      .from('invitations')
      .insert({
        code,
        created_by: user.id,
        expires_at: expiresAt.toISOString()
      })
      .select()
      .single()

    if (error) {
      console.error('❌ [generate-invite] Database insert error:', error)
      console.error('❌ [generate-invite] Error message:', error.message)
      console.error('❌ [generate-invite] Error code:', error.code)
      throw error
    }

    console.log('✅ [generate-invite] Successfully created invitation:', data.id)
    console.log('✅ [generate-invite] Invite code:', data.code)

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Authorization, Content-Type',
      }
    })

  } catch (error) {
    console.error('❌ [generate-invite] Unhandled error:', error)
    console.error('❌ [generate-invite] Error message:', error.message)
    console.error('❌ [generate-invite] Error stack:', error.stack)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      }
    })
  }
})

function generateInviteCode(): string {
  // Generate 6-digit numeric code
  const digits = '0123456789'
  let code = ''
  for (let i = 0; i < 6; i++) {
    code += digits.charAt(Math.floor(Math.random() * digits.length))
  }
  return code
}
