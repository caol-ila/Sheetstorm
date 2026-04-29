#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Download pending PDFs from the OMR Test Suite corpus
.DESCRIPTION
    Reads manifest.json and downloads all PDFs with status="pending_download"
    Updates manifest.json with download status and file sizes
.PARAMETER Force
    Re-download even if file already exists
.EXAMPLE
    .\download_corpus.ps1
    .\download_corpus.ps1 -Force
#>

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $scriptDir "manifest.json"

if (-not (Test-Path $manifestPath)) {
    Write-Error "manifest.json not found at $manifestPath"
    exit 1
}

Write-Host "OMR Test Suite Corpus Downloader"
Write-Host "=================================="
Write-Host ""

# Load manifest
$manifest = Get-Content $manifestPath | ConvertFrom-Json

# Filter pending downloads
$pendingDownloads = @($manifest | Where-Object { $_.status -eq "pending_download" })
Write-Host "Found $($pendingDownloads.Count) pending downloads"
Write-Host ""

$successCount = 0
$failureCount = 0

foreach ($item in $pendingDownloads) {
    $filename = $item.filename
    $filepath = Join-Path $scriptDir $filename
    $url = $item.source
    
    # Skip if already exists and not Force
    if ((Test-Path $filepath) -and -not $Force) {
        Write-Host "✓ $filename (already exists)"
        continue
    }
    
    Write-Host "Downloading: $filename"
    Write-Host "  URL: $url"
    
    try {
        # Download with robust error handling
        $params = @{
            Uri = $url
            OutFile = $filepath
            TimeoutSec = 30
            UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            ErrorAction = "Stop"
        }
        
        Invoke-WebRequest @params
        
        if (Test-Path $filepath) {
            $size = (Get-Item $filepath).Length
            
            if ($size -gt 50000) {
                Write-Host "  ✓ Downloaded ($size bytes)"
                
                # Update manifest
                $item.status = "downloaded"
                $item.file_size_bytes = $size
                $item.download_date = (Get-Date).ToString("yyyy-MM-dd")
                
                $successCount++
            } else {
                Write-Host "  ⚠ File too small ($size bytes) - likely error page"
                Write-Host "     Removing corrupted file..."
                Remove-Item $filepath -Force
                $failureCount++
            }
        } else {
            Write-Host "  ✗ File not written"
            $failureCount++
        }
    } catch {
        Write-Host "  ✗ Error: $($_.Exception.Message)"
        $failureCount++
        
        # Remove partial download
        if (Test-Path $filepath) {
            Remove-Item $filepath -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host ""
Write-Host "Summary"
Write-Host "======="
Write-Host "  Successful: $successCount"
Write-Host "  Failed: $failureCount"
Write-Host ""

# Save updated manifest
$manifest | ConvertTo-Json -Depth 10 | Set-Content $manifestPath
Write-Host "Updated manifest.json"

# Show corpus status
Write-Host ""
Write-Host "Corpus Status:"
Write-Host "=============="
$downloaded = @($manifest | Where-Object { $_.status -eq "downloaded" }).Count
$pending = @($manifest | Where-Object { $_.status -eq "pending_download" }).Count
Write-Host "  Downloaded: $downloaded / $($manifest.Count)"
Write-Host "  Pending: $pending / $($manifest.Count)"

if ($pending -eq 0) {
    Write-Host ""
    Write-Host "✓ All PDFs downloaded successfully!"
} else {
    Write-Host ""
    Write-Host "⏳ $pending PDFs still pending. Re-run this script to retry."
}
