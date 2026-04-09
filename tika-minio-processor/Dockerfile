FROM python:3-alpine

# Install system dependencies
RUN apk add --no-cache curl

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the processor scripts
COPY tika_processor.py .
COPY auto_processor.py .
COPY universal_processor.py .
COPY universal_auto_processor.py .

# Set permissions
RUN chmod +x tika_processor.py auto_processor.py universal_processor.py universal_auto_processor.py

# Default command (use universal processor)
CMD ["python", "universal_auto_processor.py"]
