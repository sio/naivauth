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


CREATE EXTENSION pgcrypto;  /* get_random_uuid() */


CREATE OR REPLACE random_int(low int, high int) RETURNS int AS $$
    BEGIN
        RETURN floor(random() * (high - low + 1) + low);
    END;
$$ LANGUAGE plpgsql STRICT;


CREATE TABLE session (
    fingerprint bytea NOT NULL,
    cookie      uuid PRIMARY KEY DEFAULT get_random_uuid(),
    token       int DEFAULT random_int(100000, 999999),
    active      boolean NOT NULL DEFAULT false,
    user        text,
    created_at  timestamp with time zone DEFAULT now() NOT NULL,
    expires_at  timestamp with time zone DEFAULT now() + interval '15m' NOT NULL,
    trash       uuid UNIQUE, /* NULL for non-trash, copy cookie otherwise */

    CONSTRAINT token_unique_among_active UNIQUE(token, trash),
    CONSTRAINT token_length CHECK (token > 100000)
);


CREATE INDEX cookie_lookup ON session USING HASH (cookie);
CREATE INDEX fingerprint_lookup ON session USING HASH (fingerprint);
CREATE INDEX token_lookup ON session USING HASH (token);
