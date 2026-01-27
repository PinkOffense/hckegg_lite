-- ============================================
-- HCKEgg Lite - Vet Appointment Notifications Schema
-- ============================================
-- Execute este SQL no Supabase SQL Editor
-- Este script adiciona tabelas para notificações de consultas veterinárias
-- ============================================

-- ============================================
-- STEP 1: DROP EXISTING OBJECTS (IF ANY)
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own vet appointments" ON public.vet_appointments;
DROP POLICY IF EXISTS "Users can insert their own vet appointments" ON public.vet_appointments;
DROP POLICY IF EXISTS "Users can update their own vet appointments" ON public.vet_appointments;
DROP POLICY IF EXISTS "Users can delete their own vet appointments" ON public.vet_appointments;

DROP POLICY IF EXISTS "Users can view their own notification settings" ON public.notification_settings;
DROP POLICY IF EXISTS "Users can insert their own notification settings" ON public.notification_settings;
DROP POLICY IF EXISTS "Users can update their own notification settings" ON public.notification_settings;

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can insert their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;

DROP POLICY IF EXISTS "Users can view their own push tokens" ON public.push_tokens;
DROP POLICY IF EXISTS "Users can insert their own push tokens" ON public.push_tokens;
DROP POLICY IF EXISTS "Users can update their own push tokens" ON public.push_tokens;
DROP POLICY IF EXISTS "Users can delete their own push tokens" ON public.push_tokens;

-- Drop views
DROP VIEW IF EXISTS public.upcoming_vet_appointments;

-- Drop functions
DROP FUNCTION IF EXISTS get_due_appointment_notifications(INTEGER);
DROP FUNCTION IF EXISTS mark_notifications_as_sent(UUID[]);

-- Drop triggers
DROP TRIGGER IF EXISTS update_vet_appointments_updated_at ON public.vet_appointments;
DROP TRIGGER IF EXISTS update_notification_settings_updated_at ON public.notification_settings;
DROP TRIGGER IF EXISTS update_notifications_updated_at ON public.notifications;
DROP TRIGGER IF EXISTS update_push_tokens_updated_at ON public.push_tokens;
DROP TRIGGER IF EXISTS create_appointment_notification ON public.vet_appointments;

-- Drop tables (in correct order due to foreign keys)
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.push_tokens CASCADE;
DROP TABLE IF EXISTS public.notification_settings CASCADE;
DROP TABLE IF EXISTS public.vet_appointments CASCADE;

-- ============================================
-- STEP 2: CREATE TABLES
-- ============================================

-- ============================================
-- TABLE: vet_appointments
-- Purpose: Dedicated table for scheduling vet appointments
-- Separates scheduled visits from vet_records (historical records)
-- ============================================
CREATE TABLE IF NOT EXISTS public.vet_appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Appointment details
    title VARCHAR(200) NOT NULL,
    description TEXT,
    appointment_date DATE NOT NULL,
    appointment_time TIME,

    -- Vet/Clinic information
    vet_name VARCHAR(200),
    vet_clinic VARCHAR(200),
    vet_phone VARCHAR(50),
    vet_address TEXT,

    -- Appointment type and status
    appointment_type VARCHAR(50) NOT NULL DEFAULT 'checkup'
        CHECK (appointment_type IN ('checkup', 'vaccine', 'treatment', 'surgery', 'emergency', 'follow_up', 'other')),
    status VARCHAR(50) NOT NULL DEFAULT 'scheduled'
        CHECK (status IN ('scheduled', 'confirmed', 'completed', 'cancelled', 'missed')),

    -- Related data
    hens_involved INTEGER DEFAULT 0 CHECK (hens_involved >= 0),
    estimated_cost DECIMAL(10, 2) CHECK (estimated_cost >= 0),
    notes TEXT,

    -- Link to original vet_record if this is a follow-up
    related_vet_record_id UUID REFERENCES public.vet_records(id) ON DELETE SET NULL,

    -- Notification settings for this specific appointment
    reminder_days_before INTEGER[] DEFAULT ARRAY[1, 7],

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for vet_appointments
CREATE INDEX idx_vet_appointments_user_date ON public.vet_appointments(user_id, appointment_date);
CREATE INDEX idx_vet_appointments_user_status ON public.vet_appointments(user_id, status);
CREATE INDEX idx_vet_appointments_upcoming ON public.vet_appointments(user_id, appointment_date)
    WHERE status IN ('scheduled', 'confirmed');
