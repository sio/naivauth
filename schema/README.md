# Database schema for naivauth

Since naivauth operates on rather simple data structures we try to delegate
most of data validation and data generation logic to database engine instead
of implementing it in database clients.
This makes it easier to write the apps (auth backend, frontend and
authenicated channel listener).

This schema is written for PostgreSQL, cross-engine support is not tested
and should not be assumed.
