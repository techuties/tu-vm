FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the processor scripts
COPY tika_processor.py .
COPY auto_processor.py .

# Set permissions
RUN chmod +x tika_processor.py auto_processor.py

# Default command
CMD ["python", "auto_processor.py"]