CREATE INDEX idx_vet_appointments_user_created ON public.vet_appointments(user_id, created_at DESC);

COMMENT ON TABLE public.vet_appointments IS 'Scheduled vet appointments for future visits';
COMMENT ON COLUMN public.vet_appointments.appointment_type IS 'Type: checkup, vaccine, treatment, surgery, emergency, follow_up, other';
COMMENT ON COLUMN public.vet_appointments.status IS 'Status: scheduled, confirmed, completed, cancelled, missed';
COMMENT ON COLUMN public.vet_appointments.reminder_days_before IS 'Array of days before appointment to send reminders (e.g., [1, 7] = 1 day and 7 days before)';
COMMENT ON COLUMN public.vet_appointments.related_vet_record_id IS 'Link to vet_record if this is a follow-up appointment';

-- ============================================
-- TABLE: notification_settings
-- Purpose: User preferences for notifications
-- ============================================
CREATE TABLE IF NOT EXISTS public.notification_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- General notification toggles
    notifications_enabled BOOLEAN NOT NULL DEFAULT true,
    push_notifications_enabled BOOLEAN NOT NULL DEFAULT true,
    email_notifications_enabled BOOLEAN NOT NULL DEFAULT false,

    -- Vet appointment notification settings
    vet_appointment_reminders BOOLEAN NOT NULL DEFAULT true,
    vet_appointment_reminder_days INTEGER[] NOT NULL DEFAULT ARRAY[1, 3, 7],
    vet_appointment_reminder_time TIME NOT NULL DEFAULT '09:00:00',

    -- Overdue notifications
    overdue_appointment_alerts BOOLEAN NOT NULL DEFAULT true,

    -- Health alert notifications (from vet_records with high severity)
    health_alerts_enabled BOOLEAN NOT NULL DEFAULT true,
    health_alert_severity_threshold VARCHAR(50) NOT NULL DEFAULT 'medium'
        CHECK (health_alert_severity_threshold IN ('low', 'medium', 'high', 'critical')),

    -- Quiet hours (no notifications during these times)
    quiet_hours_enabled BOOLEAN NOT NULL DEFAULT false,
    quiet_hours_start TIME DEFAULT '22:00:00',
    quiet_hours_end TIME DEFAULT '07:00:00',

    -- Timezone for scheduling
    timezone VARCHAR(100) NOT NULL DEFAULT 'Europe/Lisbon',

    -- Language preference for notifications
    notification_language VARCHAR(10) NOT NULL DEFAULT 'pt',

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- One settings record per user
    CONSTRAINT unique_user_notification_settings UNIQUE(user_id)
);

-- Index for notification_settings
CREATE INDEX idx_notification_settings_user ON public.notification_settings(user_id);

COMMENT ON TABLE public.notification_settings IS 'User notification preferences and settings';
COMMENT ON COLUMN public.notification_settings.vet_appointment_reminder_days IS 'Array of days before appointment to send reminders';
COMMENT ON COLUMN public.notification_settings.health_alert_severity_threshold IS 'Minimum severity to trigger health alerts';
COMMENT ON COLUMN public.notification_settings.quiet_hours_enabled IS 'If true, no notifications during quiet hours';

