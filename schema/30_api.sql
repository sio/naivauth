/*
 * Stored functions and procedures
 */


CREATE OR REPLACE FUNCTION get_username(fingerprint bytea, cookie uuid) RETURNS text AS $$
    SELECT username FROM active_session
    WHERE fingerprint = get_username.fingerprint AND cookie = get_username.cookie
$$ LANGUAGE sql STRICT;


/*
 * This function may raise an error upon token collision when randomly
 * generated new value matches another unused (not yet garbage collected) token
 */
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


/* This procedure needs to be called from time to time to return used tokens
 * back into available pool */
CREATE OR REPLACE PROCEDURE collect_garbage() AS $$
    UPDATE session
    SET
        active = false,
        trash = cookie
    WHERE
        expires_at < now() AND
        trash IS NULL;
$$ LANGUAGE sql;
