FROM python:3.10-slim

WORKDIR /app

# Install UV for dependency management
RUN pip install --no-cache-dir uv

# Create and activate virtual environment
RUN python -m venv venv
ENV PATH="/app/venv/bin:$PATH"

# Copy and install dependencies
COPY requirements.txt .
RUN uv pip install --no-cache -r requirements.txt

# Copy application code
COPY . .

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
