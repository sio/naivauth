/*
 * Tables and views
 */


CREATE TABLE IF NOT EXISTS session (
    fingerprint bytea NOT NULL,
    cookie      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    token       int NOT NULL DEFAULT random_int(100000, 999999),
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
