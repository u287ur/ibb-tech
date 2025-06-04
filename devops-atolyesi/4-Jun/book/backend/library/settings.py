import os
from pathlib import Path
# from decouple import config  # 🔒 Optional fallback

# 📁 Project base directory
BASE_DIR = Path(__file__).resolve().parent.parent

# 🔑 Secret key (keep this safe in production)
# SECRET_KEY = config('SECRET_KEY', default='unsafe-default')
SECRET_KEY = os.environ.get('SECRET_KEY', 'unsafe-default')

# 🐞 Debug mode (True = development, False = production)
# DEBUG = config('DEBUG', default=False, cast=bool)
DEBUG = os.environ.get('DEBUG', 'False') == 'True'
APPEND_SLASH = False
# 🌍 Allowed hosts
# ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='*').split(',')
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '*').split(',')

# 📦 Installed Django and third-party apps
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    'rest_framework',
    'rest_framework.authtoken',
    'corsheaders',

    'api',  # Your local app
]

# 🧱 Middleware stack
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # Must be first for CORS to work
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# 🔗 URL configuration
ROOT_URLCONF = 'library.urls'

# 🖼️ Template rendering settings
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# 🚀 WSGI application entry point
WSGI_APPLICATION = 'library.wsgi.application'

# 🛢️ Database configuration (MySQL)
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',

        # Database name
        # 'NAME': config('DB_NAME', default='library_db'),
        'NAME': os.environ.get('DB_NAME', 'library_db'),

        # Username
        # 'USER': config('DB_USER', default='library_user'),
        'USER': os.environ.get('DB_USER', 'library_user'),

        # Password
        # 'PASSWORD': config('DB_PASSWORD', default='library_pass'),
        'PASSWORD': os.environ.get('DB_PASSWORD', 'library_pass'),

        # Host (e.g., RDS endpoint or 'db' for Docker)
        # 'HOST': config('DB_HOST', default='db'),
        'HOST': os.environ.get('DB_HOST', 'db'),

        # Port
        # 'PORT': config('DB_PORT', default='3306'),
        'PORT': os.environ.get('DB_PORT', '3306'),

        # Extra MySQL options
        'OPTIONS': {
            'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
            'charset': 'utf8mb4',
        }
    }
}

# 👤 Custom user model
AUTH_USER_MODEL = 'api.User'

# 🔐 Password validation rules
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# 🌐 Localization
LANGUAGE_CODE = 'tr-tr'
TIME_ZONE = 'Europe/Istanbul'
USE_I18N = True
USE_TZ = True

# 📁 Static file URL
STATIC_URL = 'static/'

# 🔑 Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# 🔄 Django REST Framework settings
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ],
}

# 🌍 CORS allowed origins (standard ones from env)
CORS_ALLOWED_ORIGINS = os.environ.get(
    'CORS_ALLOWED_ORIGINS',
    'http://localhost:8080'
).split(',')

# ✅ Extra: Allow *.elb.amazonaws.com via regex
CORS_ALLOWED_ORIGIN_REGEXES = [
    r"^http:\/\/.*\.elb\.amazonaws\.com$"
]

CORS_ALLOWED_ORIGINS = os.environ.get(
    'CORS_ALLOWED_ORIGINS',
    'http://localhost:8080'
).split(',')

CSRF_TRUSTED_ORIGINS = os.environ.get(
    'CSRF_TRUSTED_ORIGINS',
    'http://localhost:8080'
).split(',')

CORS_ALLOW_CREDENTIALS = True