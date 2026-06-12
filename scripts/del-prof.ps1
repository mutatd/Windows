Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "=== DELETE OLD PROFILES ===" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Never delete these
$excludedUsers = @(
    $env:USERNAME,
    "Public",
    "Default",
    "Default User",
    "All Users",
    "Administrator",
    "defaultuser0"
)

# Only remove profiles older than this many days
$minAgeDays = 30

Write-Host "Current user (will be skipped): $env:USERNAME" -ForegroundColor Cyan
Write-Host "Minimum profile age: $minAgeDays days" -ForegroundColor Cyan
Write-Host ""

$profiles = Get-CimInstance Win32_UserProfile | Where-Object { 
    -not $_.Special -and 
    $_.LocalPath -notlike "*\Windows\*" -and
    $_.LocalPath -notlike "*\ServiceProfiles\*"
}

$candidates = @()
$skipped = @()

foreach ($profile in $profiles) {
    $username = Split-Path $profile.LocalPath -Leaf
    
    if ($username -in $excludedUsers) {
        $skipped += "Excluded: $username"
        continue
    }
    
    $profileAge = (Get-Date) - $profile.LastUseTime
    
    if ($profileAge.Days -lt $minAgeDays) {
        $skipped += "Too new: $username ($($profileAge.Days) days old)"
        continue
    }
    
    $candidates += $profile
}

if ($candidates.Count -eq 0) {
    Write-Host "No profiles found that are safe to remove." -ForegroundColor Green
    Write-Host ""
    Write-Host "Skipped profiles:" -ForegroundColor DarkGray
    foreach ($s in $skipped) {
        Write-Host "  - $s" -ForegroundColor DarkGray
    }
    Pause
    return
}

Write-Host "Profiles eligible for removal:" -ForegroundColor Red
Write-Host ""
foreach ($profile in $candidates) {
    $username = Split-Path $profile.LocalPath -Leaf
    $age = ((Get-Date) - $profile.LastUseTime).Days
    $size = if (Test-Path $profile.LocalPath) {
        try {
            $folderSize = (Get-ChildItem $profile.LocalPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            "$([math]::Round($folderSize/1MB, 0)) MB"
        } catch {
            "Unknown"
        }
    } else {
        "Folder missing"
    }
    Write-Host "  $username" -ForegroundColor Yellow -NoNewline
    Write-Host " - Last used: $age days ago" -ForegroundColor Gray -NoNewline
    Write-Host " - Size: $size" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Skipped:" -ForegroundColor DarkGray
foreach ($s in $skipped) {
    Write-Host "  - $s" -ForegroundColor DarkGray
}

Write-Host ""
$confirm = Read-Host "Delete these $($candidates.Count) profiles? (y/N)"

if ($confirm -eq 'y' -or $confirm -eq 'Y') {
    $totalFreed = 0
    foreach ($profile in $candidates) {
        $username = Split-Path $profile.LocalPath -Leaf
        Write-Host "Deleting: $username..." -ForegroundColor Yellow
        
        # Get size before deletion
        if (Test-Path $profile.LocalPath) {
            $size = (Get-ChildItem $profile.LocalPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            $totalFreed += $size
        }
        
        try {
            Remove-CimInstance -InputObject $profile -Confirm:$false -ErrorAction Stop
            Write-Host "  Done." -ForegroundColor Green
        } catch {
            Write-Host "  Failed: $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Total space freed: $([math]::Round($totalFreed/1GB, 2)) GB" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
} else {
    Write-Host "Cancelled." -ForegroundColor Yellow
}

Write-Host ""
Pause
