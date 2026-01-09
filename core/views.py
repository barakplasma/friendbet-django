from django.shortcuts import render, redirect
from django.contrib.auth import logout, login
from django.contrib.auth.decorators import login_required
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.views import LoginView
from django.urls import reverse_lazy
from django.utils.translation import gettext_lazy as _
from django import forms


class CustomUserCreationForm(UserCreationForm):
    def __init__(self, *args, **kwargs):
        from core.models import User
        super().__init__(*args, **kwargs)
        self._meta.model = User


class CustomLoginView(LoginView):
    template_name = 'registration/login.html'
    redirect_authenticated_user = True


def signup_view(request):
    if request.method == 'POST':
        form = CustomUserCreationForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            return redirect('dashboard')
    else:
        form = CustomUserCreationForm()
    return render(request, 'registration/signup.html', {'form': form})


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
