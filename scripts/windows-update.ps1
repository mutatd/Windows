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
    Write-Host "  [2] Install All Available Updates"
    Write-Host "  [3] Install Selected Updates"
    Write-Host "  [4] View Update History (Last 30 days)"
    Write-Host "  [5] Show Hidden Updates"
    Write-Host "  [6] Hide Specific Update"
    Write-Host "  [7] Pause Updates (7 days)"
    Write-Host "  [8] Resume Updates"
    Write-Host "  [9] Check Update Service Status"
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
                
                $script:AvailableUpdates = @()
                $count = 0
                foreach ($Update in $SearchResult.Updates) {
                    $count++
                    $script:AvailableUpdates += $Update
                    Write-Host "$count. $($Update.Title)" -ForegroundColor White
                    Write-Host "   KB: $($Update.KBArticleIDs)" -ForegroundColor Gray
                    Write-Host "   Size: $([math]::Round($Update.MaxDownloadSize/1MB,2)) MB" -ForegroundColor Gray
                    Write-Host "   Type: $($Update.Type)" -ForegroundColor Gray
                    Write-Host ""
                }
                
                if ($SearchResult.Updates.Count -eq 0) {
                    Write-Host "No updates available. System is up to date!" -ForegroundColor Green
                    $script:AvailableUpdates = @()
                }
            } catch {
                Write-Host "Error checking updates: $_" -ForegroundColor Red
            }
            Pause
        }
        '2' {
            Write-Host "`nInstalling All Available Updates..." -ForegroundColor Yellow
            Write-Host "==================================" -ForegroundColor Cyan
            
            if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
                Write-Host "ERROR: Administrator privileges required to install updates!" -ForegroundColor Red
                Pause
                break
            }
            
            try {
                $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
                Write-Host "Searching for updates..." -ForegroundColor Yellow
                $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
                
                if ($SearchResult.Updates.Count -eq 0) {
                    Write-Host "No updates available to install!" -ForegroundColor Green
                    Pause
                    break
                }
                
                Write-Host "Found $($SearchResult.Updates.Count) updates to install" -ForegroundColor Yellow
                Write-Host ""
                
                # List what will be installed
                foreach ($Update in $SearchResult.Updates) {
                    Write-Host "  - $($Update.Title)" -ForegroundColor White
                }
                
                $confirm = Read-Host "`nProceed with installation? (Y/N)"
                if ($confirm.ToUpper() -ne 'Y') {
                    Write-Host "Installation cancelled." -ForegroundColor Gray
                    Pause
                    break
                }
                
                # Create downloader and installer
                $Downloader = $UpdateSession.CreateUpdateDownloader()
                $Downloader.Updates = $SearchResult.Updates
                
                Write-Host "`nDownloading updates..." -ForegroundColor Yellow
                $DownloadResult = $Downloader.Download()
                
                if ($DownloadResult.ResultCode -eq 2) { # 2 = Downloaded
                    Write-Host "Downloads complete!" -ForegroundColor Green
                    
                    $Installer = $UpdateSession.CreateUpdateInstaller()
                    $Installer.Updates = $SearchResult.Updates
                    
                    Write-Host "Installing updates..." -ForegroundColor Yellow
                    $InstallResult = $Installer.Install()
                    
                    Write-Host "`nInstallation Result: $($InstallResult.ResultCode)" -ForegroundColor $(if($InstallResult.ResultCode -eq 2){'Green'}else{'Yellow'})
                    Write-Host "Reboot Required: $($InstallResult.RebootRequired)" -ForegroundColor $(if($InstallResult.RebootRequired){'Red'}else{'Green'})
                    
                    if ($InstallResult.RebootRequired) {
                        $reboot = Read-Host "`nReboot now? (Y/N)"
                        if ($reboot.ToUpper() -eq 'Y') {
                            Restart-Computer -Force
                        }
                    }
                } else {
                    Write-Host "Download failed! Result Code: $($DownloadResult.ResultCode)" -ForegroundColor Red
                }
            } catch {
                Write-Host "Error installing updates: $_" -ForegroundColor Red
                Write-Host "Try running Windows Update from Settings if this fails" -ForegroundColor Yellow
            }
            Pause
        }
        '3' {
            Write-Host "`nInstall Selected Updates..." -ForegroundColor Yellow
            Write-Host "===========================" -ForegroundColor Cyan
            
            if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
                Write-Host "ERROR: Administrator privileges required to install updates!" -ForegroundColor Red
                Pause
                break
            }
            
            try {
                $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
                Write-Host "Searching for updates..." -ForegroundColor Yellow
                $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
                
                if ($SearchResult.Updates.Count -eq 0) {
                    Write-Host "No updates available to install!" -ForegroundColor Green
                    Pause
                    break
                }
                
                $updates = @($SearchResult.Updates)
                Write-Host "`nAvailable updates:" -ForegroundColor Yellow
                for ($i = 0; $i -lt $updates.Count; $i++) {
                    Write-Host "[$($i+1)] $($updates[$i].Title)" -ForegroundColor White
                    Write-Host "    KB: $($updates[$i].KBArticleIDs) | Size: $([math]::Round($updates[$i].MaxDownloadSize/1MB,2)) MB" -ForegroundColor Gray
                }
                
                Write-Host "`nEnter update numbers to install (comma-separated, e.g., 1,3,5)" -ForegroundColor Yellow
                Write-Host "Enter 'A' for all, or '0' to cancel" -ForegroundColor Gray
                $selection = Read-Host "Selection"
                
                if ($selection -eq '0') {
                    Write-Host "Cancelled." -ForegroundColor Gray
                    Pause
                    break
                }
                
                $selectedUpdates = @()
                
                if ($selection.ToUpper() -eq 'A') {
                    $selectedUpdates = $updates
                    Write-Host "Selected all $($updates.Count) updates" -ForegroundColor Yellow
                } else {
                    $indices = $selection -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
                    foreach ($index in $indices) {
                        $idx = [int]$index - 1
                        if ($idx -ge 0 -and $idx -lt $updates.Count) {
                            $selectedUpdates += $updates[$idx]
                        }
                    }
                    
                    if ($selectedUpdates.Count -eq 0) {
                        Write-Host "No valid updates selected!" -ForegroundColor Red
                        Pause
                        break
                    }
                }
                
                Write-Host "`nSelected updates for installation:" -ForegroundColor Yellow
                foreach ($update in $selectedUpdates) {
                    Write-Host "  - $($update.Title)" -ForegroundColor White
                }
                
                $totalSize = [math]::Round(($selectedUpdates | Measure-Object -Property MaxDownloadSize -Sum).Sum/1MB, 2)
                Write-Host "`nTotal download size: $totalSize MB" -ForegroundColor Gray
                
                $confirm = Read-Host "`nProceed with installation? (Y/N)"
                if ($confirm.ToUpper() -ne 'Y') {
                    Write-Host "Installation cancelled." -ForegroundColor Gray
                    Pause
                    break
                }
                
                # Create download collection
                $UpdateCollection = New-Object -ComObject Microsoft.Update.UpdateColl
                foreach ($update in $selectedUpdates) {
                    $UpdateCollection.Add($update) | Out-Null
                }
                
                # Download
                $Downloader = $UpdateSession.CreateUpdateDownloader()
                $Downloader.Updates = $UpdateCollection
                
                Write-Host "`nDownloading selected updates..." -ForegroundColor Yellow
                $DownloadResult = $Downloader.Download()
                
                if ($DownloadResult.ResultCode -eq 2) {
                    Write-Host "Downloads complete!" -ForegroundColor Green
                    
                    # Install
                    $Installer = $UpdateSession.CreateUpdateInstaller()
                    $Installer.Updates = $UpdateCollection
                    
                    Write-Host "Installing updates..." -ForegroundColor Yellow
                    $InstallResult = $Installer.Install()
                    
                    Write-Host "`nInstallation Result: $($InstallResult.ResultCode)" -ForegroundColor $(if($InstallResult.ResultCode -eq 2){'Green'}else{'Yellow'})
                    Write-Host "Reboot Required: $($InstallResult.RebootRequired)" -ForegroundColor $(if($InstallResult.RebootRequired){'Red'}else{'Green'})
                    
                    if ($InstallResult.RebootRequired) {
                        $reboot = Read-Host "`nReboot now? (Y/N)"
                        if ($reboot.ToUpper() -eq 'Y') {
                            Restart-Computer -Force
                        }
                    }
                } else {
                    Write-Host "Download failed! Result Code: $($DownloadResult.ResultCode)" -ForegroundColor Red
                }
            } catch {
                Write-Host "Error installing updates: $_" -ForegroundColor Red
                Write-Host "Try running Windows Update from Settings if this fails" -ForegroundColor Yellow
            }
            Pause
        }
        '4' {
            Write-Host "`nRecent Update History:" -ForegroundColor Yellow
            try {
                $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
                $History = $UpdateSearcher.QueryHistory(0, 50)
                
                $recent = $History | Where-Object { $_.Date -gt (Get-Date).AddDays(-30) } | Sort-Object Date -Descending
                
                if ($recent) {
                    foreach ($entry in $recent) {
                        Write-Host "Title: $($entry.Title)" -ForegroundColor White
                        Write-Host "Date: $($entry.Date)" -ForegroundColor Gray
                        Write-Host "Result: $($entry.ResultCode)" -ForegroundColor $(if($entry.ResultCode -eq 2){'Green'}else{'Yellow'})
                        Write-Host "---" -ForegroundColor DarkGray
                    }
                } else {
                    Write-Host "No updates installed in the last 30 days" -ForegroundColor Gray
                }
            } catch {
                Write-Host "Error retrieving update history: $_" -ForegroundColor Red
            }
            Pause
        }
        '5' {
            Write-Host "`nHidden Updates:" -ForegroundColor Yellow
            try {
                $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
                $SearchResult = $UpdateSearcher.Search("IsHidden=1 and IsInstalled=0")
                
                if ($SearchResult.Updates.Count -gt 0) {
                    foreach ($Update in $SearchResult.Updates) {
                        Write-Host "Title: $($Update.Title)" -ForegroundColor White
                        Write-Host "KB: $($Update.KBArticleIDs)" -ForegroundColor Gray
                        Write-Host "---" -ForegroundColor DarkGray
                    }
                } else {
                    Write-Host "No hidden updates found." -ForegroundColor Green
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '6' {
            Write-Host "`nHide Specific Update" -ForegroundColor Yellow
            Write-Host "====================" -ForegroundColor Cyan
            
            try {
                $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
                Write-Host "Searching for available updates..." -ForegroundColor Yellow
                $SearchResult = $UpdateSearcher.Search("IsInstalled=0 and IsHidden=0")
                
                if ($SearchResult.Updates.Count -eq 0) {
                    Write-Host "No updates available to hide!" -ForegroundColor Green
                    Pause
                    break
                }
                
                $updates = @($SearchResult.Updates)
                Write-Host "`nAvailable updates:" -ForegroundColor Yellow
                for ($i = 0; $i -lt $updates.Count; $i++) {
                    Write-Host "[$($i+1)] $($updates[$i].Title)" -ForegroundColor White
                }
                
                $selection = Read-Host "`nEnter number to hide (0 to cancel)"
                if ($selection -eq '0') {
                    Write-Host "Cancelled." -ForegroundColor Gray
                    Pause
                    break
                }
                
                if ($selection -match '^\d+$') {
                    $idx = [int]$selection - 1
                    if ($idx -ge 0 -and $idx -lt $updates.Count) {
                        $updates[$idx].IsHidden = $true
                        Write-Host "Update hidden: $($updates[$idx].Title)" -ForegroundColor Green
                    }
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '7' {
            Write-Host "`nPausing Windows Updates for 7 days..." -ForegroundColor Yellow
            try {
                $pause = (Get-Date).AddDays(7)
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $pause.ToString("yyyy-MM-ddTHH:mm:ssZ") -ErrorAction Stop
                Write-Host "Updates paused until: $($pause.ToShortDateString())" -ForegroundColor Green
            } catch {
                Write-Host "Error pausing updates. Administrator privileges may be required: $_" -ForegroundColor Red
            }
            Pause
        }
        '8' {
            Write-Host "`nResuming Windows Updates..." -ForegroundColor Yellow
            try {
                Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -ErrorAction Stop
                Write-Host "Updates resumed successfully!" -ForegroundColor Green
            } catch {
                Write-Host "Updates are not currently paused, or error occurred" -ForegroundColor Yellow
            }
            Pause
        }
        '9' {
            Write-Host "`nWindows Update Service Status:" -ForegroundColor Yellow
            $services = @("wuauserv", "bits", "dosvc")
            foreach ($service in $services) {
                try {
                    $status = Get-Service -Name $service -ErrorAction Stop
                    Write-Host "$service`: $($status.Status) (Startup: $($status.StartType))" -ForegroundColor $(if($status.Status -eq 'Running'){'Green'}else{'Red'})
                } catch {
                    Write-Host "$service`: Not found" -ForegroundColor Red
                }
            }
            Pause
        }
        'B' { break }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice.ToUpper() -ne 'B')