-- ============================================
-- TABLE: notifications
-- Purpose: Store all notifications (sent, pending, read)
-- ============================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Notification content
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,

    -- Notification type and source
    notification_type VARCHAR(50) NOT NULL
        CHECK (notification_type IN ('vet_appointment_reminder', 'vet_appointment_overdue', 'health_alert', 'follow_up_reminder', 'general')),

    -- Priority level
    priority VARCHAR(20) NOT NULL DEFAULT 'normal'
        CHECK (priority IN ('low', 'normal', 'high', 'urgent')),

    -- Related entities (optional, for deep linking)
    related_appointment_id UUID REFERENCES public.vet_appointments(id) ON DELETE SET NULL,
    related_vet_record_id UUID REFERENCES public.vet_records(id) ON DELETE SET NULL,

    -- Notification status
    status VARCHAR(50) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'sent', 'delivered', 'read', 'failed', 'cancelled')),

    -- Scheduling
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,

    -- Delivery channels used
    sent_via_push BOOLEAN DEFAULT false,
    sent_via_email BOOLEAN DEFAULT false,

    -- Error tracking
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,

    -- Additional data (JSON for flexibility)
    metadata JSONB DEFAULT '{}',

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for notifications
CREATE INDEX idx_notifications_user_status ON public.notifications(user_id, status);
CREATE INDEX idx_notifications_user_created ON public.notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_scheduled ON public.notifications(scheduled_for) WHERE status = 'pending';
CREATE INDEX idx_notifications_user_unread ON public.notifications(user_id) WHERE status IN ('sent', 'delivered');
CREATE INDEX idx_notifications_appointment ON public.notifications(related_appointment_id) WHERE related_appointment_id IS NOT NULL;

COMMENT ON TABLE public.notifications IS 'All notifications sent to users';
COMMENT ON COLUMN public.notifications.notification_type IS 'Type: vet_appointment_reminder, vet_appointment_overdue, health_alert, follow_up_reminder, general';
COMMENT ON COLUMN public.notifications.status IS 'Status: pending, sent, delivered, read, failed, cancelled';
COMMENT ON COLUMN public.notifications.metadata IS 'Additional JSON data for the notification';

-- ============================================
-- TABLE: push_tokens
-- Purpose: Store device push notification tokens (FCM, APNs)
-- ============================================
CREATE TABLE IF NOT EXISTS public.push_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Token information
    token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('android', 'ios', 'web')),

    -- Device information
    device_id VARCHAR(200),
    device_name VARCHAR(200),
    device_model VARCHAR(200),
    app_version VARCHAR(50),

    -- Token validity
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Unique token per device
    CONSTRAINT unique_push_token UNIQUE(token)
);

-- Indexes for push_tokens
CREATE INDEX idx_push_tokens_user ON public.push_tokens(user_id);
CREATE INDEX idx_push_tokens_active ON public.push_tokens(user_id) WHERE is_active = true;

COMMENT ON TABLE public.push_tokens IS 'Device push notification tokens for FCM/APNs';
COMMENT ON COLUMN public.push_tokens.platform IS 'Platform: android, ios, web';
COMMENT ON COLUMN public.push_tokens.is_active IS 'Whether this token is still valid for notifications';

-- ============================================
-- STEP 3: CREATE TRIGGERS
-- ============================================

-- Trigger for vet_appointments updated_at
CREATE TRIGGER update_vet_appointments_updated_at
    BEFORE UPDATE ON public.vet_appointments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for notification_settings updated_at
CREATE TRIGGER update_notification_settings_updated_at
    BEFORE UPDATE ON public.notification_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for notifications updated_at
CREATE TRIGGER update_notifications_updated_at
    BEFORE UPDATE ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for push_tokens updated_at
CREATE TRIGGER update_push_tokens_updated_at
    BEFORE UPDATE ON public.push_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 4: CREATE FUNCTION TO AUTO-CREATE NOTIFICATIONS
-- ============================================

-- Function: Create reminder notifications when appointment is created/updated
CREATE OR REPLACE FUNCTION create_appointment_reminders()
RETURNS TRIGGER AS $$
DECLARE
    reminder_day INTEGER;
    reminder_date TIMESTAMP WITH TIME ZONE;
    user_settings RECORD;
    notification_title TEXT;
    notification_body TEXT;
