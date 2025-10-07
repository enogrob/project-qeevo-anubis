#!/bin/bash

# Enhanced PDF Export Script with Mermaid & Image Support
set -e

INPUT_FILE="$1"
if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <markdown-file>"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "File not found: $INPUT_FILE"
    exit 1
fi

# Use absolute paths
INPUT_FILE=$(realpath "$INPUT_FILE")
OUTPUT_FILE="${INPUT_FILE%.*}.pdf"

echo "Processing: $INPUT_FILE -> $OUTPUT_FILE"

# Get directory
INPUT_DIR=$(dirname "$INPUT_FILE")
FILENAME=$(basename "$INPUT_FILE" .md)

# Create a temporary directory structure for HTTP serving
TEMP_DIR="/tmp/pdf_export_$$"
mkdir -p "$TEMP_DIR"
TEMP_HTML="$TEMP_DIR/index.html"

# Copy assets to temp directory to make them accessible via HTTP
if [ -d "$INPUT_DIR/assets" ]; then
    echo "📁 Copying assets for HTTP serving..."
    cp -r "$INPUT_DIR/assets" "$TEMP_DIR/"
fi

# Also check for images in other common locations
for img_dir in "images" "img" "."; do
    if [ -d "$INPUT_DIR/$img_dir" ] && [ "$img_dir" != "." ]; then
        cp -r "$INPUT_DIR/$img_dir" "$TEMP_DIR/" 2>/dev/null || true
    fi
done

