from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Student, Book, Loan, Librarian

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('id', 'email', 'password', 'role')
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        print("Creating user with data:", validated_data)  # Debug log
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user

class StudentSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    email = serializers.EmailField(write_only=True)
    password = serializers.CharField(write_only=True)

    class Meta:
        model = Student
        fields = (
            'id',
            'user',
            'email',
            'password',
            'name',
            'student_number',
            'created_at',
            'updated_at',
        )

    def create(self, validated_data):
        print("Creating student with data:", validated_data)  # Debug log
        try:
            email = validated_data.pop('email')
            password = validated_data.pop('password')

            user = User.objects.create_user(
                email=email,
                password=password,
                role='student'
            )
            print(f"User created successfully: {user}")  # Debug log

            student = Student.objects.create(
                user=user,
                **validated_data
            )
            print(f"Student profile created successfully: {student}")  # Debug log
            return student
        except Exception as e:
            print(f"Error in student creation: {str(e)}")  # Debug log
            raise

class BookSerializer(serializers.ModelSerializer):
    class Meta:
        model = Book
        fields = '__all__'

class LoanSerializer(serializers.ModelSerializer):
    student_name = serializers.CharField(source='student.name', read_only=True)
    book_title = serializers.CharField(source='book.title', read_only=True)

    class Meta:
        model = Loan
        fields = '__all__'

class LibrarianSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    email = serializers.EmailField(write_only=True)
    password = serializers.CharField(write_only=True)

    class Meta:
        model = Librarian
        fields = (
            'id',
            'user',
            'email',
            'password',
            'name',
            'employee_number',
            'created_at',
            'updated_at',
        )

    def create(self, validated_data):
        email = validated_data.pop('email')
        password = validated_data.pop('password')

        user = User.objects.create_user(
            email=email,
            password=password,
            role='admin'
        )
        librarian = Librarian.objects.create(user=user, **validated_data)
        return librarian
