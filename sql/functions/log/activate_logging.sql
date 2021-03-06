
-- this function creates a log function for each table found in the
-- log schema and registers those functions as trigger
CREATE OR REPLACE FUNCTION log.activate_logging() RETURNS VOID AS $$
  DECLARE
    fundef      TEXT;
    trigdef     TEXT;
    trigname    TEXT;
    procname    TEXT;
    tablename   TEXT;
    tableschema TEXT;
    columns     TEXT;
    columns_old TEXT;
    columns_new TEXT;
  BEGIN
    FOR tablename IN
      SELECT table_name FROM information_schema.tables WHERE table_schema = 'log' AND EXISTS( SELECT 1 FROM information_schema.tables AS interior WHERE table_schema IN ('auth','conflict','custom','public') AND interior.table_name = tables.table_name )
    LOOP
      SELECT INTO tableschema table_schema FROM information_schema.tables WHERE table_schema IN ('auth','conflict','custom','public') AND table_name = tablename;
      RAISE NOTICE 'Creating log function for table %', tablename;
      -- (re)creating trigger function
      procname = tablename || '_log_function';

      SELECT INTO columns array_to_string(ARRAY(SELECT quote_ident(column_name::text) from information_schema.columns WHERE table_name = tablename AND table_schema = tableschema ORDER BY ordinal_position),',');
      SELECT INTO columns_old array_to_string(ARRAY(SELECT 'OLD.'||quote_ident(column_name::text) from information_schema.columns WHERE table_name = tablename AND table_schema = tableschema ORDER BY ordinal_position),',');
      SELECT INTO columns_new array_to_string(ARRAY(SELECT 'NEW.'||quote_ident(column_name::text) from information_schema.columns WHERE table_name = tablename AND table_schema = tableschema ORDER BY ordinal_position),',');

      fundef = $f$CREATE OR REPLACE FUNCTION log.$f$ || quote_ident( procname ) || $f$() RETURNS TRIGGER AS $i$
        DECLARE
          new_transaction BOOLEAN;
	  current_person_id INTEGER;
        BEGIN
          BEGIN
            -- postgresql 8.1 and 8.2
            new_transaction := current_setting('pentabarf.transaction_id') IN ('unset','');
          EXCEPTION WHEN undefined_object THEN
            -- postgresql 8.3
            new_transaction := TRUE;
          END;
          IF new_transaction THEN
            PERFORM set_config('pentabarf.transaction_id',nextval('base.log_transaction_log_transaction_id_seq')::TEXT,TRUE);
            BEGIN
              -- postgresql 8.1 and 8.2
              current_person_id := CASE current_setting('pentabarf.person_id') WHEN '' THEN NULL WHEN 'unset' THEN NULL ELSE current_setting('pentabarf.person_id')::INTEGER END;
            EXCEPTION WHEN undefined_object THEN
              -- postgresql 8.3
              current_person_id := NULL;
            END;
            INSERT INTO log.log_transaction( log_transaction_id, person_id )
              VALUES ( currval('base.log_transaction_log_transaction_id_seq'), current_person_id );
          END IF;
          INSERT INTO log.log_transaction_involved_tables( log_transaction_id, table_name )
              VALUES ( currval('base.log_transaction_log_transaction_id_seq'), $f$ || quote_literal(tablename) || $f$);
          IF ( TG_OP = 'DELETE' ) THEN
            INSERT INTO log.$f$ || quote_ident( tablename ) || $f$(log_transaction_id,log_operation,$f$ || columns || $f$) SELECT currval('base.log_transaction_log_transaction_id_seq'), 'D', $f$ || columns_old || $f$;
            RETURN OLD;
          ELSE
            INSERT INTO log.$f$ || quote_ident( tablename ) || $f$(log_transaction_id,log_operation,$f$ || columns || $f$) SELECT currval('base.log_transaction_log_transaction_id_seq'), substring( TG_OP, 1, 1 ), $f$ || columns_new || $f$;
            RETURN NEW;
          END IF;
          RETURN NULL;
        END;
      $i$ LANGUAGE plpgsql;$f$;
      EXECUTE fundef;

      trigname = tablename || '_log_trigger';
      -- enable function as trigger if it is not yet enabled
      IF ( NOT EXISTS( SELECT 1 FROM information_schema.triggers WHERE trigger_name = trigname AND event_object_schema = tableschema AND event_object_table = tablename ) ) THEN
        RAISE NOTICE 'Creating trigger for table %', tablename;
        trigdef = $t$CREATE TRIGGER $t$ || quote_ident( trigname ) || $t$ AFTER INSERT OR UPDATE OR DELETE ON $t$ || quote_ident( tableschema ) || '.' || quote_ident( tablename ) || $t$ FOR EACH ROW EXECUTE PROCEDURE log.$t$ || quote_ident( procname ) || $t$();$t$;
        EXECUTE trigdef;
      END IF;
    END LOOP;

  END;
$$ LANGUAGE plpgsql;
