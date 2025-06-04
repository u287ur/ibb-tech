from django.contrib.auth.hashers import make_password

password = 'admin123'
hashed_password = make_password(password)

print(hashed_password)

