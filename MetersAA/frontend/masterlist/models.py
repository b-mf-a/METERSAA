import datetime

from django.db import models
from django.utils import timezone
            
class Location(models.Model):
    location_name = models.CharField(
                        max_length=200,
                        verbose_name="Name",
                        )
    location_phone = models.CharField(
                        blank=True,
                        max_length=15,
                        verbose_name="Phone",
                        )
    location_physicaladdress = models.CharField(
                        blank=True,
                        max_length=200,
                        verbose_name="Street Address",
                        )
    
    def __str__(self):
        return self.location_name
    
class Section(models.Model):
    section_name = models.CharField(
                        max_length=200,
                        verbose_name="Name",
                        )
    section_location_id = models.ForeignKey(
                        Location, 
                        on_delete=models.DO_NOTHING,
                        verbose_name="Location",
                        )
    section_location_floor = models.CharField(
                                blank=True,
                                max_length=20,
                                verbose_name="Floor",
                                )
    section_location_room = models.CharField(
                                blank=True,
                                max_length=20,
                                verbose_name="Room",
                                )

    def __str__(self):
        return self.section_name
            
class Subnet(models.Model):
    subnet_address = models.CharField(
                        max_length=15,
                        verbose_name="IP address",
                        )
    subnet_location_id = models.ForeignKey(
                        Location,
                        on_delete=models.DO_NOTHING,
                        verbose_name="Location",)

    def __str__(self):
        return self.subnet_address

class DeviceId(models.Model):
    deviceid_ori = models.CharField(
                        max_length=9,
                        verbose_name="ORI",
                        )
    deviceid_termid = models.CharField(
                        blank=False,
                        max_length=4,
                        unique=True,
                        verbose_name="Term ID",
                        )
    deviceid_location_id = models.ForeignKey(
                                Location, 
                                on_delete=models.DO_NOTHING,
                                null=True,
                                blank=True,
                                verbose_name="Location",
                                )
    deviceid_section_id = models.ForeignKey(
                                Section, 
                                on_delete=models.DO_NOTHING,
                                null=True,
                                blank=True,
                                verbose_name="Section",
                                )
    deviceid_registered_date = models.DateTimeField('Date registered')
    deviceid_active = models.BooleanField(
                                default=True,
                                null=False,
                                blank=False,
                                verbose_name="Active",
                            )
    deviceid_note = models.TextField(
                                null=True,
                                blank=True,
                                verbose_name="Note",
                            )

    def __str__(self):
        return self.deviceid_termid
