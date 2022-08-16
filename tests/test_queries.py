import psycopg2
import pytest
import sqlparse

from collections import defaultdict
from contextlib import contextmanager
from pathlib import Path

QUERY_TYPES = [  # order matters
    'setup',
    'empty',
    'oneline',
    'multiline',
    'error',
]
TEST_DIR = Path(__file__).parent


def queries():
    TEST_DIR = Path(__file__).parent
    tests = defaultdict(set)
    for sql in TEST_DIR.glob('*.*.sql'):
        test_case, query_type, extension = sql.name.split('.')
        if extension != 'sql':
            raise ValueError(f'unparsable filename: {sql}')
        if query_type not in QUERY_TYPES:
            raise ValueError(f'invalid query type: {query_type} ({sql})')
        tests[test_case].add(query_type)
    return tests


@contextmanager
def get_cursor(connection):
    with connection:
        with connection.cursor() as cur:
            yield cur


class TestQuery:
    @pytest.mark.parametrize("query", queries())
    def test_query(self, database, query):
        self.db = database
        assert self.db
        for query_type in QUERY_TYPES:
            query_file = TEST_DIR / f'{query}.{query_type}.sql'
            if not query_file.exists():
                continue
            execute = getattr(self, f'query_{query_type}')
            with query_file.open() as q:
                execute(sqlparse.split(q.read()))

    def query_setup(self, queries):
        '''Setup queries have no assertions, they just have not to crash anything'''
        with get_cursor(self.db) as cursor:
            for query in queries:
                cursor.execute(query)

    def query_empty(self, queries):
        '''Each query must return empty result'''
        with get_cursor(self.db) as cursor:
            for query in queries:
                cursor.execute(query)
                for result in cursor:
                    raise AssertionError(f'non-empty result, first row: {result}')

    def query_oneline(self, queries):
        '''Each query must return only one result'''
        with get_cursor(self.db) as cursor:
            for query in queries:
                cursor.execute(query)
                results = cursor.fetchmany(2)
                assert len(results) == 1

    def query_multiline(self, queries):
        '''Each query must return at least two results'''
        with get_cursor(self.db) as cursor:
            for query in queries:
                cursor.execute(query)
                results = cursor.fetchmany(2)
                assert len(results) == 2

    def query_error(self, queries):
        '''Each query must raise an error'''
        with get_cursor(self.db) as cursor:
            for query in queries:
                with pytest.raises(psycopg2.DatabaseError):
                    cursor.execute(query)
