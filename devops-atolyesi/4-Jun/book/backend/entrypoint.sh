#!/bin/bash
set -e

echo "🔎 ENV DUMP:"
env

echo "⏳ Waiting for the database to be ready at $DB_HOST:$DB_PORT ..."
until nc -z "$DB_HOST" "$DB_PORT"; do
  echo "🔁 Waiting for DB..."
  sleep 2
done
echo "✅ Port is reachable. Giving DB 3 seconds more to stabilize..."
sleep 3

echo "🚀 Running migrations..."
python manage.py migrate --noinput || {
  echo "⚠️ Migration failed. Retrying with --fake-initial..."
  python manage.py migrate --fake-initial
}

echo "📋 Showing migrations for api app..."
python manage.py showmigrations api

# Run seed only if Book table is empty
BOOK_COUNT=$(python manage.py shell -c 'from api.models import Book; print(Book.objects.count())' 2>/dev/null || echo "ERROR")

if [ "$BOOK_COUNT" = "0" ]; then
  echo "🌱 Seeding initial data..."
  python manage.py seed
elif [ "$BOOK_COUNT" = "ERROR" ]; then
  echo "❌ Book check failed. Possible migration or import error."
  exit 1
else
  echo "ℹ️ Seed skipped. Book table already has data."
fi

echo "📦 Starting Django server..."
exec python manage.py runserver 0.0.0.0:8000
