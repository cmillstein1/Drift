-- Enable realtime for event_attendees table
-- This allows hosts to see join requests in real-time
-- and users to see when their request is approved
ALTER PUBLICATION supabase_realtime ADD TABLE event_attendees;
