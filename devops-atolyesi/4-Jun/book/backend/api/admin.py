from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, Librarian, Student, Book, Loan
from .forms import CustomUserChangeForm

# Custom User Admin
class CustomUserAdmin(BaseUserAdmin):
    model = User
    form = CustomUserChangeForm
    list_display = ('email', 'first_name', 'last_name', 'role', 'is_staff', 'is_active')
    list_filter = ('role', 'is_active', 'is_staff')
    search_fields = ('email', 'first_name', 'last_name')
    ordering = ('email',)
    fieldsets = (
        (None, {'fields': ('email', 'password', 'role')}),
        ('Personal info', {'fields': ('first_name', 'last_name')}),
        ('Permissions', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Important dates', {'fields': ('last_login', 'date_joined')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'password1', 'password2', 'role', 'first_name', 'last_name', 'is_staff', 'is_active')}
        ),
    )

# Librarian Admin
class LibrarianAdmin(admin.ModelAdmin):
    list_display = ('name', 'employee_number', 'user')
    search_fields = ('name', 'employee_number')

# Student Admin
class StudentAdmin(admin.ModelAdmin):
    list_display = ('name', 'student_number', 'user')
    search_fields = ('name', 'student_number')

# Book Admin
class BookAdmin(admin.ModelAdmin):
    list_display = ('title', 'author', 'is_available')
    search_fields = ('title', 'author')

# Loan Admin
class LoanAdmin(admin.ModelAdmin):
    list_display = ('book', 'student', 'loan_date', 'return_date', 'is_returned', 'actual_return_date')
    list_filter = ('is_returned',)
    search_fields = ('book__title', 'student__name')

# Register models
admin.site.register(User, CustomUserAdmin)
admin.site.register(Librarian, LibrarianAdmin)
admin.site.register(Student, StudentAdmin)
admin.site.register(Book, BookAdmin)
admin.site.register(Loan, LoanAdmin)