# Create HTML with Mermaid support
cat > "$TEMP_HTML" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Documentation</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10.6.1/dist/mermaid.min.js"></script>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 40px; }
        h1, h2, h3 { color: #333; }
        pre { background: #f4f4f4; padding: 10px; border-radius: 5px; }
        img { max-width: 100%; height: auto; }
        .mermaid { text-align: center; margin: 20px 0; }
    </style>
</head>
<body>
HTMLEOF

# Process markdown to fix image paths and convert to HTML
cd "$INPUT_DIR"
PROCESSED_MD="/tmp/processed_$$.md"

# Fix image paths to be HTTP-accessible
cp "$(basename "$INPUT_FILE")" "$PROCESSED_MD"

# Fix markdown image syntax ![alt](path) - use relative paths for HTTP server
sed -i "s|!\[\([^]]*\)\](\([^)]*\))|![\1](\2)|g" "$PROCESSED_MD"

# Fix HTML img src attributes - use relative paths for HTTP server  
sed -i "s|src=\"\([^\"]*\)\"|src=\"\1\"|g" "$PROCESSED_MD"

# Convert processed markdown to HTML
TEMP_BODY="/tmp/temp_body_$$.html"
pandoc "$PROCESSED_MD" --from markdown --to html5 > "$TEMP_BODY"

# Process HTML to fix Mermaid code blocks
sed -i 's/<pre class="mermaid"><code>/<div class="mermaid">/g' "$TEMP_BODY"
sed -i 's/<\/code><\/pre>/<\/div>/g' "$TEMP_BODY"

# Also handle cases where mermaid is inside a code element
sed -i 's/<code class="language-mermaid">/<div class="mermaid">/g' "$TEMP_BODY"

# Append processed HTML body
cat "$TEMP_BODY" >> "$TEMP_HTML"

# Clean up temporary files
rm -f "$PROCESSED_MD" "$TEMP_BODY"

# Close HTML with enhanced Mermaid initialization
cat >> "$TEMP_HTML" << 'HTMLEOF'
<script>
// Enhanced Mermaid configuration for PDF generation
mermaid.initialize({
    startOnLoad: false,
    theme: 'default',
    securityLevel: 'loose',
    htmlLabels: true,
    flowchart: {
        useMaxWidth: true,
        htmlLabels: true,
        curve: 'cardinal'
    },
    sequence: {
        diagramMarginX: 50,
        diagramMarginY: 10,
        actorMargin: 50,
        width: 150,
        height: 65,
        boxMargin: 10,
        boxTextMargin: 5,
        noteMargin: 10,
        messageMargin: 35,
        mirrorActors: true,
        bottomMarginAdj: 1,
        useMaxWidth: true
    }
});

// Wait for DOM and render Mermaid diagrams with better error handling
let renderingComplete = false;
let renderingAttempts = 0;
const maxAttempts = 10;

function attemptMermaidRender() {
    renderingAttempts++;
    console.log('Attempting Mermaid render, attempt:', renderingAttempts);
    
    if (renderingAttempts > maxAttempts) {
        console.error('Max render attempts reached');
        document.body.setAttribute('data-mermaid-ready', 'failed');
        return;
    }
    
    try {
        mermaid.run().then(() => {
            console.log('Mermaid diagrams rendered successfully');
            renderingComplete = true;
            document.body.setAttribute('data-mermaid-ready', 'true');
            
            // Add visual indicator for successful rendering
            const style = document.createElement('style');
            style.textContent = '.mermaid { border: 2px solid green; }';
            document.head.appendChild(style);
        }).catch(err => {
            console.error('Mermaid rendering error:', err);
            setTimeout(attemptMermaidRender, 500);
        });
    } catch (err) {
        console.error('Mermaid initialization error:', err);
        setTimeout(attemptMermaidRender, 500);
    }
}

document.addEventListener('DOMContentLoaded', function() {
    console.log('DOM loaded, waiting for Mermaid library...');
    
    // Wait for Mermaid library to be fully loaded
    const checkMermaidReady = () => {
        if (typeof mermaid !== 'undefined' && mermaid.initialize) {
            console.log('Mermaid library loaded, starting render...');
            setTimeout(attemptMermaidRender, 1000);
        } else {
            console.log('Waiting for Mermaid library...');
            setTimeout(checkMermaidReady, 200);
        }
    };
    
    checkMermaidReady();
});

// Fallback: Force completion after maximum wait time
setTimeout(() => {
    if (!renderingComplete) {
        console.warn('Forcing completion after timeout');
        document.body.setAttribute('data-mermaid-ready', 'timeout');
    }
}, 15000);
</script>
</body>
</html>
HTMLEOF

# Find Chrome
CHROME=""
for cmd in google-chrome-stable google-chrome chromium chromium-browser; do
    if command -v $cmd >/dev/null 2>&1; then
        CHROME="$cmd"
        break
    fi
done

if [ -z "$CHROME" ]; then
    echo "Chrome/Chromium not found"
    exit 1
fi

# Generate PDF with enhanced settings for Mermaid rendering
echo "Generating PDF with $CHROME..."
echo "Starting temporary HTTP server for better resource loading..."



# Start a temporary HTTP server
TEMP_PORT=9876
HTTP_PID=""

# Function to start HTTP server
start_http_server() {
    cd "$TEMP_DIR"
    python3 -m http.server $TEMP_PORT >/dev/null 2>&1 &
    HTTP_PID=$!
    sleep 2  # Give server time to start
    echo "HTTP server started on port $TEMP_PORT (PID: $HTTP_PID)"
}

# Function to stop HTTP server and cleanup
stop_http_server() {
    if [ ! -z "$HTTP_PID" ]; then
        kill $HTTP_PID 2>/dev/null || true
        echo "HTTP server stopped"
    fi
    # Clean up temp directory unless in DEBUG mode
    if [ "$DEBUG" != "1" ]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
}

# Start HTTP server
start_http_server

# Use HTTP URL instead of file URL for better resource loading
HTTP_URL="http://localhost:$TEMP_PORT/index.html"

echo "Generating PDF from: $HTTP_URL"
echo "Waiting for Mermaid diagrams to render..."

# Try PDF generation with HTTP server
$CHROME \
    --headless \
    --disable-gpu \
    --no-sandbox \
    --disable-setuid-sandbox \
    --disable-dev-shm-usage \
    --disable-background-timer-throttling \
    --disable-renderer-backgrounding \
    --disable-features=TranslateUI \
    --run-all-compositor-stages-before-draw \
    --disable-ipc-flooding-protection \
    --disable-web-security \
    --virtual-time-budget=120000 \
    --timeout=180000 \
    --print-to-pdf="$OUTPUT_FILE" \
    --print-to-pdf-no-header \
    --window-size=1200,800 \
    "$HTTP_URL"

# Stop HTTP server
stop_http_server

# Check if PDF was generated successfully
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "HTTP approach failed, falling back to file:// approach..."
    
    $CHROME \
        --headless \
        --disable-gpu \
        --no-sandbox \
        --disable-setuid-sandbox \
        --disable-dev-shm-usage \
        --disable-background-timer-throttling \
        --disable-renderer-backgrounding \
        --disable-features=TranslateUI \
        --run-all-compositor-stages-before-draw \
        --disable-ipc-flooding-protection \
        --allow-file-access-from-files \
        --disable-web-security \
        --virtual-time-budget=120000 \
        --timeout=180000 \
        --print-to-pdf="$OUTPUT_FILE" \
        --print-to-pdf-no-header \
        --window-size=1200,800 \
        "file://$TEMP_HTML"
fi

# Try Puppeteer approach if available and Chrome approach failed or produced small file
PDF_SIZE=0
if [ -f "$OUTPUT_FILE" ]; then
    PDF_SIZE=$(stat -c%s "$OUTPUT_FILE" 2>/dev/null || stat -f%z "$OUTPUT_FILE" 2>/dev/null || echo 0)
fi

# Check if we should try Puppeteer (if PDF is small or doesn't exist, and Node.js is available)
if [ $PDF_SIZE -lt 500000 ] && [ -f "pdf-generator.js" ] && command -v node >/dev/null 2>&1; then
    echo ""
    echo "🔄 Chrome PDF seems small (${PDF_SIZE} bytes), trying Puppeteer approach..."
    
    # Remove the small PDF if it exists
    [ -f "$OUTPUT_FILE" ] && rm "$OUTPUT_FILE"
    
    # Start HTTP server for Puppeteer
    start_http_server
    
    # Try Puppeteer with HTTP URL
    if node pdf-generator.js "$HTTP_URL" "$OUTPUT_FILE"; then
        echo "✅ Puppeteer approach successful!"
    else
        echo "⚠️  Puppeteer approach failed, keeping Chrome result"
        # Regenerate with Chrome if Puppeteer failed
        if [ ! -f "$OUTPUT_FILE" ]; then
            echo "🔄 Regenerating with Chrome..."
            $CHROME \
                --headless \
                --disable-gpu \
                --no-sandbox \
                --disable-setuid-sandbox \
                --disable-dev-shm-usage \
                --allow-file-access-from-files \
                --disable-web-security \
                --virtual-time-budget=60000 \
                --print-to-pdf="$OUTPUT_FILE" \
                --print-to-pdf-no-header \
                --window-size=1200,800 \
                "$HTTP_URL"
        fi
    fi
    
    # Stop HTTP server after Puppeteer
    stop_http_server
fi

# Check if DEBUG mode is enabled
if [ "$DEBUG" = "1" ]; then
    echo "DEBUG: Temporary HTML file preserved at: $TEMP_HTML"
    echo "DEBUG: You can open it in a browser to verify rendering"
else
    # Cleanup temp directory
    rm -rf "$TEMP_DIR" 2>/dev/null || true
fi

if [ -f "$OUTPUT_FILE" ]; then
    FINAL_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo ""
    echo "✅ PDF generated successfully: $OUTPUT_FILE"
    echo "📊 File size: $FINAL_SIZE"
    echo ""
    echo "💡 Tips:"
    echo "  • For debugging: DEBUG=1 $0 $1"
    echo "  • To install better PDF support: npm install (for Puppeteer)"
else
    echo "❌ PDF generation failed"
    exit 1
fi
