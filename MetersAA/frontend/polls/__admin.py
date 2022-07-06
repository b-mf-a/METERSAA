from django.contrib import admin
from import_export.admin import ImportExportMixin

# Register your models here.

from .models import Question

class QuestionAdmin(ImportExportMixin, admin.ModelAdmin):
    list_display = ['question_text', 'pub_date']
    
admin.site.register(Question, QuestionAdmin)
