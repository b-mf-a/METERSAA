from datetime import timedelta, datetime, date
from django import template

register = template.Library()

@register.filter()
def cleandatetime(strdatetime):
	date_input = strdatetime
	datetimeobject = datetime.strptime(date_input,'%Y%m%d-%H%M-%S')
	new_format = datetimeobject.strftime('%B %d, %Y @ %I:%M %p')
	return new_format
