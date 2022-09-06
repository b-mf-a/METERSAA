from django.contrib import admin
from import_export.admin import ImportExportMixin

# Register your models here.

from .models import DeviceId, Location, Section, Subnet 

class DeviceIdAdmin(ImportExportMixin, admin.ModelAdmin):
    list_display = ['deviceid_ori', 'deviceid_termid', 'deviceid_note']

class LocationAdmin(ImportExportMixin, admin.ModelAdmin):
    list_display = ['location_name', 'location_phone', 'location_physicaladdress']
    
class SectionAdmin(ImportExportMixin, admin.ModelAdmin):
    list_display = ['section_name', 'section_location_floor', 'section_location_room']

class SubnetAdmin(ImportExportMixin, admin.ModelAdmin):
    list_display = ['subnet_address']
    
admin.site.register(DeviceId, DeviceIdAdmin)
admin.site.register(Location, LocationAdmin)
admin.site.register(Section, SectionAdmin)
admin.site.register(Subnet, SubnetAdmin)
