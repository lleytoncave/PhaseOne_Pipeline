# =============================
# SETTINGS
# =============================
$inputFolder  = "D:\PhaseOne\100PHASE"
$outputFolder = "D:\PhaseOne\100PHASEout_10_75"
$resize       = "10%"   # Resize to 10% of original dimensions
$quality      = 75

# Ensure output folder exists
New-Item -ItemType Directory -Force -Path $outputFolder | Out-Null

# =============================
# GET FILES
# =============================
$files = Get-ChildItem -Path $inputFolder -Filter *.iiq
if ($files.Count -eq 0) { Write-Host "No IIQ files found in $inputFolder"; exit }

# Natural sort workaround for PowerShell 5.1
$files = $files | Sort-Object {[regex]::Matches($_.Name,'\d+') | ForEach-Object { [int]$_.Value }}, Name

$total = $files.Count
Write-Host "Found $total IIQ files to process."

# =============================
# PROCESS FILES SEQUENTIALLY
# =============================
$startTime = Get-Date
$completed = 0

foreach ($file in $files) {
    $fileStart = Get-Date
    $basename = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $outfile = Join-Path $outputFolder ($basename + ".jpg")

    if (Test-Path $outfile) {
        $message = "Skipped"
    } else {
        try {
            # Convert IIQ to JPG using ImageMagick 7 recommended command
            magick $file.FullName -resize $resize -quality $quality $outfile
            $message = "Converted"
        } catch {
            $message = "Error"
        }
    }

    $completed++
    
    # Timing calculations
    $fileElapsed = (Get-Date) - $fileStart
    $elapsed = (Get-Date) - $startTime
    $avgPerFile = $elapsed.TotalSeconds / $completed
    $remainingSeconds = [math]::Round($avgPerFile * ($total - $completed))

    # Format estimated remaining time
    $hours = [int]([math]::Floor($remainingSeconds / 3600))
    $minutes = [int]([math]::Floor(($remainingSeconds % 3600) / 60))
    $seconds = [int]($remainingSeconds % 60)
    $remainingFormatted = "{0:D2}:{1:D2}:{2:D2}" -f $hours, $minutes, $seconds

    # Time per image
    $fileSeconds = [math]::Round($fileElapsed.TotalSeconds, 2)

    # Progress bar
    $percent = [math]::Round(($completed / $total) * 100)
    $barLength = 30
    $filled = [math]::Round($barLength * $completed / $total)
    $empty = $barLength - $filled
    $bar = "[" + ("#" * $filled) + ("-" * $empty) + "] $percent%"

    # Update progress in-place
    $statusMessage = "$bar [$completed/$total] $message - Time/image: ${fileSeconds}s - Est. left: $remainingFormatted"
    Write-Host -NoNewline "`r$statusMessage"
}

# New line after progress bar is done
Write-Host ""

# =============================
# SUMMARY
# =============================
$runtime = (Get-Date) - $startTime
$runtimeFormatted = "{0:D2}:{1:D2}:{2:D2}" -f [int]$runtime.Hours, [int]$runtime.Minutes, [int]$runtime.Seconds

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Processed $total files in $runtimeFormatted (hh:mm:ss)" -ForegroundColor Cyan
Write-Host "Average: $([math]::Round($runtime.TotalSeconds / $total, 2))s per file" -ForegroundColor Cyan
Write-Host "Output folder: $outputFolder" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
