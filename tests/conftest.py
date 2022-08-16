import psycopg2
import pytest

import os


PG_DATABASE_PREFIX = 'naivauth_test_'


PG_CONNECTION = dict(
    user = os.getenv('PG_USER', 'postgres'),
    password = os.getenv('PG_PASSWORD', 'postgres'),
    host = os.getenv('PG_HOST', '127.0.0.1'),
    port = os.getenv('PG_PORT', '5432'),
)


@pytest.fixture
def postgres():
    connection = psycopg2.connect(**PG_CONNECTION)
    pass


def remove_test_databases(connection)
    with connection:
        existing = []
        with connection.cursor() as cursor:
            query = 'SELECT datname FROM pg_database WHERE datname LIKE ? AND NOT datistemplate'
            cursor.execute(query, [f'{PG_DATABASE_PREFIX}%'])
            for database in cursor:
                existing.append(cursor['datname'])
    print(existing)
