# Windows Update Manager
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     Windows Update Manager" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "WARNING: Some features require administrator privileges" -ForegroundColor Yellow
    Write-Host ""
}

do {
    Write-Host "  [1] Check for Updates"
    Write-Host "  [2] View Update History (Last 30 days)"
    Write-Host "  [3] Show Hidden Updates"
    Write-Host "  [4] Pause Updates (7 days)"
    Write-Host "  [5] Resume Updates"
    Write-Host "  [6] Check Update Service Status"
    Write-Host "  [B] Back to Main Menu"
    Write-Host ""
    
    $choice = Read-Host "Select option"
    
    switch ($choice.ToUpper()) {
        '1' {
            Write-Host "`nChecking for Windows Updates..." -ForegroundColor Yellow
            try {
                $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
                Write-Host "Searching for updates (this may take a moment)..." -ForegroundColor Gray
                $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
                Write-Host "`nFound $($SearchResult.Updates.Count) available updates:" -ForegroundColor Green
                
                $count = 0
                foreach ($Update in $SearchResult.Updates) {
                    $count++
                    Write-Host "$count. $($Update.Title)" -ForegroundColor White
                    Write-Host "   KB: $($Update.KBArticleIDs)" -ForegroundColor Gray
                    Write-Host "   Size: $([math]::Round($Update.MaxDownloadSize/1MB,2)) MB" -ForegroundColor Gray
                    Write-Host "   Type: $($Update.Type)" -ForegroundColor Gray
                    Write-Host ""
                }
                
                if ($SearchResult.Updates.Count -eq 0) {
                    Write-Host "No updates available. System is up to date!" -ForegroundColor Green
                }
            } catch {
                Write-Host "Error checking updates: $_" -ForegroundColor Red
            }
            Pause
        }
        '2' {
            Write-Host "`nRecent Update History:" -ForegroundColor Yellow
            try {
                $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
                $History = $UpdateSearcher.QueryHistory(0, 50)
                
                $recent = $History | Where-Object { $_.Date -gt (Get-Date).AddDays(-30) } | Sort-Object Date -Descending
                
                foreach ($entry in $recent) {
                    Write-Host "Title: $($entry.Title)" -ForegroundColor White
                    Write-Host "Date: $($entry.Date)" -ForegroundColor Gray
                    Write-Host "Result: $($entry.ResultCode)" -ForegroundColor $(if($entry.ResultCode -eq 2){'Green'}else{'Yellow'})
                    Write-Host "---" -ForegroundColor DarkGray
                }
            } catch {
                Write-Host "Error retrieving update history: $_" -ForegroundColor Red
            }
            Pause
        }
        '3' {
            Write-Host "`nHidden Updates:" -ForegroundColor Yellow
            try {
                $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
                $SearchResult = $UpdateSearcher.Search("IsHidden=1 and IsInstalled=0")
                
                foreach ($Update in $SearchResult.Updates) {
                    Write-Host "Title: $($Update.Title)" -ForegroundColor White
                    Write-Host "KB: $($Update.KBArticleIDs)" -ForegroundColor Gray
                    Write-Host "---" -ForegroundColor DarkGray
                }
                
                if ($SearchResult.Updates.Count -eq 0) {
                    Write-Host "No hidden updates found." -ForegroundColor Green
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '4' {
            Write-Host "`nPausing Windows Updates for 7 days..." -ForegroundColor Yellow
            try {
                $pause = (Get-Date).AddDays(7)
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $pause.ToString("yyyy-MM-ddTHH:mm:ssZ")
                Write-Host "Updates paused until: $($pause.ToShortDateString())" -ForegroundColor Green
            } catch {
                Write-Host "Error pausing updates: $_" -ForegroundColor Red
            }
            Pause
        }
        '5' {
            Write-Host "`nResuming Windows Updates..." -ForegroundColor Yellow
            try {
                Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue
                Write-Host "Updates resumed successfully!" -ForegroundColor Green
            } catch {
                Write-Host "Error resuming updates: $_" -ForegroundColor Red
            }
            Pause
        }
        '6' {
            Write-Host "`nWindows Update Service Status:" -ForegroundColor Yellow
            $services = @("wuauserv", "bits", "dosvc")
            foreach ($service in $services) {
                $status = Get-Service -Name $service -ErrorAction SilentlyContinue
                if ($status) {
                    Write-Host "$service`: $($status.Status) (Startup: $($status.StartType))" -ForegroundColor $(if($status.Status -eq 'Running'){'Green'}else{'Red'})
                } else {
                    Write-Host "$service`: Not found" -ForegroundColor Red
                }
            }
            Pause
        }
        'B' { break }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice.ToUpper() -ne 'B')
