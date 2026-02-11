// supabase/functions/delete-account/index.ts
// Self-service account deletion: verifies the user via JWT,
// explicitly cleans up all user data, then deletes the auth user via service role.
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

    const uid = user.id
    const serviceClient = createClient(supabaseUrl, serviceKey)

    // Explicitly delete user data from all tables before removing the auth user.
    // This avoids trigger conflicts during CASCADE deletes.
    // Order matters: delete from leaf tables first, then parent tables.

    // Tables referencing auth.users(id) directly
    await serviceClient.from("event_messages").delete().eq("user_id", uid)
    await serviceClient.from("event_chat_mutes").delete().eq("user_id", uid)
    await serviceClient.from("admin_invite_redemptions").delete().eq("user_id", uid)

    // Tables referencing profiles(id) — delete from leaf tables first
    await serviceClient.from("post_likes").delete().eq("user_id", uid)
    await serviceClient.from("post_replies").delete().eq("author_id", uid)
    await serviceClient.from("event_attendees").delete().eq("user_id", uid)
    await serviceClient.from("activity_attendees").delete().eq("user_id", uid)
    await serviceClient.from("channel_memberships").delete().eq("user_id", uid)
    await serviceClient.from("channel_messages").delete().eq("user_id", uid)
    await serviceClient.from("van_builder_experts").delete().eq("user_id", uid)
    await serviceClient.from("swipes").delete().or(`swiper_id.eq.${uid},swiped_id.eq.${uid}`)
    await serviceClient.from("matches").delete().or(`user1_id.eq.${uid},user2_id.eq.${uid}`)
    await serviceClient.from("friends").delete().or(`requester_id.eq.${uid},addressee_id.eq.${uid}`)

    // Messages & conversation participants
    await serviceClient.from("messages").delete().eq("sender_id", uid)
    await serviceClient.from("conversation_participants").delete().eq("user_id", uid)

    // Reports (reporter gets cascade, reported_user gets set null)
    await serviceClient.from("reports").delete().eq("reporter_id", uid)
    await serviceClient.from("reports").update({ reported_user_id: null }).eq("reported_user_id", uid)

    // Community posts (cascade will clean up remaining replies/likes/attendees for these posts)
    await serviceClient.from("community_posts").delete().eq("author_id", uid)

    // Activities (cascade will clean up remaining attendees for these activities)
    await serviceClient.from("activities").delete().eq("host_id", uid)

    // Travel schedule
    await serviceClient.from("travel_schedule").delete().eq("user_id", uid)

    // Van builder resources (SET NULL on uploaded_by)
    await serviceClient.from("van_builder_resources").update({ uploaded_by: null }).eq("uploaded_by", uid)

    // Profile itself
    await serviceClient.from("profiles").delete().eq("id", uid)

    // Finally delete the auth user (should now have no FK references)
    const { error: deleteError } = await serviceClient.auth.admin.deleteUser(uid)
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
