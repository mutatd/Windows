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
$cutoffDate = (Get-Date).AddDays(-$minAgeDays)

Write-Host "Current user (will be skipped): $env:USERNAME" -ForegroundColor Cyan
Write-Host "Minimum profile age: $minAgeDays days (not used since $($cutoffDate.ToString('yyyy-MM-dd')))" -ForegroundColor Cyan
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
    
    # Handle null LastUseTime
    if (-not $profile.LastUseTime) {
        $skipped += "No last use data: $username (removing anyway if old enough by file date)"
        # Fall back to folder last write time
        if (Test-Path $profile.LocalPath) {
            $lastWrite = (Get-Item $profile.LocalPath).LastWriteTime
            if ($lastWrite -gt $cutoffDate) {
                $skipped += "  -> Folder modified recently, skipping"
                continue
            }
        }
        $candidates += $profile
        continue
    }
    
    if ($profile.LastUseTime -gt $cutoffDate) {
        $skipped += "Too new: $username (last used $($profile.LastUseTime.ToString('yyyy-MM-dd')))"
        continue
    }
    
    $candidates += $profile
}

if ($candidates.Count -eq 0) {
    Write-Host "No profiles found that are safe to remove." -ForegroundColor Green
    Write-Host ""
    if ($skipped.Count -gt 0) {
        Write-Host "Skipped profiles:" -ForegroundColor DarkGray
        foreach ($s in $skipped) {
            Write-Host "  - $s" -ForegroundColor DarkGray
        }
    }
    Pause
    return
}

Write-Host "Profiles eligible for removal:" -ForegroundColor Red
Write-Host ""
foreach ($profile in $candidates) {
    $username = Split-Path $profile.LocalPath -Leaf
    $lastUsed = if ($profile.LastUseTime) { 
        $profile.LastUseTime.ToString('yyyy-MM-dd')
    } else { 
        "Unknown" 
    }
    Write-Host "  $username" -ForegroundColor Yellow -NoNewline
    Write-Host " - Last used: $lastUsed" -ForegroundColor Gray
}

Write-Host ""
if ($skipped.Count -gt 0) {
    Write-Host "Skipped:" -ForegroundColor DarkGray
    foreach ($s in $skipped) {
        Write-Host "  - $s" -ForegroundColor DarkGray
    }
}

Write-Host ""
$confirm = Read-Host "Delete these $($candidates.Count) profiles? (y/N)"

if ($confirm -eq 'y' -or $confirm -eq 'Y') {
    foreach ($profile in $candidates) {
        $username = Split-Path $profile.LocalPath -Leaf
        Write-Host "Deleting: $username..." -ForegroundColor Yellow
        
        try {
            Remove-CimInstance -InputObject $profile -Confirm:$false -ErrorAction Stop
            Write-Host "  Done." -ForegroundColor Green
        } catch {
            Write-Host "  Failed: $_" -ForegroundColor Red
        }
    }
    Write-Host ""
    Write-Host "All done." -ForegroundColor Green
} else {
    Write-Host "Cancelled." -ForegroundColor Yellow
}

Write-Host ""
Pause
