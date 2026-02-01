// supabase/functions/send-report/index.ts
// Handles user reports: inserts into DB and sends email notification via Resend
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const cors = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
}

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")
const SUPABASE_PROJECT_ID = "kbedevzqiqhkleokehhv"

interface ContentSnapshot {
  type: "profile" | "post" | "message" | "activity"
  userName?: string
  userAvatar?: string
  title?: string
  content?: string
  images?: string[]
}

interface ReportRequest {
  reported_user_id: string
  category: "spam" | "harassment" | "inappropriate" | "scam" | "other"
  description?: string
  post_id?: string
  message_id?: string
  activity_id?: string
  content_snapshot: ContentSnapshot
}

const categoryLabels: Record<string, string> = {
  spam: "Spam",
  harassment: "Harassment",
  inappropriate: "Inappropriate Content",
  scam: "Scam/Fraud",
  other: "Other",
}

const categoryColors: Record<string, string> = {
  spam: "#dc2626",
  harassment: "#ea580c",
  inappropriate: "#db2777",
  scam: "#2563eb",
  other: "#6b7280",
}

function buildEmailHtml(
  report: ReportRequest,
  reportId: string,
  reporterId: string
): string {
  const snapshot = report.content_snapshot
  const category = categoryLabels[report.category] || report.category
  const categoryColor = categoryColors[report.category] || "#6b7280"
  const contentType = snapshot.type.charAt(0).toUpperCase() + snapshot.type.slice(1)

  const supabaseBaseUrl = `https://supabase.com/dashboard/project/${SUPABASE_PROJECT_ID}/editor`
  const viewReportUrl = `${supabaseBaseUrl}/reports?filter=id:eq:${reportId}`
  const viewUserUrl = `${supabaseBaseUrl}/profiles?filter=id:eq:${report.reported_user_id}`

  let contentSection = ""
  if (snapshot.type === "profile") {
    contentSection = `
      <div style="background: #f9fafb; border-radius: 8px; padding: 16px; margin-bottom: 16px;">
        <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 12px;">
          ${snapshot.userAvatar ? `<img src="${snapshot.userAvatar}" alt="Avatar" style="width: 48px; height: 48px; border-radius: 50%; object-fit: cover;">` : '<div style="width: 48px; height: 48px; border-radius: 50%; background: #e5e7eb;"></div>'}
          <div>
            <div style="font-weight: 600; color: #111827;">${snapshot.userName || "Unknown User"}</div>
            <div style="font-size: 12px; color: #6b7280;">ID: ${report.reported_user_id.slice(0, 8)}...</div>
          </div>
        </div>
        ${snapshot.content ? `<div style="color: #374151; font-size: 14px;">${snapshot.content}</div>` : ""}
      </div>
    `
  } else if (snapshot.type === "post" || snapshot.type === "activity") {
    contentSection = `
      <div style="background: #f9fafb; border-radius: 8px; padding: 16px; margin-bottom: 16px;">
        ${snapshot.title ? `<div style="font-weight: 600; color: #111827; margin-bottom: 8px;">${snapshot.title}</div>` : ""}
        ${snapshot.content ? `<div style="color: #374151; font-size: 14px; margin-bottom: 12px;">${snapshot.content.slice(0, 300)}${snapshot.content.length > 300 ? "..." : ""}</div>` : ""}
        <div style="font-size: 12px; color: #6b7280;">
          By: ${snapshot.userName || "Unknown"} (${report.reported_user_id.slice(0, 8)}...)
        </div>
        ${snapshot.images && snapshot.images.length > 0 ? `
          <div style="display: flex; gap: 8px; margin-top: 12px; flex-wrap: wrap;">
            ${snapshot.images.slice(0, 3).map(img => `<img src="${img}" alt="Image" style="width: 80px; height: 80px; border-radius: 4px; object-fit: cover;">`).join("")}
            ${snapshot.images.length > 3 ? `<div style="width: 80px; height: 80px; border-radius: 4px; background: #e5e7eb; display: flex; align-items: center; justify-content: center; color: #6b7280; font-size: 14px;">+${snapshot.images.length - 3}</div>` : ""}
          </div>
        ` : ""}
      </div>
    `
  } else if (snapshot.type === "message") {
    contentSection = `
      <div style="background: #f9fafb; border-radius: 8px; padding: 16px; margin-bottom: 16px;">
        <div style="font-size: 12px; color: #6b7280; margin-bottom: 8px;">Message from ${snapshot.userName || "Unknown"}</div>
        <div style="color: #374151; font-size: 14px; font-style: italic;">"${snapshot.content || "No content"}"</div>
        ${snapshot.images && snapshot.images.length > 0 ? `
          <div style="display: flex; gap: 8px; margin-top: 12px;">
            ${snapshot.images.slice(0, 3).map(img => `<img src="${img}" alt="Image" style="width: 60px; height: 60px; border-radius: 4px; object-fit: cover;">`).join("")}
          </div>
        ` : ""}
      </div>
    `
  }

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 0; background: #f3f4f6;">
  <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background: #18181b; color: white; padding: 20px; border-radius: 12px 12px 0 0;">
      <h1 style="margin: 0 0 8px 0; font-size: 20px;">New Report Submitted</h1>
      <div style="display: flex; gap: 8px; flex-wrap: wrap;">
        <span style="background: ${categoryColor}; color: white; padding: 4px 12px; border-radius: 16px; font-size: 12px; font-weight: 600;">${category}</span>
        <span style="background: #374151; color: white; padding: 4px 12px; border-radius: 16px; font-size: 12px;">${contentType}</span>
      </div>
    </div>

    <div style="background: white; padding: 24px; border-radius: 0 0 12px 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
      <h2 style="margin: 0 0 16px 0; font-size: 16px; color: #111827;">Reported Content</h2>
      ${contentSection}

      ${report.description ? `
        <h2 style="margin: 24px 0 12px 0; font-size: 16px; color: #111827;">Reporter's Notes</h2>
        <div style="background: #fef3c7; border-left: 4px solid #f59e0b; padding: 12px; border-radius: 4px; color: #92400e; font-size: 14px;">
          ${report.description}
        </div>
      ` : ""}

      <div style="margin-top: 24px; padding-top: 16px; border-top: 1px solid #e5e7eb; font-size: 12px; color: #6b7280;">
        <div><strong>Report ID:</strong> ${reportId}</div>
        <div><strong>Reporter ID:</strong> ${reporterId}</div>
        <div><strong>Submitted:</strong> ${new Date().toLocaleString("en-US", { dateStyle: "medium", timeStyle: "short" })}</div>
      </div>

      <div style="margin-top: 24px; display: flex; gap: 12px; flex-wrap: wrap;">
        <a href="${viewReportUrl}" style="background: #2563eb; color: white; padding: 10px 20px; border-radius: 6px; text-decoration: none; font-size: 14px; font-weight: 500;">View Report</a>
        <a href="${viewUserUrl}" style="background: #374151; color: white; padding: 10px 20px; border-radius: 6px; text-decoration: none; font-size: 14px; font-weight: 500;">View User</a>
      </div>
    </div>
  </div>
</body>
</html>
  `.trim()
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cors })
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")

    if (!supabaseUrl || !anonKey || !serviceKey) {
      return new Response(
        JSON.stringify({ success: false, error: "Server configuration error" }),
        { status: 500, headers: cors }
      )
    }

    // Verify the user is authenticated (check both cases)
    const authHeader = req.headers.get("Authorization") || req.headers.get("authorization")
    if (!authHeader) {
      console.error("No Authorization header found")
      return new Response(
        JSON.stringify({ success: false, error: "Missing Authorization header" }),
        { status: 401, headers: cors }
      )
    }

    const authClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: { user }, error: userError } = await authClient.auth.getUser()

    if (userError || !user) {
      console.error("Auth error:", userError?.message || "No user found")
      return new Response(
        JSON.stringify({ success: false, error: userError?.message || "Unauthorized" }),
        { status: 401, headers: cors }
      )
    }

    console.log("Authenticated user:", user.id)

    const body: ReportRequest = await req.json()

    // Validate required fields
    if (!body.reported_user_id || !body.category || !body.content_snapshot) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing required fields" }),
        { status: 400, headers: cors }
      )
    }

    // Insert report using service role
    const serviceClient = createClient(supabaseUrl, serviceKey)
    const { data: report, error: insertError } = await serviceClient
      .from("reports")
      .insert({
        reporter_id: user.id,
        reported_user_id: body.reported_user_id,
        category: body.category,
        description: body.description,
        post_id: body.post_id,
        message_id: body.message_id,
        activity_id: body.activity_id,
        content_snapshot: body.content_snapshot,
      })
      .select("id")
      .single()

    if (insertError) {
      console.error("Insert error:", insertError)
      return new Response(
        JSON.stringify({ success: false, error: insertError.message }),
        { status: 400, headers: cors }
      )
    }

    // Send email via Resend
    if (RESEND_API_KEY) {
      try {
        const emailHtml = buildEmailHtml(body, report.id, user.id)

        const emailResponse = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${RESEND_API_KEY}`,
          },
          body: JSON.stringify({
            from: "Drift Reports <reports@usedrift.app>",
            to: "support@usedrift.app",
            subject: `[${categoryLabels[body.category]}] New ${body.content_snapshot.type} report`,
            html: emailHtml,
          }),
        })

        if (!emailResponse.ok) {
          const errorText = await emailResponse.text()
          console.error("Resend error:", errorText)
          // Don't fail the request if email fails - report is already saved
        }
      } catch (emailError) {
        console.error("Email send error:", emailError)
        // Don't fail the request if email fails - report is already saved
      }
    } else {
      console.warn("RESEND_API_KEY not configured, skipping email")
    }

    return new Response(
      JSON.stringify({ success: true, report_id: report.id }),
      { status: 200, headers: cors }
    )
  } catch (error) {
    console.error("send-report error:", error)
    return new Response(
      JSON.stringify({ success: false, error: (error as Error).message }),
      { status: 500, headers: cors }
    )
  }
})
