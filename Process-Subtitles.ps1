<#
.SYNOPSIS
    Video Course Transcript Organizer - Extract & Organize Course Transcripts
    
.DESCRIPTION
    This PowerShell script automatically processes video subtitle files (.vtt/.srt) 
    from course folders and converts them into clean, organized, searchable text files.
    
    Features:
    - Removes timestamps, metadata, and sequence numbers
    - Maintains folder structure and sequential order
    - Creates individual clean transcript files
    - Generates combined master file for searching
    - Handles special characters and various subtitle formats
    
.PARAMETER Path
    Optional. Specify the root path containing subtitle files. Defaults to script location.
    
.EXAMPLE
    .\Process-Subtitles.ps1
    Processes all subtitle files in the current directory
    
.EXAMPLE
    .\Process-Subtitles.ps1 -Path "C:\Courses\My-Course"
    Processes subtitle files in the specified directory
    
.NOTES
    Author: GitHub @devsgh-cloudsec
    Version: 1.0
    Created: 2025-07-27
    Repository: https://github.com/devsgh-cloudsec/video-course-transcript-organizer
    
    Requirements:
    - Windows PowerShell 5.1 or higher
    - Read/Write permissions in the target directory
    
.LINK
    https://github.com/devsgh-cloudsec/video-course-transcript-organizer
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Path
)

Clear-Host
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = "Stop"

# Function to sanitize filenames by removing problematic characters
function Get-SafeFileName {
    param([string]$fileName)
    return $fileName -replace '[^\w\-_\.\s]', '_' -replace '\s+', ' '
}

# Function to clean subtitle content by removing timestamps, metadata, and formatting
function Get-CleanSubtitleContent {
    param([string]$filePath)
    
    try {
        $content = Get-Content $filePath -Encoding UTF8 -ErrorAction Stop
        $cleanLines = @()
        
        foreach ($line in $content) {
            $trimmedLine = $line.Trim()
            
            # Skip lines that match subtitle formatting patterns
            if ($trimmedLine -match '^WEBVTT' -or              # WEBVTT header
                $trimmedLine -match '^NOTE' -or                # VTT NOTE lines
                $trimmedLine -match '^STYLE' -or               # VTT STYLE lines
                $trimmedLine -match '^\d{1,2}:\d{2}:\d{2}.*-->' -or  # Timestamps with arrows
                $trimmedLine -match '^\d+$' -or                # Sequence numbers (SRT)
                $trimmedLine -match '^$' -or                   # Empty lines
                $trimmedLine -match '^Kind:' -or               # VTT metadata
                $trimmedLine -match '^Language:' -or           # VTT metadata
                $trimmedLine -match '^\[.*\]$' -or             # Sound effects [music], [applause]
                $trimmedLine -match '^<.*>$') {                # HTML-like tags
                continue
            }
            
            # Add non-empty cleaned lines
            if ($trimmedLine -ne "") {
                $cleanLines += $trimmedLine
            }
        }
        
        return $cleanLines
    }
    catch {
        Write-Warning "Failed to read file: $filePath - $($_.Exception.Message)"
        return @()
    }
}

