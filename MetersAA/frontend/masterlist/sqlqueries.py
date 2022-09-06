import datetime

from django.db import models, connection
from django.utils import timezone

from collections import namedtuple

from .models import Location

def namedtuplefetchall(cursor):
    "Return all rows from a cursor as a named tuple"
    desc = cursor.description
    nt_result = namedtuple('Result', [col[0] for col in desc])
    return [nt_result(*row) for row in cursor.fetchall()]
        
class SqlQueries():
    
    def get_last_seen_of_all_masterlist_deviceids():
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT w.id,w.location_name,w.deviceid_ori,w.deviceid_termid,w.deviceid_note,c.computer_name,wtshouldbe.subnet_address as wtsubnet_address,wtshouldbe.location_name as wtlocation_name,e.scanresult_datetime
                FROM (
                    SELECT t.id, t.deviceid_ori, t.deviceid_termid, t.location_name, t.deviceid_note, t.id
                    FROM (
                        SELECT z.deviceid_ori,z.deviceid_termid,z.deviceid_note,k.location_name,y.id,k.id
                        FROM masterlist_deviceid z
                        LEFT JOIN core_deviceid y ON z.deviceid_termid = y.deviceid_termid
                        JOIN masterlist_location k ON z.deviceid_location_id_id = k.id
                        WHERE z.deviceid_active = 1
                    ) t
                ) w
                LEFT JOIN (
                    SELECT p1.scanresult_computer_id_id,p1.scanresult_subnet_id_id,p1.scanresult_deviceid_id_id,p1.scanresult_datetime
                    FROM core_scanresult p1
                    INNER JOIN
                    (
                        SELECT max(scanresult_datetime) LatestResult, scanresult_deviceid_id_id
                        FROM core_scanresult
                        GROUP BY scanresult_deviceid_id_id
                    ) p2
                    ON p1.scanresult_deviceid_id_id = p2.scanresult_deviceid_id_id
                    AND p1.scanresult_datetime = p2.LatestResult
                ) e ON w.id = e.scanresult_deviceid_id_id
                LEFT JOIN core_computer c ON e.scanresult_computer_id_id = c.id
                LEFT JOIN (
                    SELECT ms.id,ms.subnet_address,cs.id AS cssi,ml.location_name,ml.id
                    FROM core_subnet cs
                    JOIN masterlist_subnet ms ON cs.subnet_address = ms.subnet_address
                    JOIN masterlist_location ml ON ms.subnet_location_id_id = ml.id
                ) wtshouldbe ON e.scanresult_subnet_id_id = wtshouldbe.cssi 
            """)
            
            #rows = cursor.fetchall()
            rows = namedtuplefetchall(cursor)
            
            return rows
        #return something
        
    def get_locations():
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT location_name, location_phone, location_physicaladdress
                FROM masterlist_location
            """)
        
            rows = cursor.fetchall()
            
            return rows

    def get_last_xtimes_seen_of_deviceid(termid):
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT cc.computer_name, mll.location_name AS 'at_location',mlltwo.location_name AS 'registered_location',cd.deviceid_termid,cd.deviceid_ori,mld.deviceid_termid AS 'registered_termid',mld.deviceid_ori AS 'registered_ori',p1.scanresult_datetime
                FROM core_scanresult p1
                JOIN core_subnet cs ON cs.id = p1.scanresult_subnet_id_id
                JOIN masterlist_subnet mls ON mls.subnet_address = cs.subnet_address
                JOIN masterlist_location mll ON mll.id = mls.subnet_location_id_id
                JOIN core_deviceid cd ON cd.id = p1.scanresult_deviceid_id_id
                JOIN masterlist_deviceid mld ON mld.deviceid_termid = cd.deviceid_termid
                JOIN masterlist_location mlltwo ON mlltwo.id = mld.deviceid_location_id_id
                JOIN core_computer cc ON cc.id = p1.scanresult_computer_id_id
                WHERE mld.deviceid_termid = '""" + str(termid) + """'
                ORDER BY p1.scanresult_datetime DESC
                LIMIT 200
            """)
            
            #rows = cursor.fetchall()
            rows = namedtuplefetchall(cursor)
            
            return rows
            
    def get_deviceid_info(termid):
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT mld.deviceid_ori,mld.deviceid_termid,tml.location_name,mld.deviceid_note
                FROM masterlist_deviceid mld
                JOIN masterlist_location tml ON mld.deviceid_location_id_id = tml.id
                WHERE mld.deviceid_termid = '""" + str(termid) + """'
            """)
        
            rows = namedtuplefetchall(cursor)
            
            return rows
