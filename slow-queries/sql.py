import time
import zipfile
import os.path
import os
import psycopg2

DB_USERNAME='law-dev-02'
DB_HOSTNAME='law-dev-02.caltesting.org'
DB_NAME='law-dev-02'
PGPASSFILE='/home/bpeddada/.pgpass'

def hack_pgpass():
    """
    This is needed because the pgpass is not interpreted
    """
    f = open(PGPASSFILE)
    dbpass = None
    for x in f.readlines():
        fields =  x.split(':')
        if fields[0] == DB_HOSTNAME:
            if fields[2] == DB_NAME:
                dbpass = fields[4]
    return dbpass

def conn():
    dbconn = psycopg2.connect("dbname=%s host=%s port=5432 user=%s password=%s sslmode=prefer" % (
            DB_NAME,
            DB_HOSTNAME,
            DB_USERNAME,
            hack_pgpass()))
    return dbconn

c = conn()
cur = c.cursor()

seen = {
    ' select 1 ' :1
}
#import sqlparse
#from sqlparse.sql import IdentifierList, Identifier
#from sqlparse.tokens import Keyword, DML

import yaml

cost = {}
def run_query(x):
    print "check",x
    if x.lower().startswith(" select") or x.lower().startswith(" update"):
        if "$" in x:
            return

        if x in seen:
            seen[x]=seen[x]+1
            return 
        seen[x]=1

        #print "QUERY '%s'" % x
        query = "EXPLAIN (COSTS true, FORMAT YAML) " + x 
        cur.execute(query)
        yml = ''
        for a in cur :
            for y in a:
                yml = yml + y
        #print yml
        d= yaml.load(yml)
        for a in d:
            cost[x]=a['Plan']['Total Cost']
#    else:
        #print "Skip", x

        #[{'Plan': {'Startup Cost': 9607.77, 'Plan Width': 0, 'Plans': [{'Relation Name': 'upload_errors', 'Startup Cost': 0.0, 'Node Type': 'Seq Scan', 'Plan Rows': 98, 'Filter': '(file_id = 17)', 'Alias': 'uploaderro0_', 'Parent Relationship': 'Outer', 'Plan Width': 0, 'Total Cost': 9607.53}], 'Total Cost': 9607.78, 'Strategy': 'Plain', 'Node Type': 'Aggregate', 'Plan Rows': 1}}]
def report():
    for x in seen:

        c = seen[x]
        if x in cost:
            cst = cost[x]
        else:
            cst = "unknown"
        x = x.replace("\n","")
        print "\t".join(["$%s$" % x,"%s" % c, "%s" % cst])
            
import atexit
atexit.register(report)
