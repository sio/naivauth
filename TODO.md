# TODO list

## SQL

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
