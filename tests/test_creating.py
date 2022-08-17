import pytest

from .conftest import apply_schema

def test_applying_schema(database):
    '''Check if schema applies cleanly'''
    with database:
        with database.cursor() as cursor:
            cursor.execute('''SELECT * FROM pg_tables WHERE tablename = 'session' ''')
            result = cursor.fetchone()
            assert result


def test_schema_idempotence(database):
    '''Schema should be idempotent'''
    for _ in range(3):
        apply_schema(database)
