-- Migration: Enable pg_net extension
-- Description: pg_net is required for push notification triggers to make HTTP calls
-- to the send-push Edge Function. Without it, net.http_post() calls silently fail.

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;
