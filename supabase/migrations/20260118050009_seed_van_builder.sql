-- Migration: Seed Van Builder Community Data
-- Description: Add sample messages and resources for Van Builder

-- Add sample resources
INSERT INTO public.van_builder_resources (title, description, category, views, saves) VALUES
    ('Complete Electrical Wiring Guide', 'A comprehensive guide to wiring your van conversion, including DC and AC systems.', 'Electrical', 12453, 892),
    ('Solar System Sizing Calculator', 'Interactive calculator to determine the right solar setup for your needs.', 'Solar', 8721, 1205),
    ('Insulation Best Practices', 'Learn the best methods and materials for insulating your van.', 'HVAC', 6543, 734),
    ('Water System Diagram Templates', 'Ready-to-use diagrams for planning your water system.', 'Plumbing', 5892, 621),
    ('Battery Bank Wiring Diagrams', 'Common configurations for lithium and AGM battery banks.', 'Electrical', 4521, 543),
    ('Ventilation Fan Installation Guide', 'Step-by-step guide for installing roof fans.', 'HVAC', 3892, 412);
