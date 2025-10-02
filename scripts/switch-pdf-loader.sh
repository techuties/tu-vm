#!/bin/bash
# PDF Processor Management Script
# Usage: ./switch-pdf-loader.sh [tika|pymupdf]

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 [tika|pymupdf]"
    echo ""
    echo "Current configuration:"
    docker exec -i ai_postgres psql -U ai_admin -d ai_platform -c "SELECT (data::jsonb -> 'rag' -> 'file' ->> 'pdf_loader') as current_loader FROM config WHERE id=1;"
    echo ""
    echo "Note: Tika is the recommended default for full document processing capabilities."
    exit 1
fi

LOADER=$1

case $LOADER in
    tika)
        echo "🔄 Switching to TikaLoader (recommended - full document processing)..."
        docker exec -i ai_postgres psql -U ai_admin -d ai_platform -c "
        UPDATE config SET data = jsonb_set(data::jsonb, '{rag,file,pdf_loader}', '\"TikaLoader\"'::jsonb) WHERE id=1;
        UPDATE config SET data = jsonb_set(data::jsonb, '{rag,file,pdf_extract_images}', 'true'::jsonb) WHERE id=1;
        UPDATE config SET data = jsonb_set(data::jsonb, '{TIKA_SERVER_URL}', '\"http://ai_tika:9998\"'::jsonb) WHERE id=1;
        "
        echo "✅ Switched to TikaLoader with full image processing enabled"
        ;;
    pymupdf)
        echo "🔄 Switching to PyMuPDFLoader (fast, text-only)..."
        docker exec -i ai_postgres psql -U ai_admin -d ai_platform -c "
        UPDATE config SET data = jsonb_set(data::jsonb, '{rag,file,pdf_loader}', '\"PyMuPDFLoader\"'::jsonb) WHERE id=1;
        UPDATE config SET data = jsonb_set(data::jsonb, '{rag,file,pdf_extract_images}', 'false'::jsonb) WHERE id=1;
        "
        echo "✅ Switched to PyMuPDFLoader (image extraction disabled)"
        ;;
    *)
        echo "❌ Invalid option. Use 'tika' or 'pymupdf'"
        echo "   tika     - Full document processing with OCR and image analysis"
        echo "   pymupdf  - Fast text extraction only"
        exit 1
        ;;
esac

echo "🔄 Restarting Open WebUI..."
docker compose restart open-webui

echo "✅ PDF processor switched successfully!"
echo "📋 Current configuration:"
docker exec -i ai_postgres psql -U ai_admin -d ai_platform -c "SELECT (data::jsonb -> 'rag' -> 'file' ->> 'pdf_loader') as current_loader FROM config WHERE id=1;"
