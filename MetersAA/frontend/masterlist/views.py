from django.core.serializers import serialize
from django.shortcuts import render, get_object_or_404
from django.http import HttpResponse, Http404
from django.template import loader

# Create your views here.

#from .models import Question

from .sqlqueries import SqlQueries
from .models import Location, Subnet

def index(request):
#   latest_question_list = Question.objects.order_by('-pub_date')[:5]
    #output = ', '.join([q.question_text for q in latest_question_list])
    #template = loader.get_template('polls/index.html')
#   context = {
#       'latest_question_list': latest_question_list,
#   }
#   return render(request, 'polls/index.html', context)
    #return HttpResponse(template.render(context, request))
    #return HttpResponse(output)
    #return HttpResponse("Hello, world. You're at the polls index.")
    scanresults = SqlQueries.get_last_seen_of_all_masterlist_deviceids()
    #locations = Location.objects.all()
    locations = SqlQueries.get_locations()
    return render(request, 'masterlist/index.html', {'scanresults': scanresults, 'locations': locations})

def termid(request, termid):
    scanresults = SqlQueries.get_last_xtimes_seen_of_deviceid(termid)
    deviceidinfo = SqlQueries.get_deviceid_info(termid)
    return render(request, 'masterlist/deviceid.html', {'scanresults': scanresults, 'deviceidinfo': deviceidinfo})
    
def subnets(request):
    qs = Subnet.objects.all()
    data = serialize("json", qs, fields=('subnet_address'))
    return HttpResponse(data, content_type="application/json")