BEGIN
    -- Only process if status is scheduled or confirmed
    IF NEW.status NOT IN ('scheduled', 'confirmed') THEN
        RETURN NEW;
    END IF;

    -- Get user notification settings
    SELECT * INTO user_settings
    FROM public.notification_settings
    WHERE user_id = NEW.user_id;

    -- If no settings exist, create default settings
    IF user_settings IS NULL THEN
        INSERT INTO public.notification_settings (user_id)
        VALUES (NEW.user_id)
        RETURNING * INTO user_settings;
    END IF;

    -- Check if notifications are enabled
    IF NOT user_settings.notifications_enabled OR NOT user_settings.vet_appointment_reminders THEN
        RETURN NEW;
    END IF;

    -- Cancel any existing pending notifications for this appointment
    UPDATE public.notifications
    SET status = 'cancelled', updated_at = NOW()
    WHERE related_appointment_id = NEW.id AND status = 'pending';

    -- Create notifications for each reminder day
    FOREACH reminder_day IN ARRAY COALESCE(NEW.reminder_days_before, user_settings.vet_appointment_reminder_days)
    LOOP
        -- Calculate reminder date
        reminder_date := (NEW.appointment_date - (reminder_day || ' days')::INTERVAL)::DATE
            + user_settings.vet_appointment_reminder_time;

        -- Only create if reminder date is in the future
        IF reminder_date > NOW() THEN
            -- Generate notification content based on language
            IF user_settings.notification_language = 'pt' THEN
                notification_title := 'Lembrete: Consulta Veterinária';
                notification_body := format('Tem uma consulta (%s) agendada para %s.',
                    NEW.title,
                    CASE
                        WHEN reminder_day = 0 THEN 'hoje'
                        WHEN reminder_day = 1 THEN 'amanhã'
                        ELSE format('daqui a %s dias', reminder_day)
                    END);
            ELSE
                notification_title := 'Reminder: Vet Appointment';
                notification_body := format('You have an appointment (%s) scheduled for %s.',
                    NEW.title,
                    CASE
                        WHEN reminder_day = 0 THEN 'today'
                        WHEN reminder_day = 1 THEN 'tomorrow'
                        ELSE format('in %s days', reminder_day)
                    END);
            END IF;

            -- Insert notification
            INSERT INTO public.notifications (
                user_id,
                title,
                body,
                notification_type,
                priority,
                related_appointment_id,
                status,
                scheduled_for,
                metadata
            ) VALUES (
                NEW.user_id,
                notification_title,
                notification_body,
                'vet_appointment_reminder',
                CASE WHEN reminder_day <= 1 THEN 'high' ELSE 'normal' END,
                NEW.id,
                'pending',
                reminder_date,
                jsonb_build_object(
                    'appointment_date', NEW.appointment_date,
                    'appointment_type', NEW.appointment_type,
                    'reminder_days_before', reminder_day,
                    'vet_name', NEW.vet_name,
                    'vet_clinic', NEW.vet_clinic
                )
            );
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create notifications
CREATE TRIGGER create_appointment_notification
    AFTER INSERT OR UPDATE OF appointment_date, status, reminder_days_before
    ON public.vet_appointments
    FOR EACH ROW
    EXECUTE FUNCTION create_appointment_reminders();

-- ============================================
-- STEP 5: CREATE HELPER FUNCTIONS
-- ============================================

