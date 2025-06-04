# backend/api/forms.py
from django import forms
from django.contrib.auth.forms import UserChangeForm
from .models import User

class CustomUserChangeForm(UserChangeForm):
    class Meta:
        model = User
        fields = '__all__'

    def clean_username(self):
        value = self.cleaned_data.get("username")
        if value is None:
            return ""
        return value
