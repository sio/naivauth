/*
 * Database schema for naivauth
 *
 * Since naivauth operates on rather simple data structures we try to delegate
 * most of data validation and data generation logic to database engine instead
 * of implementing it in database clients.
 * This makes it easier to write the apps (auth backend, frontend and
 * authenicated channel listener).
 *
 * This schema is written for PostgreSQL, cross-engine support is not tested
 * and should not be assumed.
 */


CREATE EXTENSION IF NOT EXISTS pgcrypto;  /* get_random_uuid() */


CREATE OR REPLACE FUNCTION random_int(low int, high int) RETURNS int AS $$
    BEGIN
        RETURN floor(random() * (high - low + 1) + low);
    END;
$$ LANGUAGE plpgsql STRICT;


CREATE TABLE IF NOT EXISTS session (
    fingerprint bytea NOT NULL,
    cookie      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    token       int DEFAULT random_int(100000, 999999),
    active      boolean NOT NULL DEFAULT false,
    username    text,
    created_at  timestamp with time zone DEFAULT now() NOT NULL,
    expires_at  timestamp with time zone DEFAULT now() + interval '15m' NOT NULL,
    trash       uuid UNIQUE, /* NULL for non-trash, copy cookie otherwise */

    CONSTRAINT token_length CHECK (token > 100000),
    CONSTRAINT active_must_assign_user CHECK (NOT active OR (active AND (username IS NOT NULL)))
);


CREATE UNIQUE INDEX IF NOT EXISTS constraint_token_unique_among_active ON session (
    token,
    coalesce(trash, '00000000-0000-0000-0000-000000000000')
);


CREATE OR REPLACE VIEW active_session AS
    SELECT * FROM session
    WHERE
        active AND
        expires_at > now() AND
        trash IS NULL;
CREATE OR REPLACE VIEW activating_session AS
    SELECT * FROM session
    WHERE
        NOT active AND
        expires_at > now() AND
        trash IS NULL;
CREATE OR REPLACE VIEW valid_session AS
    SELECT * FROM session
    WHERE
        expires_at > now() AND
        trash IS NULL;


CREATE INDEX IF NOT EXISTS cookie_lookup ON session (cookie, fingerprint);
CREATE INDEX IF NOT EXISTS fingerprint_lookup ON session USING HASH (fingerprint);
CREATE INDEX IF NOT EXISTS token_lookup ON session USING HASH (token);


CREATE OR REPLACE FUNCTION get_username(fingerprint bytea, cookie uuid) RETURNS text AS $$
    SELECT username FROM active_session
    WHERE fingerprint = get_username.fingerprint AND cookie = get_username.cookie
$$ LANGUAGE sql STRICT;


CREATE OR REPLACE FUNCTION get_token(fingerprint bytea, OUT token int, OUT cookie uuid) AS $$
BEGIN
    /* Check if there already exists a token waiting to be activated */
    SELECT session.token, session.cookie FROM valid_session AS session
    WHERE session.fingerprint = get_token.fingerprint
    ORDER BY created_at DESC LIMIT 1
    INTO get_token.token, get_token.cookie;

    /* Create new token */
    IF NOT FOUND THEN
        INSERT INTO session (fingerprint) values (get_token.fingerprint);
        SELECT session.token, session.cookie FROM valid_session AS session
        WHERE session.fingerprint = get_token.fingerprint
        INTO get_token.token, get_token.cookie;
    END IF;
END;
$$ LANGUAGE plpgsql STRICT;


CREATE OR REPLACE PROCEDURE activate(token int, username text) AS $$
    UPDATE session
    SET
        active = true,
        username = activate.username
    WHERE
        session.token = activate.token AND
        session.expires_at > now() AND
        trash is NULL;
$$ LANGUAGE sql;


CREATE OR REPLACE PROCEDURE deactivate(cookie uuid) AS $$
    UPDATE session
    SET
        active = false,
        trash = cookie
    WHERE
        session.cookie = deactivate.cookie;
$$ LANGUAGE sql;