-- Function: Get notifications that are due to be sent
CREATE OR REPLACE FUNCTION get_due_appointment_notifications(p_limit INTEGER DEFAULT 100)
RETURNS TABLE (
    notification_id UUID,
    user_id UUID,
    title VARCHAR(200),
    body TEXT,
    notification_type VARCHAR(50),
    priority VARCHAR(20),
    related_appointment_id UUID,
    metadata JSONB,
    push_tokens TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        n.id AS notification_id,
        n.user_id,
        n.title,
        n.body,
        n.notification_type,
        n.priority,
        n.related_appointment_id,
        n.metadata,
        ARRAY_AGG(pt.token) FILTER (WHERE pt.token IS NOT NULL) AS push_tokens
    FROM public.notifications n
    LEFT JOIN public.push_tokens pt ON pt.user_id = n.user_id AND pt.is_active = true
    JOIN public.notification_settings ns ON ns.user_id = n.user_id
    WHERE n.status = 'pending'
      AND n.scheduled_for <= NOW()
      AND ns.notifications_enabled = true
      AND ns.push_notifications_enabled = true
      -- Check quiet hours
      AND (
          NOT ns.quiet_hours_enabled
          OR NOT (
              CURRENT_TIME BETWEEN ns.quiet_hours_start AND '23:59:59'::TIME
              OR CURRENT_TIME BETWEEN '00:00:00'::TIME AND ns.quiet_hours_end
          )
      )
    GROUP BY n.id, n.user_id, n.title, n.body, n.notification_type, n.priority,
             n.related_appointment_id, n.metadata
    ORDER BY n.priority DESC, n.scheduled_for ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Mark notifications as sent
CREATE OR REPLACE FUNCTION mark_notifications_as_sent(p_notification_ids UUID[])
RETURNS INTEGER AS $$
DECLARE
    rows_updated INTEGER;
BEGIN
    UPDATE public.notifications
    SET
        status = 'sent',
        sent_at = NOW(),
        sent_via_push = true,
        updated_at = NOW()
    WHERE id = ANY(p_notification_ids)
      AND status = 'pending';

    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    RETURN rows_updated;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Create overdue notifications for missed appointments
CREATE OR REPLACE FUNCTION check_overdue_appointments()
RETURNS INTEGER AS $$
DECLARE
    appointment RECORD;
    user_settings RECORD;
    notification_title TEXT;
    notification_body TEXT;
    notifications_created INTEGER := 0;
BEGIN
    -- Find appointments that are overdue (past date, still scheduled/confirmed)
    FOR appointment IN
        SELECT va.*
        FROM public.vet_appointments va
        WHERE va.appointment_date < CURRENT_DATE
          AND va.status IN ('scheduled', 'confirmed')
    LOOP
        -- Get user settings
        SELECT * INTO user_settings
        FROM public.notification_settings
        WHERE user_id = appointment.user_id;

        -- Skip if overdue alerts disabled
        IF user_settings IS NULL OR NOT user_settings.overdue_appointment_alerts THEN
            CONTINUE;
        END IF;

        -- Check if we already sent an overdue notification
        IF EXISTS (
            SELECT 1 FROM public.notifications
            WHERE related_appointment_id = appointment.id
              AND notification_type = 'vet_appointment_overdue'
              AND status != 'cancelled'
        ) THEN
            CONTINUE;
        END IF;

        -- Generate notification content
        IF user_settings.notification_language = 'pt' THEN
            notification_title := 'Consulta em Atraso!';
            notification_body := format('A consulta "%s" estava agendada para %s. Por favor, reagende ou marque como concluída.',
                appointment.title,
                to_char(appointment.appointment_date, 'DD/MM/YYYY'));
        ELSE
            notification_title := 'Overdue Appointment!';
            notification_body := format('The appointment "%s" was scheduled for %s. Please reschedule or mark as completed.',
                appointment.title,
                to_char(appointment.appointment_date, 'YYYY-MM-DD'));
        END IF;

        -- Create overdue notification
        INSERT INTO public.notifications (
            user_id,
            title,
            body,
            notification_type,
            priority,
            related_appointment_id,
            status,
            scheduled_for,
            metadata
        ) VALUES (
            appointment.user_id,
            notification_title,
            notification_body,
            'vet_appointment_overdue',
            'urgent',
            appointment.id,
            'pending',
            NOW(),
            jsonb_build_object(
                'appointment_date', appointment.appointment_date,
                'appointment_type', appointment.appointment_type,
                'days_overdue', CURRENT_DATE - appointment.appointment_date
            )
        );

        -- Update appointment status to missed
        UPDATE public.vet_appointments
        SET status = 'missed', updated_at = NOW()
        WHERE id = appointment.id;

        notifications_created := notifications_created + 1;
    END LOOP;

    RETURN notifications_created;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- STEP 6: CREATE VIEWS
-- ============================================

-- View: Upcoming appointments with notification status
CREATE OR REPLACE VIEW public.upcoming_vet_appointments AS
SELECT
    va.id,
    va.user_id,
    va.title,
    va.description,
    va.appointment_date,
    va.appointment_time,
    va.vet_name,
    va.vet_clinic,
    va.vet_phone,
    va.appointment_type,
    va.status,
    va.hens_involved,
    va.estimated_cost,
    va.notes,
    va.created_at,
    -- Calculated fields
    (va.appointment_date - CURRENT_DATE) AS days_until,
    CASE
        WHEN va.appointment_date < CURRENT_DATE THEN 'overdue'
        WHEN va.appointment_date = CURRENT_DATE THEN 'today'
        WHEN va.appointment_date = CURRENT_DATE + 1 THEN 'tomorrow'
        WHEN va.appointment_date <= CURRENT_DATE + 7 THEN 'this_week'
        WHEN va.appointment_date <= CURRENT_DATE + 30 THEN 'this_month'
        ELSE 'future'
    END AS urgency,
    -- Notification counts
    (
        SELECT COUNT(*)
        FROM public.notifications n
        WHERE n.related_appointment_id = va.id AND n.status = 'pending'
    ) AS pending_notifications,
    (
        SELECT COUNT(*)
        FROM public.notifications n
        WHERE n.related_appointment_id = va.id AND n.status = 'sent'
    ) AS sent_notifications
FROM public.vet_appointments va
WHERE va.status IN ('scheduled', 'confirmed')
ORDER BY va.appointment_date ASC;

COMMENT ON VIEW public.upcoming_vet_appointments IS 'View of upcoming appointments with notification status and urgency indicators';

-- ============================================
-- STEP 7: ENABLE ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.vet_appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 8: CREATE RLS POLICIES
-- ============================================

-- Policies for vet_appointments
CREATE POLICY "Users can view their own vet appointments"
    ON public.vet_appointments FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own vet appointments"
    ON public.vet_appointments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own vet appointments"
    ON public.vet_appointments FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own vet appointments"
    ON public.vet_appointments FOR DELETE
    USING (auth.uid() = user_id);

-- Policies for notification_settings
CREATE POLICY "Users can view their own notification settings"
    ON public.notification_settings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notification settings"
    ON public.notification_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notification settings"
    ON public.notification_settings FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policies for notifications
CREATE POLICY "Users can view their own notifications"
    ON public.notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notifications"
    ON public.notifications FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
    ON public.notifications FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notifications"
    ON public.notifications FOR DELETE
    USING (auth.uid() = user_id);

-- Policies for push_tokens
CREATE POLICY "Users can view their own push tokens"
    ON public.push_tokens FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own push tokens"
    ON public.push_tokens FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own push tokens"
    ON public.push_tokens FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own push tokens"
    ON public.push_tokens FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- STEP 9: GRANT PERMISSIONS
-- ============================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.vet_appointments TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.notification_settings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.push_tokens TO authenticated;

GRANT SELECT ON public.upcoming_vet_appointments TO authenticated;

-- Service role needs full access for background jobs
GRANT ALL ON public.vet_appointments TO service_role;
GRANT ALL ON public.notification_settings TO service_role;
GRANT ALL ON public.notifications TO service_role;
GRANT ALL ON public.push_tokens TO service_role;

-- ============================================
-- COMPLETION MESSAGE
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Vet Notifications Schema Created Successfully!';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'New Tables Created:';
    RAISE NOTICE '  - vet_appointments: Scheduled vet visits';
    RAISE NOTICE '  - notification_settings: User notification preferences';
    RAISE NOTICE '  - notifications: Notification history and queue';
    RAISE NOTICE '  - push_tokens: Device push notification tokens';
    RAISE NOTICE '';
    RAISE NOTICE 'New Views:';
    RAISE NOTICE '  - upcoming_vet_appointments: Upcoming visits with urgency';
    RAISE NOTICE '';
    RAISE NOTICE 'New Functions:';
    RAISE NOTICE '  - create_appointment_reminders(): Auto-creates notifications';
    RAISE NOTICE '  - get_due_appointment_notifications(): Gets pending notifications';
    RAISE NOTICE '  - mark_notifications_as_sent(): Marks notifications as sent';
    RAISE NOTICE '  - check_overdue_appointments(): Creates overdue alerts';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '  1. Run this script in Supabase SQL Editor';
    RAISE NOTICE '  2. Implement Flutter notification service';
    RAISE NOTICE '  3. Add Firebase Cloud Messaging (FCM) for push notifications';
    RAISE NOTICE '  4. Create a Supabase Edge Function or cron job to process notifications';
    RAISE NOTICE '============================================';
END $$;
