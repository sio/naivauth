import pytest

def test_applying_schema(database):
    '''Check if schema applies cleanly'''
    with database:
        with database.cursor() as cursor:
            cursor.execute('''SELECT * FROM pg_tables WHERE tablename = 'session' ''')
            result = cursor.fetchone()
            assert result
