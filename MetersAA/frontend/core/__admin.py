from django.contrib import admin
from import_export.admin import ImportExportMixin

# Register your models here.

from .models import DeviceId, Computer, Subnet, ScanResult 

class DeviceIdAdmin(ImportExportMixin, admin.ModelAdmin):
    list_display = ['deviceid_ori', 'deviceid_termid']

class ComputerAdmin(ImportExportMixin, admin.ModelAdmin):
    list_display = ['computer_name']

class SubnetAdmin(ImportExportMixin, admin.ModelAdmin):
    list_display = ['subnet_address']
    
class SubnetAdmin(ImportExportMixin, admin.ModelAdmin):
    list_display = ['subnet_address']
    
class ScanResultAdmin(ImportExportMixin, admin.ModelAdmin):
    list_display = ['scanresult_subnet_id']
    
admin.site.register(DeviceId, DeviceIdAdmin)
admin.site.register(Computer, ComputerAdmin)
admin.site.register(Subnet, SubnetAdmin)
admin.site.register(ScanResult, ScanResultAdmin)
