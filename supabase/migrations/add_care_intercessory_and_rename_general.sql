-- Existing installations: run this migration instead of rerunning schema.sql.
-- Preserve the department ID, item assignments, item codes, and activity logs.
BEGIN;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.departments WHERE department_name = 'Uncategorized')
     AND EXISTS (SELECT 1 FROM public.departments WHERE department_name = 'General') THEN
    RAISE EXCEPTION 'Both Uncategorized and General exist. Resolve the duplicate departments before running this migration.';
  END IF;
END $$;

UPDATE public.departments
SET department_name = 'General'
WHERE department_name = 'Uncategorized';

INSERT INTO public.departments (department_name)
VALUES ('Care Department'), ('Intercessory Department'), ('General')
ON CONFLICT (department_name) DO NOTHING;

COMMIT;
