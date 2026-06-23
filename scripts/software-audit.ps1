# Installed Software Auditor
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     Installed Software Auditor" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

do {
    Write-Host "  [1] List All Installed Programs"
    Write-Host "  [2] List Recently Installed (30 days)"
    Write-Host "  [3] Find Large Programs (>500MB)"
    Write-Host "  [4] Search for Specific Program"
    Write-Host "  [5] Export Software List to CSV"
    Write-Host "  [6] Check Windows Store Apps"
    Write-Host "  [B] Back to Main Menu"
    Write-Host ""
    
    $choice = Read-Host "Select option"
    
    switch ($choice.ToUpper()) {
        '1' {
            Write-Host "`nAll Installed Programs:" -ForegroundColor Yellow
            Write-Host "=======================" -ForegroundColor Cyan
            
            try {
                $programs = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                          HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                          HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                    Where-Object { $_.DisplayName -and $_.DisplayName -notmatch 'Update for|Security Update|Hotfix' } |
                    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
                    Sort-Object DisplayName
                
                $count = 0
                foreach ($program in $programs) {
                    $count++
                    Write-Host "[$count] $($program.DisplayName)" -ForegroundColor White
                    if ($program.DisplayVersion) { Write-Host "     Version: $($program.DisplayVersion)" -ForegroundColor Gray }
                    if ($program.Publisher) { Write-Host "     Publisher: $($program.Publisher)" -ForegroundColor Gray }
                    if ($program.InstallDate) { Write-Host "     Installed: $($program.InstallDate)" -ForegroundColor Gray }
                    Write-Host "---" -ForegroundColor DarkGray
                }
                
                Write-Host "`nTotal programs found: $count" -ForegroundColor Yellow
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '2' {
            Write-Host "`nRecently Installed Programs (Last 30 days):" -ForegroundColor Yellow
            Write-Host "==========================================" -ForegroundColor Cyan
            
            try {
                $thirtyDaysAgo = (Get-Date).AddDays(-30).ToString("yyyyMMdd")
                
                $programs = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                          HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                          HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                    Where-Object { $_.DisplayName -and $_.InstallDate -and $_.InstallDate -gt $thirtyDaysAgo } |
                    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
                    Sort-Object InstallDate -Descending
                
                if ($programs) {
                    foreach ($program in $programs) {
                        Write-Host "Name: $($program.DisplayName)" -ForegroundColor White
                        Write-Host "Version: $($program.DisplayVersion)" -ForegroundColor Gray
                        Write-Host "Publisher: $($program.Publisher)" -ForegroundColor Gray
                        Write-Host "Installed: $($program.InstallDate)" -ForegroundColor Yellow
                        Write-Host "---" -ForegroundColor DarkGray
                    }
                } else {
                    Write-Host "No programs installed in the last 30 days" -ForegroundColor Green
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '3' {
            Write-Host "`nLarge Programs (>500MB):" -ForegroundColor Yellow
            Write-Host "=======================" -ForegroundColor Cyan
            Write-Host "This may take a moment..." -ForegroundColor Gray
            
            try {
                $paths = @(
                    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
                    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
                )
                
                $largePrograms = @()
                
                foreach ($path in $paths) {
                    $programs = Get-ItemProperty $path | Where-Object { $_.DisplayName -and $_.InstallLocation }
                    foreach ($program in $programs) {
                        if ($program.InstallLocation -and (Test-Path $program.InstallLocation)) {
                            try {
                                $size = (Get-ChildItem -Path $program.InstallLocation -Recurse -ErrorAction SilentlyContinue | 
                                    Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                                if ($size -and $size -gt 500MB) {
                                    $largePrograms += [PSCustomObject]@{
                                        Name = $program.DisplayName
                                        Size = [math]::Round($size/1GB, 2)
                                        Location = $program.InstallLocation
                                    }
                                }
                            } catch { }
                        }
                    }
                }
                
                if ($largePrograms) {
                    $largePrograms = $largePrograms | Sort-Object Size -Descending
                    foreach ($program in $largePrograms) {
                        Write-Host "Name: $($program.Name)" -ForegroundColor White
                        Write-Host "Size: $($program.Size) GB" -ForegroundColor Yellow
                        Write-Host "Location: $($program.Location)" -ForegroundColor Gray
                        Write-Host "---" -ForegroundColor DarkGray
                    }
                } else {
                    Write-Host "No large programs found or unable to determine sizes" -ForegroundColor Gray
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '4' {
            Write-Host "`nSearch for Program:" -ForegroundColor Yellow
            $searchTerm = Read-Host "Enter program name to search"
            
            if ($searchTerm) {
                Write-Host "`nSearching for '$searchTerm'..." -ForegroundColor Yellow
                
                try {
                    $results = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                            HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                            HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                        Where-Object { $_.DisplayName -and $_.DisplayName -match $searchTerm } |
                        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, UninstallString
                    
                    if ($results) {
                        foreach ($result in $results) {
                            Write-Host "`nName: $($result.DisplayName)" -ForegroundColor White
                            Write-Host "Version: $($result.DisplayVersion)" -ForegroundColor Gray
                            Write-Host "Publisher: $($result.Publisher)" -ForegroundColor Gray
                            Write-Host "Install Date: $($result.InstallDate)" -ForegroundColor Gray
                            if ($result.UninstallString) {
                                Write-Host "Uninstall: $($result.UninstallString)" -ForegroundColor DarkGray
                            }
                            Write-Host "---" -ForegroundColor DarkGray
                        }
                    } else {
                        Write-Host "No programs found matching '$searchTerm'" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "Error: $_" -ForegroundColor Red
                }
            }
            Pause
        }
        '5' {
            Write-Host "`nExporting Software List to CSV..." -ForegroundColor Yellow
            
            try {
                $desktopPath = [Environment]::GetFolderPath("Desktop")
                $exportPath = "$desktopPath\software_audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
                
                $programs = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                          HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
                                          HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
                    Where-Object { $_.DisplayName } |
                    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, UninstallString |
                    Sort-Object DisplayName
                
                $programs | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
                
                Write-Host "Software list exported to: $exportPath" -ForegroundColor Green
                Write-Host "Total programs exported: $($programs.Count)" -ForegroundColor Gray
            } catch {
                Write-Host "Error exporting: $_" -ForegroundColor Red
            }
            Pause
        }
        '6' {
            Write-Host "`nWindows Store Apps:" -ForegroundColor Yellow
            Write-Host "====================" -ForegroundColor Cyan
            
            try {
                $storeApps = Get-AppxPackage | Where-Object { $_.IsFramework -eq $false } | Sort-Object Name
                
                Write-Host "Total Store apps: $($storeApps.Count)" -ForegroundColor Yellow
                Write-Host "`nApp list:" -ForegroundColor Cyan
                
                foreach ($app in $storeApps) {
                    Write-Host "Name: $($app.Name)" -ForegroundColor White
                    Write-Host "Version: $($app.Version)" -ForegroundColor Gray
                    Write-Host "Publisher: $($app.Publisher)" -ForegroundColor Gray
                    Write-Host "Location: $($app.InstallLocation)" -ForegroundColor Gray
                    Write-Host "---" -ForegroundColor DarkGray
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        'B' { break }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice.ToUpper() -ne 'B')
