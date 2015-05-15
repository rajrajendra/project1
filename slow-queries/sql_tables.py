import time
import zipfile
import os.path
import os
#import sqlparse
#from sqlparse.sql import IdentifierList, Identifier
#from sqlparse.tokens import Keyword, DML

seen = {
    ' select 1 ' :1
}


def is_subselect(parsed):
    if not parsed.is_group():
        return False
    for item in parsed.tokens:
        if item.ttype is DML and item.value.upper() == 'SELECT':
            return True
    return False


def extract_from_part(parsed):
    from_seen = False
    for item in parsed.tokens:

        if from_seen:
            if is_subselect(item):
                for x in extract_from_part(item):
                    yield x
            elif item.ttype is Keyword:
                #raise StopIteration
                pass
            else:
                yield item
        elif item.ttype is Keyword and item.value.upper() == 'FROM':
            from_seen = True


def extract_table_identifiers(token_stream):
    for item in token_stream:
        if isinstance(item, IdentifierList):
            for identifier in item.get_identifiers():
                #print "Check ID",dir(identifier)
                #Check ID ['__class__', '__delattr__', '__doc__', '__format__', '__getattribute__', '__hash__', '__init__', '__module__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__slots__', '__str__', '__subclasshook__', '__unicode__', '_get_first_name', '_get_repr_name', '_get_repr_value', '_groupable_tokens', '_pprint_tree', '_remove_quotes', '_to_string', 'flatten', 'get_alias', 'get_array_indices', 'get_name', 'get_ordering', 'get_parent_name', 'get_real_name', 'get_sublists', 'get_token_at_offset', 'get_typecast', 'group_tokens', 'has_alias', 'has_ancestor', 'insert_after', 'insert_before', 'is_child_of', 'is_group', 'is_keyword', 'is_whitespace', 'is_wildcard', 'match', 'normalized', 'parent', 'to_unicode', 'token_first', 'token_index', 'token_matching', 'token_next', 'token_next_by_instance', 'token_next_by_type', 'token_next_match', 'token_not_matching', 'token_prev', 'tokens', 'tokens_between', 'ttype', 'value', 'within']
                yield identifier

        elif isinstance(item, Identifier):
            yield item
        # It's a bug to check for Keyword here, but in the example
        # above some tables names are identified as keywords...
        elif item.ttype is Keyword:
            yield item.value


def extract_tables(sql):
    p = sqlparse.parse(sql)

    print "SQL", sql
    stream = extract_from_part(p[0])
    stream2 = []
    for x in stream :
        #print "member",x
        stream2.append(x)

    stream3 = []
    for t in extract_table_identifiers(stream2):
        #print "Table", t
        stream3.append(t)

    return stream3


tables = {}

def run_query(time,x):
    if x.lower().startswith(" select"):
        if x in seen:
            seen[x]=seen[x]+1
            return 
            #print x
        seen[x]=1
        t = extract_tables(x)
        for a in t:
            print "Found",a
            tables[a]=1


def report():
    for x in tables.keys():
        print x

