/*
 * Postgres extensions and pure functions
 * which do not require any tables to exist beforehand
 */


CREATE EXTENSION IF NOT EXISTS pgcrypto;  /* get_random_uuid() */


CREATE OR REPLACE FUNCTION random_int(low int, high int) RETURNS int AS $$
    BEGIN
        RETURN floor(random() * (high - low + 1) + low);
    END;
$$ LANGUAGE plpgsql STRICT;
