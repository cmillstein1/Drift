-- Migration: Seed Test Users
-- Description: Create test user profiles for development
-- Password for all test users: password123

-- ============================================================
-- Create Test Users
-- ============================================================
DO $$
DECLARE
    user1_id UUID := gen_random_uuid();
    user2_id UUID := gen_random_uuid();
    user3_id UUID := gen_random_uuid();
    user4_id UUID := gen_random_uuid();
    user5_id UUID := gen_random_uuid();
    user6_id UUID := gen_random_uuid();
    -- Pre-computed bcrypt hash for 'password123'
    password_hash TEXT := '$2a$10$PznXR4wrqNPsOwnXX3eqJ.4L9v8WQqNI7sOQr/gfLZE3J7xLqHQRO';
BEGIN
    -- Insert test users into auth.users
    INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, aud, role)
    VALUES
        (user1_id, '00000000-0000-0000-0000-000000000000', 'sarah@test.com', password_hash, NOW(), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
        (user2_id, '00000000-0000-0000-0000-000000000000', 'marcus@test.com', password_hash, NOW(), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
        (user3_id, '00000000-0000-0000-0000-000000000000', 'luna@test.com', password_hash, NOW(), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
        (user4_id, '00000000-0000-0000-0000-000000000000', 'jake@test.com', password_hash, NOW(), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
        (user5_id, '00000000-0000-0000-0000-000000000000', 'emma@test.com', password_hash, NOW(), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated'),
        (user6_id, '00000000-0000-0000-0000-000000000000', 'alex@test.com', password_hash, NOW(), NOW(), NOW(), '{"provider":"email","providers":["email"]}', '{}', 'authenticated', 'authenticated');

    -- Update profiles with test data (profiles are auto-created by trigger)
    UPDATE public.profiles SET
        name = 'Sarah Mitchell',
        bio = 'Van-lifer and photographer exploring the Pacific Coast. Always up for sunrise hikes and good coffee.',
        avatar_url = 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
        photos = ARRAY['https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800', 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800', 'https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=800', 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'https://images.unsplash.com/photo-1472214103451-1944b5e71b8b?w=800'],
        location = 'Big Sur, CA',
        verified = TRUE,
        lifestyle = 'van_life',
        travel_pace = 'slow',
        next_destination = 'Portland, OR',
        interests = ARRAY['Photography', 'Hiking', 'Coffee', 'Surfing', 'Yoga'],
        looking_for = 'dating',
        onboarding_completed = TRUE,
        birthday = '1997-03-15',
        prompt_answers = '[
            {"prompt": "My simple pleasure is", "answer": "Waking up before sunrise, making pour-over coffee, and watching the fog roll over the ocean."},
            {"prompt": "The best trip I ever took was", "answer": "Driving the entire Pacific Coast Highway from San Diego to Seattle. Two months of pure magic."},
            {"prompt": "I''m really good at", "answer": "Finding the most epic sunrise spots and making friends with local surfers."},
            {"prompt": "You can find me on weekends", "answer": "Chasing waves at sunrise, exploring hidden beaches, and capturing the perfect golden hour shot."},
            {"prompt": "I''m looking for someone who", "answer": "Loves adventure as much as I do and isn''t afraid to wake up early for a good sunrise."},
            {"prompt": "My ideal first date is", "answer": "A sunrise hike followed by coffee at a local roastery, then exploring a new beach together."}
        ]'::jsonb
    WHERE id = user1_id;

    UPDATE public.profiles SET
        name = 'Marcus Thompson',
        bio = 'Full-time RV life with my dog Max. Software developer working remotely from national parks.',
        avatar_url = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
        photos = ARRAY['https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?w=800', 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800', 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=800'],
        location = 'Yellowstone, WY',
        verified = TRUE,
        lifestyle = 'rv_life',
        travel_pace = 'moderate',
        next_destination = 'Grand Teton, WY',
        interests = ARRAY['Coding', 'Dogs', 'National Parks', 'Stargazing', 'Hiking'],
        looking_for = 'friends',
        onboarding_completed = TRUE,
        birthday = '1992-08-22',
        prompt_answers = '[
            {"prompt": "My simple pleasure is", "answer": "Stargazing with Max after a long day of coding. Nothing beats the Milky Way from a dark sky location."},
            {"prompt": "I''m really good at", "answer": "Finding the perfect balance between work and adventure. My RV office has the best views."},
            {"prompt": "A life goal of mine is", "answer": "Visiting all 63 US National Parks. Currently at 42 and counting!"},
            {"prompt": "You can find me on weekends", "answer": "Hiking with Max, working on side projects, or finding the best remote work spots with WiFi and views."},
            {"prompt": "I''m looking for someone who", "answer": "Appreciates both productivity and adventure, and doesn''t mind a dog who thinks he''s a person."},
            {"prompt": "My ideal first date is", "answer": "A sunset hike followed by stargazing. I''ll bring the telescope and Max will bring the enthusiasm."}
        ]'::jsonb
    WHERE id = user2_id;

    UPDATE public.profiles SET
        name = 'Luna Kim',
        bio = 'Digital nomad and yoga instructor. Currently building out my Sprinter van.',
        avatar_url = 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
        photos = ARRAY['https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800', 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800', 'https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=800', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'https://images.unsplash.com/photo-1511497584788-876760111969?w=800', 'https://images.unsplash.com/photo-1505142468610-359e7d316be0?w=800'],
        location = 'Joshua Tree, CA',
        verified = TRUE,
        lifestyle = 'digital_nomad',
        travel_pace = 'slow',
        next_destination = 'Sedona, AZ',
        interests = ARRAY['Yoga', 'Van Building', 'Desert Life', 'Meditation', 'Art'],
        looking_for = 'both',
        onboarding_completed = TRUE,
        birthday = '1995-11-08',
        prompt_answers = '[
            {"prompt": "My simple pleasure is", "answer": "Morning yoga sessions on my van''s rooftop with the desert sunrise as my backdrop."},
            {"prompt": "The best trip I ever took was", "answer": "A solo journey through the Southwest that taught me the power of solitude and self-discovery."},
            {"prompt": "I''m currently reading/watching", "answer": "Reading ''Wild'' by Cheryl Strayed and watching documentaries about van life conversions."},
            {"prompt": "You can find me on weekends", "answer": "Practicing yoga in nature, journaling at sunrise, or exploring new desert landscapes."},
            {"prompt": "I''m looking for someone who", "answer": "Values mindfulness, respects my need for alone time, and loves deep conversations under the stars."},
            {"prompt": "My ideal first date is", "answer": "A sunrise yoga session followed by a healthy breakfast and a hike to a beautiful viewpoint."}
        ]'::jsonb
    WHERE id = user3_id;

    UPDATE public.profiles SET
        name = 'Jake Rivera',
        bio = 'Adventure photographer chasing storms and sunsets. Living the van life for 3 years now.',
        avatar_url = 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
        photos = ARRAY['https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?w=800', 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800'],
        location = 'Moab, UT',
        verified = TRUE,
        lifestyle = 'van_life',
        travel_pace = 'fast',
        next_destination = 'Zion, UT',
        interests = ARRAY['Photography', 'Rock Climbing', 'Mountain Biking', 'Adventure', 'Camping'],
        looking_for = 'dating',
        onboarding_completed = TRUE,
        birthday = '1994-05-30',
        prompt_answers = '[
            {"prompt": "My simple pleasure is", "answer": "Finding the perfect local coffee roaster in every new town I visit. I keep a detailed map of my favorites."},
            {"prompt": "I''m really good at", "answer": "Rock climbing and finding hidden climbing spots. Always down for a climbing partner!"},
            {"prompt": "The best part of van life is", "answer": "Waking up at a new crag, making coffee, and climbing all day. Pure freedom."},
            {"prompt": "You can find me on weekends", "answer": "At the climbing gym or on a new route, always with a fresh cup of coffee in hand."},
            {"prompt": "I''m looking for someone who", "answer": "Loves climbing as much as I do, or is willing to learn. Coffee appreciation is a bonus!"},
            {"prompt": "My ideal first date is", "answer": "A morning climb followed by coffee at my favorite local roastery, then exploring the area together."}
        ]'::jsonb
    WHERE id = user4_id;

    UPDATE public.profiles SET
        name = 'Emma Chen',
        bio = 'Writer and traveler documenting van life stories. Love meeting fellow nomads!',
        avatar_url = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        photos = ARRAY['https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800', 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800', 'https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=800', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800'],
        location = 'Sedona, AZ',
        verified = TRUE,
        lifestyle = 'traveler',
        travel_pace = 'moderate',
        next_destination = 'Santa Fe, NM',
        interests = ARRAY['Writing', 'Reading', 'Campfires', 'Storytelling', 'Photography'],
        looking_for = 'friends',
        onboarding_completed = TRUE,
        birthday = '1996-09-12',
        prompt_answers = '[
            {"prompt": "My simple pleasure is", "answer": "Discovering hole-in-the-wall restaurants and food trucks. I document every amazing meal I find."},
            {"prompt": "The best trip I ever took was", "answer": "A 6-month journey through the American Southwest, documenting the stories of fellow nomads I met along the way."},
            {"prompt": "I''m really good at", "answer": "Finding the best local spots - whether it''s food, hiking trails, or hidden gems. My blog readers trust my recommendations!"},
            {"prompt": "You can find me on weekends", "answer": "Exploring farmers markets, trying new restaurants, or hiking to find the perfect spot for my next blog post."},
            {"prompt": "I''m looking for someone who", "answer": "Loves food as much as I do and is always up for trying new places and sharing stories."},
            {"prompt": "My ideal first date is", "answer": "A food tour of the area - hitting up the best local spots, food trucks, and maybe a farmers market."}
        ]'::jsonb
    WHERE id = user5_id;

    UPDATE public.profiles SET
        name = 'Alex Morgan',
        bio = 'Electrician turned van builder. Happy to help with electrical questions!',
        avatar_url = 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400',
        photos = ARRAY['https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=800', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?w=800', 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800', 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=800'],
        location = 'Portland, OR',
        verified = TRUE,
        lifestyle = 'van_life',
        travel_pace = 'slow',
        next_destination = 'Olympic NP, WA',
        interests = ARRAY['Electrical', 'DIY', 'Solar Power', 'Teaching', 'Woodworking'],
        looking_for = 'both',
        onboarding_completed = TRUE,
        birthday = '1990-02-28',
        prompt_answers = '[
            {"prompt": "My simple pleasure is", "answer": "The smell of fresh sawdust and the satisfaction of a perfectly executed woodworking project in my mobile workshop."},
            {"prompt": "I''m really good at", "answer": "Building custom van conversions. I''ve helped over 20 people convert their vans into dream homes on wheels."},
            {"prompt": "A life goal of mine is", "answer": "Starting a van conversion business that helps others achieve their nomadic dreams."},
            {"prompt": "You can find me on weekends", "answer": "In my mobile workshop building something new, or out testing my latest van build on a mountain bike trail."},
            {"prompt": "I''m looking for someone who", "answer": "Appreciates craftsmanship, loves adventure, and maybe wants to learn a thing or two about van building."},
            {"prompt": "My ideal first date is", "answer": "A tour of my current van build project, followed by a mountain bike ride and beers at a local brewery."}
        ]'::jsonb
    WHERE id = user6_id;

    -- Create activities hosted by test users
    INSERT INTO public.activities (host_id, title, description, category, location, exact_location, image_url, starts_at, duration_minutes, max_attendees) VALUES
        (user1_id, 'Sunrise Hike at Pfeiffer Beach', 'Join me for an early morning hike to catch the sunrise! Moderate difficulty, bring water and a headlamp.', 'outdoor', 'Big Sur, CA', 'Pfeiffer Beach Parking Lot', 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=800', NOW() + INTERVAL '2 days', 180, 8),
        (user2_id, 'Remote Work Coworking Session', 'Let''s work together at the visitor center! Good WiFi and great views. Coffee provided.', 'work', 'Yellowstone, WY', 'Old Faithful Visitor Center', 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800', NOW() + INTERVAL '1 day', 240, 6),
        (user3_id, 'Morning Yoga in the Desert', 'Gentle yoga flow as the sun rises over Joshua Tree. All levels welcome!', 'wellness', 'Joshua Tree, CA', 'Hidden Valley Campground', 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800', NOW() + INTERVAL '3 days', 60, 10),
        (user4_id, 'Photography Golden Hour Meetup', 'Meet fellow photographers for golden hour shooting at Delicate Arch. Share tips and shots!', 'social', 'Moab, UT', 'Delicate Arch Trailhead', 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800', NOW() + INTERVAL '4 days', 120, 12),
        (user5_id, 'Campfire Stories Night', 'Bring a story to share! We''ll have s''mores and good company under the stars.', 'social', 'Sedona, AZ', 'Oak Creek Canyon Campground', 'https://images.unsplash.com/photo-1475483768296-6163e08872a1?w=800', NOW() + INTERVAL '5 days', 180, 15),
        (user6_id, 'Van Electrical Workshop', 'Learn the basics of van electrical systems. Bring your questions!', 'work', 'Portland, OR', 'Powell Butte Nature Park', 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800', NOW() + INTERVAL '6 days', 240, 10);

    -- Add Alex as a van builder expert
    INSERT INTO public.van_builder_experts (user_id, specialty, bio, rating, review_count, verified, available_for_booking, hourly_rate)
    VALUES (user6_id, 'Electrical Systems', 'Certified electrician with 10+ years experience. Specialized in 12V/24V van electrical systems, solar installations, and lithium battery setups.', 4.9, 127, TRUE, TRUE, 75.00);

    -- Add some channel messages
    INSERT INTO public.channel_messages (channel_id, user_id, content, images, likes, is_expert_post, is_pinned) VALUES
        ('electrical', user6_id, 'Just finished my 400W solar install! Happy to answer questions about wiring and panel mounting. Here are some photos of the setup:', ARRAY['https://images.unsplash.com/photo-1509391366360-2e959784a276?w=600', 'https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?w=600'], 24, TRUE, TRUE),
        ('electrical', user2_id, 'What gauge wire should I use for a 200A lithium battery bank? Running about 15 feet to my fuse box.', '{}', 5, FALSE, FALSE),
        ('solar', user1_id, 'Anyone have experience with flexible solar panels? Wondering about durability compared to rigid.', '{}', 12, FALSE, FALSE),
        ('interior', user3_id, 'Just finished my convertible bed/couch setup! Super happy with how it turned out.', ARRAY['https://images.unsplash.com/photo-1523987355523-c7b5b0dd90a7?w=600'], 45, FALSE, FALSE),
        ('general', user4_id, 'Starting my build next month! Any must-have tools I should invest in?', '{}', 18, FALSE, FALSE);

    -- Create some friend connections
    INSERT INTO public.friends (requester_id, addressee_id, status) VALUES
        (user1_id, user3_id, 'accepted'),
        (user1_id, user4_id, 'accepted'),
        (user2_id, user5_id, 'accepted'),
        (user2_id, user6_id, 'accepted'),
        (user3_id, user5_id, 'accepted'),
        (user4_id, user6_id, 'pending');

    -- Create some conversations
    INSERT INTO public.conversations (id, type) VALUES
        (gen_random_uuid(), 'dating'),
        (gen_random_uuid(), 'friends');

    RAISE NOTICE 'Test users created successfully!';
    RAISE NOTICE 'Login credentials: [email]@test.com / password123';
    RAISE NOTICE 'Users: sarah, marcus, luna, jake, emma, alex';
END $$;
