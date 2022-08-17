import psycopg2
import pytest

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
QUERY_DELIMITER = '\n---\n'
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
            with query_file.open() as fd:
                for q in fd.read().split(QUERY_DELIMITER):
                    if not q.strip():  # drop empty queries
                        continue
                    execute(q)

    def query_setup(self, query):
        '''Setup query have no assertions, they just have not to crash anything'''
        with get_cursor(self.db) as cursor:
            cursor.execute(query)

    def query_empty(self, query):
        '''Each query must return empty result'''
        with get_cursor(self.db) as cursor:
            cursor.execute(query)
            for result in cursor:
                raise AssertionError(f'non-empty result, first row: {result}')

    def query_oneline(self, query):
        '''Each query must return only one result'''
        with get_cursor(self.db) as cursor:
            cursor.execute(query)
            results = cursor.fetchmany(2)
            assert len(results) == 1

    def query_multiline(self, query):
        '''Each query must return at least two results'''
        with get_cursor(self.db) as cursor:
            cursor.execute(query)
            results = cursor.fetchmany(2)
            assert len(results) == 2

    def query_error(self, query):
        '''Each query must raise an error'''
        with get_cursor(self.db) as cursor:
            with pytest.raises(psycopg2.DatabaseError):
                cursor.execute(query)
