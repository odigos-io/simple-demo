# Stage 1: Build Stage
FROM python:3.11 AS builder

# Set environment variables for Python and prevent writing .pyc files
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Create and set the working directory
WORKDIR /app

# Copy only the poetry files to the working directory
COPY poetry.lock pyproject.toml README.md /app/

COPY inventory/ /app/inventory

# Install Poetry with specific version to avoid compatibility issues
RUN pip install poetry==1.7.1

# Configure Poetry and install dependencies with increased timeout
RUN poetry config virtualenvs.create false \
    && poetry config installer.max-workers 1 \
    && poetry install --no-interaction --no-ansi

# Stage 2: Runtime Stage
FROM python:3.11-slim

# Set environment variables for Python and prevent writing .pyc files
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install runtime dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Create and set the working directory
WORKDIR /app

# Copy only the necessary files from the builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/
COPY --from=builder /app /app

# Expose the port that the application will run on
EXPOSE 8080

# Set correct PYTHONPATH
ENV PYTHONPATH=/app

# Command to run the application
CMD ["python", "inventory/main.py"]
