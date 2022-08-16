/*
 * Custom indexes
 */

CREATE INDEX IF NOT EXISTS cookie_lookup ON session (cookie, fingerprint);
CREATE INDEX IF NOT EXISTS fingerprint_lookup ON session USING HASH (fingerprint);
CREATE INDEX IF NOT EXISTS token_lookup ON session USING HASH (token);
