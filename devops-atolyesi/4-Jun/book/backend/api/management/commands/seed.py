from django.core.management.base import BaseCommand
from django.contrib.auth.models import Group, Permission
from django.contrib.contenttypes.models import ContentType
from django.utils.timezone import now
from django.contrib.auth import get_user_model
from rest_framework.authtoken.models import Token

from api.models import Book, Loan, Student, Librarian
from datetime import timedelta

User = get_user_model()

class Command(BaseCommand):
    help = "Seed initial users, groups, and sample data only if they do not exist."

    def handle(self, *args, **kwargs):
        def create_group_with_permissions(name, model_perms):
            group, _ = Group.objects.get_or_create(name=name)
            for model, perms in model_perms.items():
                content_type = ContentType.objects.get_for_model(model)
                for codename in perms:
                    perm = Permission.objects.get(content_type=content_type, codename=codename)
                    group.permissions.add(perm)
            return group

        # ✅ Groups
        admin_group = create_group_with_permissions("admin", {
            Book: ["add_book", "change_book", "delete_book", "view_book"],
            Loan: ["add_loan", "change_loan", "delete_loan", "view_loan"],
            Student: ["add_student", "change_student", "delete_student", "view_student"],
        })

        librarian_group = create_group_with_permissions("librarian", {
            Book: ["add_book", "change_book", "delete_book", "view_book"],
            Loan: ["add_loan", "change_loan", "delete_loan", "view_loan"],
            Student: ["add_student", "change_student", "view_student"],
        })

        student_group = create_group_with_permissions("student", {
            Book: ["view_book"],
            Loan: ["view_loan"],
        })

        def create_user(email, password, first, last, role="student", is_staff=False, is_superuser=False):
            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    "first_name": first,
                    "last_name": last,
                    "role": role or "student",
                    "is_active": True,
                    "is_staff": is_staff,
                    "is_superuser": is_superuser,
                },
            )
            if created:
                user.set_password(password)
                user.save()
                self.stdout.write(f"✅ Created user: {email}")
            if role == "librarian":
                Librarian.objects.get_or_create(user=user, defaults={"name": f"{first} {last}", "employee_number": "EMP999"})
                user.groups.add(librarian_group)
            elif role == "student":
                Student.objects.get_or_create(user=user, defaults={"name": f"{first} {last}", "student_number": "STU999"})
                user.groups.add(student_group)
            elif is_superuser:
                user.groups.add(admin_group)
            Token.objects.get_or_create(user=user)
            return user

        # ✅ Core users
        create_user("admin@admin.com", "admin123", "Admin", "User", role="admin", is_superuser=True, is_staff=True)
        create_user("student@test.com", "student123", "Test", "Student", role="student")
        create_user("librarian@test.com", "librarian123", "Test", "Librarian", role="librarian", is_staff=True)

        # ✅ Sample users
        sample_users = [
            ("john@lib.com", "John", "Doe", "librarian", "EMP001"),
            ("jane@lib.com", "Jane", "Smith", "librarian", "EMP002"),
            ("alice@lib.com", "Alice", "Johnson", "librarian", "EMP003"),
            ("michael@stu.com", "Michael", "Brown", "student", "STU001"),
            ("emily@stu.com", "Emily", "Davis", "student", "STU002"),
            ("david@stu.com", "David", "Wilson", "student", "STU003"),
        ]

        for email, first, last, role, number in sample_users:
            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    "first_name": first,
                    "last_name": last,
                    "role": role,
                    "is_active": True
                }
            )
            if created:
                user.set_password("123456")
                user.save()
                self.stdout.write(f"✅ Created sample user: {email}")
                if role == "librarian":
                    Librarian.objects.get_or_create(user=user, defaults={"name": f"{first} {last}", "employee_number": number})
                    user.groups.add(librarian_group)
                elif role == "student":
                    Student.objects.get_or_create(user=user, defaults={"name": f"{first} {last}", "student_number": number})
                    user.groups.add(student_group)
                Token.objects.get_or_create(user=user)

        # ✅ Books
        books = [
            ("The Great Gatsby", "F. Scott Fitzgerald", True),
            ("To Kill a Mockingbird", "Harper Lee", True),
            ("1984", "George Orwell", False),
            ("Pride and Prejudice", "Jane Austen", True),
            ("The Catcher in the Rye", "J.D. Salinger", True),
        ]
        for title, author, available in books:
            book, created = Book.objects.get_or_create(
                title=title,
                author=author,
                defaults={"is_available": available}
            )
            if created:
                self.stdout.write(f"📚 Book added: {title}")

        # ✅ Loans
        if Loan.objects.count() == 0:
            students = list(Student.objects.all())
            books = list(Book.objects.all())
            if len(students) >= 3 and len(books) >= 5:
                loan_data = [
                    (students[0], books[2]),
                    (students[1], books[0]),
                    (students[2], books[1]),
                    (students[0], books[1]),
                    (students[1], books[2]),
                    (students[2], books[3]),
                    (students[0], books[4]),
                ]
                for student, book in loan_data:
                    Loan.objects.create(
                        student=student,
                        book=book,
                        loan_date=now().date(),
                        return_date=now().date() + timedelta(days=14),
                        is_returned=False
                    )
                self.stdout.write("📦 Sample loans added.")
            else:
                self.stdout.write("⚠️ Not enough students or books to create sample loans.")

        self.stdout.write(self.style.SUCCESS("🎉 Seed completed successfully with tokens and group assignments."))
