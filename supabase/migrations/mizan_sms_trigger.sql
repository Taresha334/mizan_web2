-- 1. Create the trigger function
CREATE OR REPLACE FUNCTION public.on_agent_verified_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Only fire when status changes to 'auto_verified'
    IF NEW.status = 'auto_verified' AND (OLD.status IS NULL OR OLD.status != 'auto_verified') THEN
        -- Invoke the Edge Function 'commander-sms-relay'
        PERFORM net.http_post(
            url := 'https://your-project-ref.functions.supabase.co/commander-sms-relay',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
            ),
            body := jsonb_build_object(
                'record', row_to_json(NEW)
            )
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Attach the trigger to your agents/partners table
CREATE TRIGGER tr_on_agent_verified
    AFTER UPDATE ON public.agents -- Ensure this matches your table name
    FOR EACH ROW
    EXECUTE FUNCTION on_agent_verified_trigger();