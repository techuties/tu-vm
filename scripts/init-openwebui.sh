#!/bin/bash

# Open WebUI initialization script with TikaLoader fix
# This script ensures TikaLoader is used for PDFs from initial installation

echo "🔧 Applying TikaLoader fix for PDF processing..."

# Apply the TikaLoader fix
python3 -c "
import re

# Read the loader file
with open('/app/backend/open_webui/retrieval/loaders/main.py', 'r') as f:
    content = f.read()

# Check if already patched
if 'Force TikaLoader for PDFs' in content:
    print('✅ TikaLoader fix already applied')
    exit(0)

# Find the PyPDFLoader section and replace it
old_line = '                loader = PyPDFLoader(\n                    file_path, extract_images=self.kwargs.get(\"PDF_EXTRACT_IMAGES\")\n                )'

new_code = '''                # Force TikaLoader for PDFs to avoid reshape errors
                if self.kwargs.get(\"TIKA_SERVER_URL\"):
                    loader = TikaLoader(
                        url=self.kwargs.get(\"TIKA_SERVER_URL\"),
                        file_path=file_path,
                        mime_type=file_content_type,
                        extract_images=self.kwargs.get(\"PDF_EXTRACT_IMAGES\"),
                    )
                else:
                    loader = PyPDFLoader(
                        file_path, extract_images=self.kwargs.get(\"PDF_EXTRACT_IMAGES\")
                    )'''

# Apply the fix
if old_line in content:
    new_content = content.replace(old_line, new_code)
    
    # Write the fixed file
    with open('/app/backend/open_webui/retrieval/loaders/main.py', 'w') as f:
        f.write(new_content)
    
    print('✅ TikaLoader fix applied successfully')
else:
    print('❌ Could not find PyPDFLoader section to patch')
    exit(1)
"

echo "🚀 Starting Open WebUI with TikaLoader fix..."
exec "$@"
