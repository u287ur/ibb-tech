from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.utils.translation import gettext_lazy as _
from django.utils import timezone

# Custom user manager to handle email-based login and superuser creation
class CustomUserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("Email must be set")
        email = self.normalize_email(email)
        extra_fields.setdefault("is_active", True)

        # Set a default username if not provided
        if not extra_fields.get("username"):
            extra_fields["username"] = email.split('@')[0]

        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("role", "admin")

        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")

        # Superuser için de username ayarlanmalı
        if not extra_fields.get("username"):
            extra_fields["username"] = email.split('@')[0]

        return self.create_user(email, password, **extra_fields)

# Custom user model that supports roles and uses email as the username
class User(AbstractUser):
    class Role(models.TextChoices):
        ADMIN = "admin", "Admin"
        LIBRARIAN = "librarian", "Librarian"
        STUDENT = "student", "Student"

    username = models.CharField(max_length=150, blank=True, null=True, unique=True)
    email = models.EmailField(unique=True)
    role = models.CharField(max_length=10, choices=Role.choices)
    first_name = models.CharField(max_length=150)
    last_name = models.CharField(max_length=150)

    USERNAME_FIELD = "email"  # Login will be based on email
    REQUIRED_FIELDS = []      # No additional required fields

    objects = CustomUserManager()

    def __str__(self):
        return self.email

class Librarian(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    employee_number = models.CharField(max_length=20, unique=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

class Student(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    student_number = models.CharField(max_length=20, unique=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

class Book(models.Model):
    title = models.CharField(max_length=200)
    author = models.CharField(max_length=100)
    is_available = models.BooleanField(default=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title

class Loan(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE)
    book = models.ForeignKey(Book, on_delete=models.CASCADE)
    loan_date = models.DateField()
    return_date = models.DateField(null=True, blank=True)
    is_returned = models.BooleanField(default=False)
    actual_return_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.book.title} - {self.student.name}"
