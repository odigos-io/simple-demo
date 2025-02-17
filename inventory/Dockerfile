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

# Install Poetry
RUN pip install poetry

# Install project dependencies
RUN poetry config virtualenvs.create false \
    && poetry install

# Stage 2: Runtime Stage
FROM python:3.11-slim

# Set environment variables for Python and prevent writing .pyc files
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Create and set the working directory
WORKDIR /app

# Copy only the necessary files from the builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/
COPY --from=builder /app /app

# Expose the port that the application will run on
EXPOSE 8080

ENV PYTHONPATH=/bar

# Command to run the application
CMD ["python", "main.py"]
