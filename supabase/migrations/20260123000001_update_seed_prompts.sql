-- Migration: Update seed user profiles with prompt answers
-- Description: Adds prompt answers to existing seed users without requiring a full database reset

DO $$
DECLARE
    user1_id UUID;
    user2_id UUID;
    user3_id UUID;
    user4_id UUID;
    user5_id UUID;
    user6_id UUID;
BEGIN
    -- Find user IDs by email
    SELECT id INTO user1_id FROM auth.users WHERE email = 'sarah@test.com' LIMIT 1;
    SELECT id INTO user2_id FROM auth.users WHERE email = 'marcus@test.com' LIMIT 1;
    SELECT id INTO user3_id FROM auth.users WHERE email = 'luna@test.com' LIMIT 1;
    SELECT id INTO user4_id FROM auth.users WHERE email = 'jake@test.com' LIMIT 1;
    SELECT id INTO user5_id FROM auth.users WHERE email = 'emma@test.com' LIMIT 1;
    SELECT id INTO user6_id FROM auth.users WHERE email = 'alex@test.com' LIMIT 1;

    -- Update Sarah
    IF user1_id IS NOT NULL THEN
        UPDATE public.profiles SET
            photos = ARRAY['https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800', 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800', 'https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=800', 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'https://images.unsplash.com/photo-1472214103451-1944b5e71b8b?w=800'],
            prompt_answers = '[
                {"prompt": "My simple pleasure is", "answer": "Waking up before sunrise, making pour-over coffee, and watching the fog roll over the ocean."},
                {"prompt": "The best trip I ever took was", "answer": "Driving the entire Pacific Coast Highway from San Diego to Seattle. Two months of pure magic."},
                {"prompt": "I''m really good at", "answer": "Finding the most epic sunrise spots and making friends with local surfers."},
                {"prompt": "You can find me on weekends", "answer": "Chasing waves at sunrise, exploring hidden beaches, and capturing the perfect golden hour shot."},
                {"prompt": "I''m looking for someone who", "answer": "Loves adventure as much as I do and isn''t afraid to wake up early for a good sunrise."},
                {"prompt": "My ideal first date is", "answer": "A sunrise hike followed by coffee at a local roastery, then exploring a new beach together."}
            ]'::jsonb
        WHERE id = user1_id;
    END IF;

    -- Update Marcus
    IF user2_id IS NOT NULL THEN
        UPDATE public.profiles SET
            photos = ARRAY['https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?w=800', 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800', 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=800'],
            prompt_answers = '[
                {"prompt": "My simple pleasure is", "answer": "Stargazing with Max after a long day of coding. Nothing beats the Milky Way from a dark sky location."},
                {"prompt": "I''m really good at", "answer": "Finding the perfect balance between work and adventure. My RV office has the best views."},
                {"prompt": "A life goal of mine is", "answer": "Visiting all 63 US National Parks. Currently at 42 and counting!"},
                {"prompt": "You can find me on weekends", "answer": "Hiking with Max, working on side projects, or finding the best remote work spots with WiFi and views."},
                {"prompt": "I''m looking for someone who", "answer": "Appreciates both productivity and adventure, and doesn''t mind a dog who thinks he''s a person."},
                {"prompt": "My ideal first date is", "answer": "A sunset hike followed by stargazing. I''ll bring the telescope and Max will bring the enthusiasm."}
            ]'::jsonb
        WHERE id = user2_id;
    END IF;

    -- Update Luna
    IF user3_id IS NOT NULL THEN
        UPDATE public.profiles SET
            photos = ARRAY['https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800', 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800', 'https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=800', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'https://images.unsplash.com/photo-1511497584788-876760111969?w=800', 'https://images.unsplash.com/photo-1505142468610-359e7d316be0?w=800'],
            prompt_answers = '[
                {"prompt": "My simple pleasure is", "answer": "Morning yoga sessions on my van''s rooftop with the desert sunrise as my backdrop."},
                {"prompt": "The best trip I ever took was", "answer": "A solo journey through the Southwest that taught me the power of solitude and self-discovery."},
                {"prompt": "I''m currently reading/watching", "answer": "Reading ''Wild'' by Cheryl Strayed and watching documentaries about van life conversions."},
                {"prompt": "You can find me on weekends", "answer": "Practicing yoga in nature, journaling at sunrise, or exploring new desert landscapes."},
                {"prompt": "I''m looking for someone who", "answer": "Values mindfulness, respects my need for alone time, and loves deep conversations under the stars."},
                {"prompt": "My ideal first date is", "answer": "A sunrise yoga session followed by a healthy breakfast and a hike to a beautiful viewpoint."}
            ]'::jsonb
        WHERE id = user3_id;
    END IF;

    -- Update Jake
    IF user4_id IS NOT NULL THEN
        UPDATE public.profiles SET
            photos = ARRAY['https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?w=800', 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800'],
            prompt_answers = '[
                {"prompt": "My simple pleasure is", "answer": "Finding the perfect local coffee roaster in every new town I visit. I keep a detailed map of my favorites."},
                {"prompt": "I''m really good at", "answer": "Rock climbing and finding hidden climbing spots. Always down for a climbing partner!"},
                {"prompt": "The best part of van life is", "answer": "Waking up at a new crag, making coffee, and climbing all day. Pure freedom."},
                {"prompt": "You can find me on weekends", "answer": "At the climbing gym or on a new route, always with a fresh cup of coffee in hand."},
                {"prompt": "I''m looking for someone who", "answer": "Loves climbing as much as I do, or is willing to learn. Coffee appreciation is a bonus!"},
                {"prompt": "My ideal first date is", "answer": "A morning climb followed by coffee at my favorite local roastery, then exploring the area together."}
            ]'::jsonb
        WHERE id = user4_id;
    END IF;

    -- Update Emma
    IF user5_id IS NOT NULL THEN
        UPDATE public.profiles SET
            photos = ARRAY['https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800', 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800', 'https://images.unsplash.com/photo-1502680390469-be75c86b636f?w=800', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800'],
            prompt_answers = '[
                {"prompt": "My simple pleasure is", "answer": "Discovering hole-in-the-wall restaurants and food trucks. I document every amazing meal I find."},
                {"prompt": "The best trip I ever took was", "answer": "A 6-month journey through the American Southwest, documenting the stories of fellow nomads I met along the way."},
                {"prompt": "I''m really good at", "answer": "Finding the best local spots - whether it''s food, hiking trails, or hidden gems. My blog readers trust my recommendations!"},
                {"prompt": "You can find me on weekends", "answer": "Exploring farmers markets, trying new restaurants, or hiking to find the perfect spot for my next blog post."},
                {"prompt": "I''m looking for someone who", "answer": "Loves food as much as I do and is always up for trying new places and sharing stories."},
                {"prompt": "My ideal first date is", "answer": "A food tour of the area - hitting up the best local spots, food trucks, and maybe a farmers market."}
            ]'::jsonb
        WHERE id = user5_id;
    END IF;

    -- Update Alex
    IF user6_id IS NOT NULL THEN
        UPDATE public.profiles SET
            photos = ARRAY['https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=800', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800', 'https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?w=800', 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800', 'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=800'],
            prompt_answers = '[
                {"prompt": "My simple pleasure is", "answer": "The smell of fresh sawdust and the satisfaction of a perfectly executed woodworking project in my mobile workshop."},
                {"prompt": "I''m really good at", "answer": "Building custom van conversions. I''ve helped over 20 people convert their vans into dream homes on wheels."},
                {"prompt": "A life goal of mine is", "answer": "Starting a van conversion business that helps others achieve their nomadic dreams."},
                {"prompt": "You can find me on weekends", "answer": "In my mobile workshop building something new, or out testing my latest van build on a mountain bike trail."},
                {"prompt": "I''m looking for someone who", "answer": "Appreciates craftsmanship, loves adventure, and maybe wants to learn a thing or two about van building."},
                {"prompt": "My ideal first date is", "answer": "A tour of my current van build project, followed by a mountain bike ride and beers at a local brewery."}
            ]'::jsonb
        WHERE id = user6_id;
    END IF;

    RAISE NOTICE 'Updated seed user profiles with prompt answers and photos';
END $$;
