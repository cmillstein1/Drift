// Minimal test version - use this to verify the function runs at all
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  console.log('TEST FUNCTION CALLED')
  console.log('Method:', req.method)
  console.log('URL:', req.url)
  
  // Log headers
  console.log('Headers:')
  for (const [key, value] of req.headers.entries()) {
    console.log(`  ${key}: ${value}`)
  }
  
  return new Response(JSON.stringify({ 
    message: 'Function is working!',
    method: req.method,
    hasAuth: req.headers.get('Authorization') ? 'YES' : 'NO'
  }), {
    status: 200,
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    }
  })
})
