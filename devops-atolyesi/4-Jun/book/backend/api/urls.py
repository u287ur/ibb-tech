from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    StudentViewSet,
    BookViewSet,
    LoanViewSet,
    LibrarianViewSet,
    login_view,
    health_check,
    logout_view
)


router = DefaultRouter()
router.register(r'students', StudentViewSet)
router.register(r'books', BookViewSet)
router.register(r'loans', LoanViewSet, basename='loan')
router.register(r'librarians', LibrarianViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('auth/login/', login_view, name='login'),
    path('auth/logout/', logout_view, name='logout'),
    path('health/', health_check, name='health-check'),

]