try {
    # Display header
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host "  Video Course Transcript Organizer v1.0" -ForegroundColor Magenta
    Write-Host "  Extract & Organize Course Transcripts" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Determine root path
    if ($Path) {
        $rootPath = $Path
        if (!(Test-Path $rootPath)) {
            throw "Specified path does not exist: $rootPath"
        }
    } else {
        $rootPath = $PSScriptRoot
        if (-not $rootPath) { 
            $rootPath = Get-Location | Select-Object -ExpandProperty Path 
        }
    }
    
    Write-Host "Root folder: $rootPath" -ForegroundColor Cyan
    
    # Create Subtitles output folder
    $outputFolder = Join-Path $rootPath "Subtitles"
    if (!(Test-Path -Path $outputFolder)) {
        New-Item -ItemType Directory -Path $outputFolder | Out-Null
        Write-Host "Created output folder: $outputFolder" -ForegroundColor Green
    } else {
        Write-Host "Using existing folder: $outputFolder" -ForegroundColor Yellow
    }
    
    # Find all subtitle files, excluding the output folder
    Write-Host "`nScanning for subtitle files..." -ForegroundColor Cyan
    $subtitleFiles = Get-ChildItem -Path $rootPath -Recurse -Include *.vtt, *.srt | Where-Object { 
        $_.DirectoryName -ne $outputFolder 
    }
    
    $totalFiles = $subtitleFiles.Count
    Write-Host "Found $totalFiles subtitle files to process" -ForegroundColor Yellow
    
    if ($totalFiles -eq 0) {
        Write-Host "`nWARNING: No subtitle files (.vtt or .srt) found!" -ForegroundColor Red
        Write-Host "Make sure you have subtitle files in the current directory or its subdirectories." -ForegroundColor Gray
        Write-Host "`nPress any key to exit..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    
    # Initialize tracking variables
    $processedFiles = @()
    $currentFile = 0
    $successCount = 0
    $warningCount = 0
    $errorCount = 0
    
    Write-Host "`nProcessing subtitle files..." -ForegroundColor Cyan
    Write-Host ("-" * 60) -ForegroundColor Gray
    
    # Process each subtitle file
    foreach ($file in $subtitleFiles) {
        $currentFile++
        $progress = [math]::Round(($currentFile / $totalFiles) * 100, 1)
        
        try {
            # Create safe filename for output
            $safeBaseName = Get-SafeFileName -fileName $file.BaseName
            $outputFile = Join-Path $outputFolder "$safeBaseName.txt"
            
            # Clean the subtitle content
            $cleanContent = Get-CleanSubtitleContent -filePath $file.FullName
            
            if ($cleanContent.Count -gt 0) {
                # Join lines with proper spacing and save
                $finalContent = $cleanContent -join "`r`n"
                $finalContent | Out-File -FilePath $outputFile -Encoding UTF8
                
                # Extract folder information for organization
                $relativePath = $file.FullName.Replace($rootPath, "").TrimStart('\')
                $folderName = Split-Path (Split-Path $relativePath -Parent) -Leaf
                if ([string]::IsNullOrEmpty($folderName)) {
                    $folderName = "Root"
                }
                
                # Track for combined file with folder structure
                $processedFiles += @{
                    Name = $safeBaseName
                    FileName = "$safeBaseName.txt"
                    Content = $cleanContent
                    OriginalPath = $file.FullName
                    FolderName = $folderName
                    RelativePath = $relativePath
                }
                
                Write-Host "[$progress" + "%] SUCCESS: $($file.Name) -> $safeBaseName.txt" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "[$progress" + "%] WARNING: $($file.Name) -> No content after cleaning" -ForegroundColor Yellow
                $warningCount++
            }
            
        } catch {
            Write-Host "[$progress" + "%] ERROR: $($file.Name) -> $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
        }
    }
    
    # Generate combined master file if we have processed files
    if ($processedFiles.Count -gt 0) {
        Write-Host "`nCreating combined master file..." -ForegroundColor Cyan
        
        $combinedFile = Join-Path $outputFolder "00-COMBINED-ALL.txt"
        $combinedContent = @()
        
        # Add header with metadata
        $combinedContent += "COMBINED COURSE SUBTITLES"
        $combinedContent += "Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $combinedContent += "Total files processed: $($processedFiles.Count)"
        $combinedContent += "Source folder: $rootPath"
        $combinedContent += ("=" * 80)
        $combinedContent += ""
        
        # Sort files by folder number first, then by file number within each folder
        $sortedFiles = $processedFiles | Sort-Object {
            # Extract folder number (e.g., "01 - Introduction" -> 1)
            if ($_.FolderName -match '^(\d+)') {
                [int]$matches[1]
            } else {
                999999  # Put non-numbered folders at the end
            }
        }, {
            # Then sort by file number within each folder
            if ($_.Name -match '^(\d+)') {
                [int]$matches[1]
            } else {
                999999  # Put non-numbered files at the end
            }
        }, Name
        
        # Group by folder and add content with section headers
        $currentFolder = ""
        foreach ($fileInfo in $sortedFiles) {
            if ($fileInfo.FolderName -ne $currentFolder) {
                $currentFolder = $fileInfo.FolderName
                $combinedContent += ""
                $combinedContent += ("=" * 80)
                $combinedContent += "SECTION: $currentFolder"
                $combinedContent += ("=" * 80)
                $combinedContent += ""
            }
            
            $combinedContent += "=== $($fileInfo.Name) ==="
            $combinedContent += $fileInfo.Content
            $combinedContent += ""
            $combinedContent += ("-" * 50)
            $combinedContent += ""
        }
        
        # Save combined file
        $combinedContent | Out-File -FilePath $combinedFile -Encoding UTF8
        Write-Host "Combined file created: 00-COMBINED-ALL.txt" -ForegroundColor Green
    }
    
    # Display comprehensive summary
    Write-Host "`n" + ("=" * 60) -ForegroundColor Gray
    Write-Host "PROCESSING COMPLETE!" -ForegroundColor Green
    Write-Host ("=" * 60) -ForegroundColor Gray
    
    Write-Host "`nProcessing Statistics:" -ForegroundColor Cyan
    Write-Host "  Files found: $totalFiles" -ForegroundColor White
    Write-Host "  Successfully processed: $successCount" -ForegroundColor Green
    Write-Host "  Warnings (empty content): $warningCount" -ForegroundColor Yellow
    Write-Host "  Errors: $errorCount" -ForegroundColor Red
    Write-Host "  Output location: $outputFolder" -ForegroundColor White
    
    if ($processedFiles.Count -gt 0) {
        Write-Host "`nWhat you can do now:" -ForegroundColor Yellow
        Write-Host "  • Search entire course: Open '00-COMBINED-ALL.txt' and use Ctrl+F" -ForegroundColor Gray
        Write-Host "  • Study individual lectures: Browse .txt files in Subtitles folder" -ForegroundColor Gray
        Write-Host "  • Import to apps: Copy content to Obsidian, Notion, OneNote, etc." -ForegroundColor Gray
        Write-Host "  • Create study guides: Use clean text for note-taking and research" -ForegroundColor Gray
    }
    
    Write-Host "`nOpening results folder..." -ForegroundColor Cyan
    Start-Process explorer.exe -ArgumentList $outputFolder
    
    # Pause to show results
    Write-Host "`nPress any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    exit 0
    
} catch {
    Write-Host "`n" + ("=" * 50) -ForegroundColor Red
    Write-Host "FATAL ERROR OCCURRED!" -ForegroundColor Red
    Write-Host ("=" * 50) -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    
    Write-Host "`nTroubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "• Ensure subtitle files (.vtt/.srt) exist in the target folder" -ForegroundColor Gray
    Write-Host "• Check folder permissions (try running as Administrator)" -ForegroundColor Gray
    Write-Host "• Verify the script file is saved with UTF-8 encoding" -ForegroundColor Gray
    Write-Host "• Avoid special characters in folder paths: |<>*?" -ForegroundColor Gray
    Write-Host "• Close any programs that might be using the subtitle files" -ForegroundColor Gray
    
    Write-Host "`nFor more help, visit:" -ForegroundColor Cyan
    Write-Host "https://github.com/devsgh-cloudsec/video-course-transcript-organizer" -ForegroundColor Blue
    
    Write-Host "`nPress any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    exit 1
}
