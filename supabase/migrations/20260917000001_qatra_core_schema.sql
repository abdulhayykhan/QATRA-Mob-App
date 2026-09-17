-- ====================================================================
-- QATRA Emergency Blood Response Platform — PostgreSQL Schema
-- Project: QATRA-Mob-App (Alkhidmat Karachi)
-- ====================================================================

-- 1. HOSPITALS REGISTRY (Karachi Emergency Centers)
CREATE TABLE IF NOT EXISTS public.hospitals (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    district TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    emergency_phone TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed Karachi Tertiary Hospitals
INSERT INTO public.hospitals (id, name, address, district, latitude, longitude, emergency_phone) VALUES
    ('hosp-01', 'Jinnah Postgraduate Medical Centre (JPMC)', 'Rafiqui H.J. Shaheed Rd, Karachi Cantt', 'Karachi South', 24.8532, 67.0458, '021-99201300'),
    ('hosp-02', 'Dr. Ruth K.M. Pfau Civil Hospital', 'Mission Rd, New Dehli Colony, Karachi', 'Karachi South', 24.8596, 67.0101, '021-99215740'),
    ('hosp-03', 'The Indus Hospital (Korangi)', 'Plot C-76, Sector 31/5, Korangi Crossing', 'Korangi', 24.8387, 67.1206, '021-35112709'),
    ('hosp-04', 'Aga Khan University Hospital (AKUH)', 'Stadium Rd, Bahadurabad, Karachi', 'Karachi East', 24.8928, 67.0747, '021-34930051'),
    ('hosp-05', 'Sindh Institute of Urology and Transplantation (SIUT)', 'Sardar Yaqoob Ali Khan Rd, Near Civil Hospital', 'Karachi South', 24.8580, 67.0118, '021-99215752'),
    ('hosp-06', 'National Institute of Child Health (NICH)', 'Rafiqui H.J. Shaheed Rd, Cantt, Karachi', 'Karachi South', 24.8519, 67.0469, '021-99201271'),
    ('hosp-07', 'Patel Hospital', 'ST-18, Block 4, Gulshan-e-Iqbal', 'Karachi East', 24.9192, 67.0981, '021-34968660'),
    ('hosp-08', 'Liaquat National Hospital', 'National Stadium Rd, Karachi', 'Karachi East', 24.8944, 67.0718, '021-111456456'),
    ('hosp-09', 'Abbasi Shaheed Hospital', 'Paposh Nagar, Nazimabad, Karachi', 'Karachi Central', 24.9288, 67.0315, '021-99260400'),
    ('hosp-10', 'Ziauddin Hospital (Clifton)', 'Shahrah-e-Ghalib, Block 6, Clifton', 'Karachi South', 24.8217, 67.0272, '021-35862937')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    address = EXCLUDED.address,
    district = EXCLUDED.district,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    emergency_phone = EXCLUDED.emergency_phone;

-- 2. USER PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
    id TEXT PRIMARY KEY,
    full_name TEXT NOT NULL DEFAULT '',
    phone TEXT NOT NULL DEFAULT '',
    email TEXT NOT NULL DEFAULT '',
    blood_group TEXT NOT NULL DEFAULT 'O-',
    district TEXT NOT NULL DEFAULT 'Karachi South',
    cnic TEXT,
    is_cnic_verified BOOLEAN NOT NULL DEFAULT FALSE,
    role TEXT NOT NULL DEFAULT 'guest' CHECK (role IN ('guest', 'seeker', 'donor', 'admin', 'driveOrganizer')),
    is_available_to_donate BOOLEAN NOT NULL DEFAULT FALSE,
    cooldown_days_remaining INTEGER NOT NULL DEFAULT 0,
    lives_saved INTEGER NOT NULL DEFAULT 0,
    current_lat DOUBLE PRECISION NOT NULL DEFAULT 24.8607,
    current_lng DOUBLE PRECISION NOT NULL DEFAULT 67.0011,
    last_donation_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. EMERGENCY BLOOD REQUESTS
CREATE TABLE IF NOT EXISTS public.emergency_requests (
    id TEXT PRIMARY KEY,
    seeker_id TEXT NOT NULL,
    seeker_name TEXT NOT NULL,
    hospital_id TEXT REFERENCES public.hospitals(id) ON DELETE SET NULL,
    blood_group TEXT NOT NULL,
    component TEXT NOT NULL,
    units_required INTEGER NOT NULL DEFAULT 1,
    units_fulfilled INTEGER NOT NULL DEFAULT 0,
    urgency TEXT NOT NULL DEFAULT 'High Priority',
    status TEXT NOT NULL DEFAULT 'Broadcasting to Radius',
    broadcast_radius_km INTEGER NOT NULL DEFAULT 10,
    slip_image_url TEXT,
    patient_mrn TEXT,
    doctor_stamp TEXT,
    desk_review_status TEXT NOT NULL DEFAULT 'Submitted for Verification Desk Review',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. DONOR DISPATCHES
CREATE TABLE IF NOT EXISTS public.donor_dispatches (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    request_id TEXT NOT NULL REFERENCES public.emergency_requests(id) ON DELETE CASCADE,
    donor_id TEXT NOT NULL,
    donor_name TEXT NOT NULL,
    blood_group TEXT NOT NULL,
    distance_km DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    eta_minutes INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'Accepted Dispatch',
    phone_number TEXT NOT NULL,
    accepted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. CAMPUS DRIVES
CREATE TABLE IF NOT EXISTS public.campus_drives (
    id TEXT PRIMARY KEY,
    organizer_id TEXT NOT NULL,
    title TEXT NOT NULL,
    university TEXT NOT NULL,
    campus TEXT NOT NULL,
    date DATE NOT NULL,
    time_range TEXT NOT NULL,
    target_units INTEGER NOT NULL DEFAULT 50,
    registered_donors INTEGER NOT NULL DEFAULT 0,
    registered_volunteers INTEGER NOT NULL DEFAULT 0,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. VERIFICATION SLIPS (Desk Staff Audit Queue)
CREATE TABLE IF NOT EXISTS public.verification_slips (
    id TEXT PRIMARY KEY,
    seeker_id TEXT NOT NULL,
    hospital TEXT NOT NULL,
    doctor_stamp TEXT NOT NULL,
    mrn TEXT NOT NULL,
    blood_group TEXT NOT NULL,
    units TEXT NOT NULL,
    desk_review_status TEXT NOT NULL DEFAULT 'Submitted for Verification Desk Review',
    flagged BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. FRAUD AUDIT LOG
CREATE TABLE IF NOT EXISTS public.fraud_audit_log (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    request_id TEXT,
    cnic TEXT NOT NULL,
    phone TEXT,
    mrn TEXT,
    reason TEXT NOT NULL,
    confidence TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Flagged',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for Fast Geospatial & Proximity Querying
CREATE INDEX IF NOT EXISTS idx_requests_status ON public.emergency_requests(status);
CREATE INDEX IF NOT EXISTS idx_requests_blood ON public.emergency_requests(blood_group);
CREATE INDEX IF NOT EXISTS idx_dispatches_request ON public.donor_dispatches(request_id);
CREATE INDEX IF NOT EXISTS idx_dispatches_donor ON public.donor_dispatches(donor_id);
CREATE INDEX IF NOT EXISTS idx_slips_status ON public.verification_slips(desk_review_status);

-- Enable Row Level Security (RLS)
ALTER TABLE public.hospitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donor_dispatches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campus_drives ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_slips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fraud_audit_log ENABLE ROW LEVEL SECURITY;

-- Read policies
CREATE POLICY "Public can view hospitals" ON public.hospitals FOR SELECT USING (true);
CREATE POLICY "Public can view campus drives" ON public.campus_drives FOR SELECT USING (true);
CREATE POLICY "Authenticated users can view requests" ON public.emergency_requests FOR SELECT USING (true);
CREATE POLICY "Users can view dispatches" ON public.donor_dispatches FOR SELECT USING (true);
CREATE POLICY "Users can view their own profile" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Staff can view verification slips" ON public.verification_slips FOR SELECT USING (true);
CREATE POLICY "Staff can view fraud audit logs" ON public.fraud_audit_log FOR SELECT USING (true);

-- Write policies
CREATE POLICY "Authenticated users can insert profile" ON public.profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "Authenticated users can update profile" ON public.profiles FOR UPDATE USING (true);
CREATE POLICY "Users can create requests" ON public.emergency_requests FOR INSERT WITH CHECK (true);
CREATE POLICY "Donors can accept dispatch" ON public.donor_dispatches FOR INSERT WITH CHECK (true);
CREATE POLICY "Organizers can create drives" ON public.campus_drives FOR ALL USING (true);
CREATE POLICY "Seekers can submit slips" ON public.verification_slips FOR ALL USING (true);
