# ---------- STAGE 1: Build image ----------
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libmariadb-dev \
    default-libmysqlclient-dev \
    build-essential \
    pkg-config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python dependencies in virtualenv
COPY requirements.txt .
RUN python -m venv /venv && \
    . /venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ---------- STAGE 2: Runtime image ----------
FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/venv/bin:$PATH"

WORKDIR /app

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    libmariadb-dev \
    netcat-traditional \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy virtualenv from builder
COPY --from=builder /venv /venv

# Copy application code
COPY . .

# Set permissions and entrypoint
RUN chmod +x entrypoint.sh

CMD ["./entrypoint.sh"]
