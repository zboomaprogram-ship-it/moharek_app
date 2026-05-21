-- Relax check constraint on results.result_type to support both Moharek and Rabhan result types
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT tc.constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu
          ON ccu.constraint_name = tc.constraint_name
          AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'CHECK'
          AND tc.table_name = 'results'
          AND ccu.column_name = 'result_type'
    LOOP
        EXECUTE 'ALTER TABLE results DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
END $$;
