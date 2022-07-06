import datetime

from django.db import models
from django.utils import timezone
            
class Subnet(models.Model):
    id = models.IntegerField(primary_key=True)
    subnet_address = models.CharField(
                        max_length=15,
                        unique=True,
                        )

    def __str__(self):
        return self.subnet_address

class DeviceId(models.Model):
    id = models.IntegerField(primary_key=True)
    deviceid_ori = models.CharField(max_length=9)
    deviceid_termid = models.CharField(
                        blank=False,
                        max_length=4,
                        unique=True,
                        )

    def __str__(self):
        return self.deviceid_termid
        
class Computer(models.Model):
    id = models.IntegerField(primary_key=True)
    computer_name = models.CharField(
                        blank=False,
                        max_length=128,
                        unique=True,
                        )
                        
    def __str__(self):
        return self.computer_name
        
class ScanResult(models.Model):
    id = models.IntegerField(primary_key=True)
    scanresult_computer_id = models.ForeignKey(
                                Computer, 
                                on_delete=models.DO_NOTHING,
                                null=False,
                                blank=False,
                                db_index=False,
                                )
    scanresult_filedesktoppresent = models.BooleanField(
                                        blank=False,
                                        null=False,
                                        )
    scanresult_filecurrentpresent = models.BooleanField(
                                        blank=False,
                                        null=False,
                                        )
    scanresult_subnet_id = models.ForeignKey(
                                Subnet, 
                                on_delete=models.DO_NOTHING,
                                null=False,
                                blank=False,
                                db_index=False,
                                )
    scanresult_deviceid_id = models.ForeignKey(
                                DeviceId, 
                                on_delete=models.DO_NOTHING,
                                null=True,
                                blank=True,
                                db_index=False,
                                )
    #scanresult_datetime = models.DateTimeField('date scanned')
    scanresult_datetime = models.TextField('date scanned')
