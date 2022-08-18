# TODO list

## SQL

- Add stored procedure to extend session lifetime
- Store schema version somewhere
- Add key:value table for misc constants
- Write tests for schema constraints
    - Token length
    - Active session must have username assigned
    - Token must be unique among active/activating
    - Token may be repeated among invalid sessions
- Write tests for stored procedures/functions
    - get_username (happy path, error/null)
    - get_token (new token, repeat old token)
    - activate
    - deactivate
    - collect_garbage


## Security

- Review <https://www.authelia.com/overview/security/measures/>
- Encrypt username, use cookie+fingerprint as salt? Same for token?
  Would this be enough to stop an attacker with access to database from
  stealing a session (renaming existing session to another user, stealing
  token and adding it to attacker's session instead)
