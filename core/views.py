from django.shortcuts import render, redirect
from django.contrib.auth import logout
from django.contrib.auth.decorators import login_required
from django.utils.translation import gettext_lazy as _


def login_view(request):
    from django.conf import settings
    return render(request, 'login.html', {
        'google_oauth2_key': settings.SOCIAL_AUTH_GOOGLE_OAUTH2_KEY,
        'github_key': settings.SOCIAL_AUTH_GITHUB_KEY,
    })


def logout_view(request):
    logout(request)
    return redirect('login')


@login_required
def dashboard(request):
    return render(request, 'dashboard.html')


def set_language(request, lang_code):
    from django.utils.translation import activate
    from django.http import HttpResponseRedirect
    from django.urls import reverse

    if lang_code in ['en', 'he']:
        activate(lang_code)
        if request.user.is_authenticated:
            request.user.preferred_language = lang_code
            request.user.save()

    return HttpResponseRedirect(request.META.get('HTTP_REFERER', reverse('dashboard')))
