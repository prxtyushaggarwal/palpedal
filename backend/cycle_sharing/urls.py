"""
URL Configuration for cycle_sharing project.
"""
from django.contrib import admin
from django.urls import path, include
from django.shortcuts import render

def home_demo(request):
    return render(request, 'web_demo.html')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('core.urls')),
    path('', home_demo, name='home_demo'),
]
