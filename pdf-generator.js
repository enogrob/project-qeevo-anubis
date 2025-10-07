#!/usr/bin/env node

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

async function generatePDF(htmlFilePath, outputPath) {
    console.log('🚀 Starting Puppeteer PDF generation...');
    
    const browser = await puppeteer.launch({
        headless: 'new',
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-gpu',
            '--no-first-run',
            '--disable-extensions',
            '--disable-background-timer-throttling',
            '--disable-renderer-backgrounding',
            '--disable-features=TranslateUI'
        ]
    });

    try {
        const page = await browser.newPage();
        
        // Set a larger viewport for better rendering
        await page.setViewport({ width: 1200, height: 800 });
        
        // Enable console logging from the page
        page.on('console', msg => {
            console.log('🌐 Page log:', msg.text());
        });
        
        // Load the HTML file or URL
        if (htmlFilePath.startsWith('http')) {
            console.log('📡 Loading from URL:', htmlFilePath);
            await page.goto(htmlFilePath, { 
                waitUntil: 'networkidle0',
                timeout: 60000 
            });
        } else {
            console.log('📄 Loading from file:', htmlFilePath);
            const htmlContent = fs.readFileSync(htmlFilePath, 'utf8');
            await page.setContent(htmlContent, { 
                waitUntil: 'networkidle0',
                timeout: 60000 
            });
        }
        
        console.log('📄 HTML content loaded, waiting for Mermaid...');
        
        // Wait for Mermaid to be ready
        try {
            await page.waitForFunction(
                () => document.body.getAttribute('data-mermaid-ready') !== null,
                { timeout: 30000 }
            );
            
            const mermaidStatus = await page.evaluate(() => 
                document.body.getAttribute('data-mermaid-ready')
            );
            
            console.log('🎨 Mermaid status:', mermaidStatus);
        } catch (error) {
            console.warn('⚠️  Mermaid readiness timeout, proceeding anyway...');
        }
        
        // Add a small delay to ensure all rendering is complete
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        // Generate PDF
        console.log('📄 Generating PDF...');
        await page.pdf({
            path: outputPath,
            format: 'A4',
            margin: {
                top: '20mm',
                right: '20mm',
                bottom: '20mm',
                left: '20mm'
            },
            printBackground: true,
            preferCSSPageSize: false
        });
        
        console.log(`✅ PDF generated successfully: ${outputPath}`);
        
        // Get file size
        const stats = fs.statSync(outputPath);
        console.log(`📊 File size: ${Math.round(stats.size / 1024)}K`);
        
    } catch (error) {
        console.error('❌ Error generating PDF:', error);
        process.exit(1);
    } finally {
        await browser.close();
    }
}

// Get command line arguments
const args = process.argv.slice(2);
if (args.length !== 2) {
    console.error('Usage: node pdf-generator.js <input.html> <output.pdf>');
    process.exit(1);
}

const [htmlFile, outputFile] = args;

// Check if input file exists (skip check for URLs)
if (!htmlFile.startsWith('http') && !fs.existsSync(htmlFile)) {
    console.error(`❌ Input file not found: ${htmlFile}`);
    process.exit(1);
}

// Generate PDF
generatePDF(htmlFile, outputFile).catch(error => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
});