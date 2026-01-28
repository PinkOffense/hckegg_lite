-- ============================================
-- HCKEgg Lite - Security Issues Fix
-- ============================================
-- Este script corrige os problemas de segurança identificados pelo Supabase:
-- 1. Views com SECURITY DEFINER -> SECURITY INVOKER
-- 2. Functions com mutable search_path -> SET search_path = ''
-- ============================================
-- Execute este SQL no Supabase SQL Editor
-- ============================================

-- ============================================
-- FIX 1: View daily_egg_records_with_stats
-- Issue: SECURITY DEFINER (default) should be SECURITY INVOKER
-- ============================================

DROP VIEW IF EXISTS public.daily_egg_records_with_stats;

CREATE VIEW public.daily_egg_records_with_stats
WITH (security_invoker = true)
AS
SELECT
    id,
    user_id,
    date,
    eggs_collected,
    eggs_consumed,
    (eggs_collected - eggs_consumed) AS eggs_remaining,
    notes,
    hen_count,
    created_at,
    updated_at
FROM public.daily_egg_records;

-- Grant permissions
GRANT SELECT ON public.daily_egg_records_with_stats TO authenticated;

COMMENT ON VIEW public.daily_egg_records_with_stats IS 'View com campos calculados para registos diários de ovos (SECURITY INVOKER)';

-- ============================================
-- FIX 2: View upcoming_vet_appointments
-- Issue: SECURITY DEFINER (default) should be SECURITY INVOKER
-- ============================================

DROP VIEW IF EXISTS public.upcoming_vet_appointments;

CREATE VIEW public.upcoming_vet_appointments
WITH (security_invoker = true)
AS
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

-- Grant permissions
GRANT SELECT ON public.upcoming_vet_appointments TO authenticated;

COMMENT ON VIEW public.upcoming_vet_appointments IS 'View of upcoming appointments with notification status and urgency indicators (SECURITY INVOKER)';

-- ============================================
-- FIX 3: Function check_overdue_appointments
-- Issue: Mutable search_path
-- ============================================

CREATE OR REPLACE FUNCTION check_overdue_appointments()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
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
$$;

-- ============================================
-- FIX 4: Function mark_notifications_as_sent
-- Issue: Mutable search_path
-- ============================================

CREATE OR REPLACE FUNCTION mark_notifications_as_sent(p_notification_ids UUID[])
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
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
$$;

-- ============================================
-- FIX 5: Function create_appointment_reminders
-- Issue: Mutable search_path
-- ============================================

CREATE OR REPLACE FUNCTION create_appointment_reminders()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
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
$$;

-- ============================================
-- FIX 6: Function get_due_appointment_notifications
-- Issue: Mutable search_path
-- ============================================

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
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
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
$$;

-- ============================================
-- FIX 7: Function get_user_stats
-- Issue: Mutable search_path
-- ============================================

CREATE OR REPLACE FUNCTION public.get_user_stats(p_user_id UUID DEFAULT NULL)
RETURNS TABLE (
    total_eggs BIGINT,
    total_sold BIGINT,
    total_revenue NUMERIC,
    total_expenses NUMERIC,
    net_profit NUMERIC,
    total_hens INTEGER,
    avg_eggs_per_day NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Use provided user_id or current user
    v_user_id := COALESCE(p_user_id, auth.uid());

    RETURN QUERY
    SELECT
        COALESCE(SUM(der.eggs_collected), 0)::BIGINT AS total_eggs,
        COALESCE(SUM(der.eggs_sold), 0)::BIGINT AS total_sold,
        COALESCE(SUM(der.eggs_sold * der.price_per_egg), 0)::NUMERIC AS total_revenue,
        COALESCE((SELECT SUM(e.amount) FROM public.expenses e WHERE e.user_id = v_user_id), 0)::NUMERIC AS total_expenses,
        (COALESCE(SUM(der.eggs_sold * der.price_per_egg), 0) -
         COALESCE((SELECT SUM(e.amount) FROM public.expenses e WHERE e.user_id = v_user_id), 0))::NUMERIC AS net_profit,
        COALESCE(MAX(der.hen_count), 0)::INTEGER AS total_hens,
        CASE
            WHEN COUNT(DISTINCT der.date) > 0
            THEN (SUM(der.eggs_collected)::NUMERIC / COUNT(DISTINCT der.date))
            ELSE 0
        END AS avg_eggs_per_day
    FROM public.daily_egg_records der
    WHERE der.user_id = v_user_id;
END;
$$;

-- ============================================
-- FIX 8: Function update_updated_at_column
-- Issue: Mutable search_path
-- ============================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- ============================================
-- VERIFICATION
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Security Issues Fixed Successfully!';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Views updated with SECURITY INVOKER:';
    RAISE NOTICE '  - daily_egg_records_with_stats';
    RAISE NOTICE '  - upcoming_vet_appointments';
    RAISE NOTICE '';
    RAISE NOTICE 'Functions updated with SET search_path = '''':';
    RAISE NOTICE '  - check_overdue_appointments()';
    RAISE NOTICE '  - mark_notifications_as_sent()';
    RAISE NOTICE '  - create_appointment_reminders()';
    RAISE NOTICE '  - get_due_appointment_notifications()';
    RAISE NOTICE '  - get_user_stats()';
    RAISE NOTICE '  - update_updated_at_column()';
    RAISE NOTICE '';
    RAISE NOTICE 'Next Steps (in Supabase Dashboard):';
    RAISE NOTICE '  1. Go to Authentication -> Settings -> MFA';
    RAISE NOTICE '     Enable at least one MFA option';
    RAISE NOTICE '  2. Go to Authentication -> Settings -> Password Protection';
    RAISE NOTICE '     Enable "Check for compromised passwords"';
    RAISE NOTICE '';
    RAISE NOTICE 'After running this script, refresh the Supabase';
    RAISE NOTICE 'dashboard to verify the security issues are resolved.';
    RAISE NOTICE '============================================';
END $$;
