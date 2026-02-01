// supabase/functions/send-push/index.ts
// Send push notifications via Firebase Cloud Messaging (FCM) HTTP v1 API
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const cors = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
}

// Firebase configuration from Supabase secrets
const FIREBASE_PROJECT_ID = Deno.env.get("FIREBASE_PROJECT_ID")
const FIREBASE_PRIVATE_KEY = Deno.env.get("FIREBASE_PRIVATE_KEY")?.replace(/\\n/g, "\n")
const FIREBASE_CLIENT_EMAIL = Deno.env.get("FIREBASE_CLIENT_EMAIL")

// Notification categories matching iOS app settings
type NotificationCategory = "newMessages" | "newMatches" | "nearbyTravelers" | "eventUpdates"

interface PushRequest {
  user_id: string
  title: string
  body: string
  category: NotificationCategory
  data?: Record<string, string>
}

interface NotificationPrefs {
  newMessages?: boolean
  newMatches?: boolean
  nearbyTravelers?: boolean
  eventUpdates?: boolean
}

// Generate a JWT for Firebase authentication
async function getFirebaseAccessToken(): Promise<string> {
  if (!FIREBASE_PRIVATE_KEY || !FIREBASE_CLIENT_EMAIL) {
    throw new Error("Firebase credentials not configured")
  }

  const now = Math.floor(Date.now() / 1000)
  const header = { alg: "RS256", typ: "JWT" }
  const payload = {
    iss: FIREBASE_CLIENT_EMAIL,
    sub: FIREBASE_CLIENT_EMAIL,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  }

  // Encode header and payload
  const encoder = new TextEncoder()
  const headerB64 = btoa(JSON.stringify(header)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_")
  const payloadB64 = btoa(JSON.stringify(payload)).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_")
  const signatureInput = `${headerB64}.${payloadB64}`

  // Import the private key and sign
  const pemContents = FIREBASE_PRIVATE_KEY
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "")

  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  )

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(signatureInput)
  )

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")

  const jwt = `${signatureInput}.${signatureB64}`

  // Exchange JWT for access token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })

  const tokenData = await tokenResponse.json()
  if (!tokenData.access_token) {
    throw new Error(`Failed to get Firebase access token: ${JSON.stringify(tokenData)}`)
  }

  return tokenData.access_token
}

// Send push notification via FCM HTTP v1 API
async function sendFCMNotification(
  fcmToken: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<boolean> {
  if (!FIREBASE_PROJECT_ID) {
    throw new Error("FIREBASE_PROJECT_ID not configured")
  }

  const accessToken = await getFirebaseAccessToken()

  const message = {
    message: {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: "default",
            badge: 1,
          },
        },
      },
      data: data || {},
    },
  }

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(message),
    }
  )

  if (!response.ok) {
    const error = await response.text()
    console.error(`FCM send failed: ${response.status} - ${error}`)
    return false
  }

  return true
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cors })
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")

    if (!supabaseUrl || !serviceKey) {
      return new Response(
        JSON.stringify({ success: false, error: "Server configuration error" }),
        { status: 500, headers: cors }
      )
    }

    const { user_id, title, body, category, data }: PushRequest = await req.json()

    if (!user_id || !title || !body || !category) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing required fields: user_id, title, body, category" }),
        { status: 400, headers: cors }
      )
    }

    // Use service role to access any user's profile
    const supabase = createClient(supabaseUrl, serviceKey)

    // Get user's FCM token and notification preferences
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("fcm_token, notification_prefs")
      .eq("id", user_id)
      .single()

    if (profileError || !profile) {
      return new Response(
        JSON.stringify({ success: false, error: "User profile not found" }),
        { status: 404, headers: cors }
      )
    }

    const { fcm_token, notification_prefs } = profile

    if (!fcm_token) {
      return new Response(
        JSON.stringify({ success: false, error: "User has no FCM token registered" }),
        { status: 400, headers: cors }
      )
    }

    // Check if user has this notification category enabled
    const prefs: NotificationPrefs = notification_prefs || {}
    const categoryEnabled = prefs[category] !== false // Default to true if not set

    if (!categoryEnabled) {
      return new Response(
        JSON.stringify({ success: false, skipped: true, reason: `Category '${category}' disabled by user` }),
        { status: 200, headers: cors }
      )
    }

    // Send the push notification
    const sent = await sendFCMNotification(fcm_token, title, body, data)

    if (!sent) {
      return new Response(
        JSON.stringify({ success: false, error: "Failed to send push notification" }),
        { status: 500, headers: cors }
      )
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: cors }
    )
  } catch (error) {
    console.error("send-push error:", error)
    return new Response(
      JSON.stringify({ success: false, error: (error as Error).message }),
      { status: 500, headers: cors }
    )
  }
})
