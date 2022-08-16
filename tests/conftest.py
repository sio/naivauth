import psycopg2
import pytest

import os
import random
import string
from pathlib import Path


PG_DATABASE_PREFIX = 'naivauth_test_'


PG_CONNECTION = dict(
    user = os.getenv('PG_USER', 'postgres'),
    password = os.getenv('PG_PASSWORD', 'postgres'),
    host = os.getenv('PG_HOST', '127.0.0.1'),
    port = os.getenv('PG_PORT', '5432'),
)
SCHEMA_DIRECTORY = Path('schema/')


@pytest.fixture
def database(postgres):
    with postgres:
        with postgres.cursor() as cursor:
            for sql in sorted(SCHEMA_DIRECTORY.glob('*.sql')):
                with sql.open() as f:
                    cursor.execute(f.read())
    yield postgres


@pytest.fixture
def postgres(temp_database):
    '''Create empty postgres database'''
    dbname = _new_test_db(**PG_CONNECTION)
    connection = psycopg2.connect(**PG_CONNECTION, dbname=dbname)
    yield connection
    if connection:
        connection.close()


@pytest.fixture(scope='session')
def temp_database():
    '''Clean up test databases (once after all tests)'''
    yield
    _remove_test_dbs(**PG_CONNECTION)


def _find_test_dbs(**params):
    connection = psycopg2.connect(**params)
    with connection:
        existing = set()
        with connection.cursor() as cursor:
            query = 'SELECT datname FROM pg_database WHERE datname LIKE %s AND NOT datistemplate;'
            cursor.execute(query, [f'{PG_DATABASE_PREFIX}%'])
            for database in cursor:
                existing.add(database[0])
    return existing


def _remove_test_dbs(**params):
    existing = _find_test_dbs(**params)
    connection = psycopg2.connect(**params)
    connection.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
    try:
        with connection.cursor() as cursor:
            for db in existing:
                print(f'Removing database: {db}')
                cursor.execute(f'DROP DATABASE IF EXISTS {db};')  # proper quotes are not accepted
    finally:
        if connection:
            connection.close()


def _new_test_db(**params):
    existing = _find_test_dbs(**params)
    db = None
    while db is None or db in existing:
        db = f'{PG_DATABASE_PREFIX}{random_string().lower()}'
    connection = psycopg2.connect(**params)
    connection.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
    try:
        with connection.cursor() as cursor:
            print(f'Creating database: {db}')
            cursor.execute(f'CREATE DATABASE {db};')  # proper quotes are not accepted
    finally:
        if connection:
            connection.close()
    return db


def random_string(length=7):
    return ''.join(random.choice(string.ascii_lowercase + string.ascii_uppercase + string.digits)
                   for _ in range(length))
