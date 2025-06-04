from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.decorators import action, api_view, permission_classes
from django.contrib.auth import authenticate, login, logout
from django.utils import timezone
from .models import Student, Book, Loan, Librarian
from .serializers import (
    StudentSerializer,
    BookSerializer,
    LoanSerializer,
    LibrarianSerializer,
    UserSerializer
)
from rest_framework.authtoken.models import Token
@api_view(['GET'])
def health_check(request):
    return Response({"status": "ok"})
# ------------------------------
# Login Endpoint (Public)
# ------------------------------
@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def login_view(request):
    email = request.data.get('email')
    password = request.data.get('password')
    print(f"Login attempt with email: {email}")

    # 'username=email' kullanılır çünkü USERNAME_FIELD = 'email'
    user = authenticate(request, username=email, password=password)
    print(f"Authentication result: {'Success' if user else 'Failed'}")

    if user is not None:
        login(request, user)
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user_id': user.pk,
            'email': user.email,
            'role': user.role
        })
    else:
        return Response(
            {"error": "Invalid credentials"},
            status=status.HTTP_400_BAD_REQUEST
        )

# ------------------------------
# Logout Endpoint (Authenticated Users)
# ------------------------------
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def logout_view(request):
    if hasattr(request.user, 'auth_token'):
        request.user.auth_token.delete()
    logout(request)
    return Response({"message": "Successfully logged out."})

# ------------------------------
# Role-based Custom Permissions
# ------------------------------
class IsAdminUser(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.role == 'admin'

class IsStudentUser(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.role == 'student'

# ------------------------------
# Librarian ViewSet (Admins only)
# ------------------------------
class LibrarianViewSet(viewsets.ModelViewSet):
    queryset = Librarian.objects.all()
    serializer_class = LibrarianSerializer
    permission_classes = [IsAdminUser]

# ------------------------------
# Student ViewSet
# - Anyone can register (create)
# - Admins can list/update/delete
# ------------------------------
class StudentViewSet(viewsets.ModelViewSet):
    queryset = Student.objects.all()
    serializer_class = StudentSerializer

    def get_permissions(self):
        if self.action == 'create':
            permission_classes = [permissions.AllowAny]
        else:
            permission_classes = [IsAdminUser]
        return [permission() for permission in permission_classes]

    def create(self, request, *args, **kwargs):
        print("Received student registration data:", request.data)
        try:
            serializer = self.get_serializer(data=request.data)
            if serializer.is_valid():
                print("Serializer is valid. Validated data:", serializer.validated_data)
                student = serializer.save()
                print(f"Student created successfully: {student}")
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            else:
                print("Serializer validation errors:", serializer.errors)
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            print(f"Error creating student: {str(e)}")
            return Response(
                {"error": "An error occurred during registration. Please try again."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

# ------------------------------
# Book ViewSet
# - Admins can manage books
# - Others can only view
# ------------------------------
class BookViewSet(viewsets.ModelViewSet):
    queryset = Book.objects.all()
    serializer_class = BookSerializer

    def get_permissions(self):
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [IsAdminUser]
        else:
            permission_classes = [permissions.IsAuthenticated]
        return [permission() for permission in permission_classes]

# ------------------------------
# Loan ViewSet (borrow and return books)
# ------------------------------
class LoanViewSet(viewsets.ModelViewSet):
    queryset = Loan.objects.all()
    serializer_class = LoanSerializer

    def get_permissions(self):
        if self.action == 'create':
            permission_classes = [IsStudentUser]
        elif self.action in ['update', 'partial_update', 'destroy']:
            permission_classes = [IsAdminUser]
        else:
            permission_classes = [permissions.IsAuthenticated]
        return [permission() for permission in permission_classes]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'student':
            return Loan.objects.filter(student__user=user)
        return Loan.objects.all()

    def create(self, request, *args, **kwargs):
        try:
            student = Student.objects.get(user=request.user)
            book_id = request.data.get('book_id')
            book = Book.objects.get(id=book_id)

            if not book.is_available:
                return Response(
                    {"error": "This book is currently not available."},
                    status=status.HTTP_400_BAD_REQUEST
                )

            loan_data = {
                'student': student.id,
                'book': book_id,
                'loan_date': request.data.get('loan_date', timezone.now().date()),
                'return_date': None,
                'is_returned': False
            }

            serializer = self.get_serializer(data=loan_data)
            serializer.is_valid(raise_exception=True)
            self.perform_create(serializer)

            book.is_available = False
            book.save()

            return Response(serializer.data, status=status.HTTP_201_CREATED)
        except Student.DoesNotExist:
            return Response(
                {"error": "Student profile not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        except Book.DoesNotExist:
            return Response(
                {"error": "Book not found."},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def return_book(self, request, pk=None):
        loan = self.get_object()
        if not loan.is_returned:
            loan.is_returned = True
            loan.actual_return_date = timezone.now().date()
            loan.book.is_available = True
            loan.book.save()
            loan.save()
        return Response({'status': 'Book returned successfully'})
@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def register_student(request):
    try:
        user_data = {
            'email': request.data.get('email'),
            'password': request.data.get('password'),
            'first_name': request.data.get('first_name'),
            'last_name': request.data.get('last_name'),
            'role': 'student'
        }

        # User kaydı
        user_serializer = UserSerializer(data=user_data)
        user_serializer.is_valid(raise_exception=True)
        user = user_serializer.save()
        user.set_password(user_data['password'])  # şifreyi hashle
        user.save()

        # Student kaydı
        student_data = {
            'user': user.id,
            'name': request.data.get('name'),
            'student_number': request.data.get('student_number'),
            'email': request.data.get('email')
        }

        student_serializer = StudentSerializer(data=student_data)
        student_serializer.is_valid(raise_exception=True)
        student_serializer.save()

        return Response({"message": "Kayıt başarılı"}, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
