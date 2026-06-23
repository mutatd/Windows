# Disk Cleanup & optimisation
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    Disk Cleanup & Optimisation" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "WARNING: Administrator privileges recommended for full functionality" -ForegroundColor Yellow
    Write-Host ""
}

do {
    Write-Host "  [1] Drive Space Overview"
    Write-Host "  [2] Run Disk Cleanup (System)"
    Write-Host "  [3] Clear Windows Update Cache"
    Write-Host "  [4] Clear Delivery Optimisation Files"
    Write-Host "  [5] analyse Drive Fragmentation"
    Write-Host "  [6] Optimize/Defrag Drives"
    Write-Host "  [7] analyse Large Files (>100MB)"
    Write-Host "  [8] Clean Prefetch Files"
    Write-Host "  [B] Back to Main Menu"
    Write-Host ""
    
    $choice = Read-Host "Select option"
    
    switch ($choice.ToUpper()) {
        '1' {
            Write-Host "`nDrive Space Overview:" -ForegroundColor Yellow
            Write-Host "=====================" -ForegroundColor Cyan
            $drives = Get-PSDrive -PSProvider FileSystem
            foreach ($drive in $drives) {
                $totalGB = [math]::Round($drive.Used/1GB + $drive.Free/1GB, 2)
                $usedGB = [math]::Round($drive.Used/1GB, 2)
                $freeGB = [math]::Round($drive.Free/1GB, 2)
                $percentUsed = [math]::Round(($usedGB/$totalGB)*100, 1)
                
                Write-Host "`nDrive $($drive.Name):" -ForegroundColor White
                Write-Host "Total: $totalGB GB" -ForegroundColor Gray
                Write-Host "Used: $usedGB GB ($percentUsed%)" -ForegroundColor $(if($percentUsed -gt 90){'Red'}elseif($percentUsed -gt 75){'Yellow'}else{'Green'})
                Write-Host "Free: $freeGB GB" -ForegroundColor $(if($freeGB -lt 10){'Red'}elseif($freeGB -lt 25){'Yellow'}else{'Green'})
                
                # Visual bar
                $barLength = 50
                $filled = [math]::Round(($percentUsed/100)*$barLength)
                $empty = $barLength - $filled
                Write-Host ("[" + ("█" * $filled) + ("░" * $empty) + "]") -ForegroundColor Cyan
            }
            Pause
        }
        '2' {
            Write-Host "`nRunning Disk Cleanup..." -ForegroundColor Yellow
            if (-not $isAdmin) {
                Write-Host "This requires Administrator privileges!" -ForegroundColor Red
            } else {
                try {
                    Write-Host "Starting system disk cleanup..." -ForegroundColor Yellow
                    Start-Process cleanmgr -ArgumentList "/sagerun:1" -Wait -NoNewWindow
                    Write-Host "Disk cleanup completed!" -ForegroundColor Green
                } catch {
                    Write-Host "Error: $_" -ForegroundColor Red
                    Write-Host "Try running 'cleanmgr' manually from Run dialog" -ForegroundColor Yellow
                }
            }
            Pause
        }
        '3' {
            Write-Host "`nClearing Windows Update Cache..." -ForegroundColor Yellow
            if (-not $isAdmin) {
                Write-Host "This requires Administrator privileges!" -ForegroundColor Red
            } else {
                $confirm = Read-Host "This will stop Windows Update service. Continue? (Y/N)"
                if ($confirm.ToUpper() -eq 'Y') {
                    try {
                        Write-Host "Stopping Windows Update service..." -ForegroundColor Yellow
                        Stop-Service -Name wuauserv -Force
                        
                        $cachePath = "$env:windir\SoftwareDistribution\Download"
                        if (Test-Path $cachePath) {
                            $size = (Get-ChildItem $cachePath -Recurse | Measure-Object -Property Length -Sum).Sum
                            Write-Host "Removing cache files... ($([math]::Round($size/1MB,2)) MB)" -ForegroundColor Yellow
                            Remove-Item -Path "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
                        }
                        
                        Write-Host "Starting Windows Update service..." -ForegroundColor Yellow
                        Start-Service -Name wuauserv
                        
                        Write-Host "Update cache cleared successfully!" -ForegroundColor Green
                    } catch {
                        Write-Host "Error: $_" -ForegroundColor Red
                    }
                }
            }
            Pause
        }
        '4' {
            Write-Host "`nClearing Delivery Optimisation Files..." -ForegroundColor Yellow
            if (-not $isAdmin) {
                Write-Host "This requires Administrator privileges!" -ForegroundColor Red
            } else {
                try {
                    $doPath = "$env:windir\DeliveryOptimisation\Cache"
                    if (Test-Path $doPath) {
                        $size = (Get-ChildItem $doPath -Recurse | Measure-Object -Property Length -Sum).Sum
                        Write-Host "Removing Delivery Optimisation cache... ($([math]::Round($size/1MB,2)) MB)" -ForegroundColor Yellow
                        Remove-Item -Path "$doPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Host "Delivery Optimisation cache cleared!" -ForegroundColor Green
                    } else {
                        Write-Host "No Delivery Optimisation cache found." -ForegroundColor Gray
                    }
                } catch {
                    Write-Host "Error: $_" -ForegroundColor Red
                }
            }
            Pause
        }
        '5' {
            Write-Host "`nAnalysing Drive Fragmentation..." -ForegroundColor Yellow
            try {
                $drives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter -ne $null }
                foreach ($drive in $drives) {
                    Write-Host "`nDrive $($drive.DriveLetter): - $($drive.FileSystemLabel)" -ForegroundColor White
                    $result = Optimize-Volume -DriveLetter $drive.DriveLetter -analyse -Verbose 4>&1
                    Write-Host $result -ForegroundColor Gray
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '6' {
            Write-Host "`nOptimising Drives..." -ForegroundColor Yellow
            if (-not $isAdmin) {
                Write-Host "This requires Administrator privileges!" -ForegroundColor Red
            } else {
                try {
                    $drives = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter -ne $null }
                    foreach ($drive in $drives) {
                        Write-Host "Optimising drive $($drive.DriveLetter):..." -ForegroundColor Yellow
                        Optimize-Volume -DriveLetter $drive.DriveLetter -Defrag -Verbose
                    }
                    Write-Host "`nDrive optimisation complete!" -ForegroundColor Green
                } catch {
                    Write-Host "Error: $_" -ForegroundColor Red
                }
            }
            Pause
        }
        '7' {
            Write-Host "`nAnalysing Large Files (>100MB)..." -ForegroundColor Yellow
            Write-Host "This may take a moment..." -ForegroundColor Gray
            $path = Read-Host "Enter path to scan (default: C:\)"
            if ([string]::IsNullOrWhiteSpace($path)) { $path = "C:\" }
            
            if (Test-Path $path) {
                try {
                    $largeFiles = Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | 
                        Where-Object { $_.Length -gt 100MB } |
                        Sort-Object Length -Descending |
                        Select-Object -First 20
                    
                    Write-Host "`nLargest files found:" -ForegroundColor Yellow
                    foreach ($file in $largeFiles) {
                        $sizeMB = [math]::Round($file.Length/1MB, 2)
                        Write-Host "$sizeMB MB - $($file.FullName)" -ForegroundColor $(if($sizeMB -gt 1000){'Red'}elseif($sizeMB -gt 500){'Yellow'}else{'White'})
                    }
                } catch {
                    Write-Host "Error scanning: $_" -ForegroundColor Red
                    Write-Host "Some system locations may be inaccessible" -ForegroundColor Gray
                }
            }
            Pause
        }
        '8' {
            Write-Host "`nCleaning Prefetch Files..." -ForegroundColor Yellow
            if (-not $isAdmin) {
                Write-Host "This requires Administrator privileges!" -ForegroundColor Red
            } else {
                try {
                    $prefetchPath = "$env:windir\Prefetch"
                    if (Test-Path $prefetchPath) {
                        $size = (Get-ChildItem $prefetchPath | Measure-Object -Property Length -Sum).Sum
                        Write-Host "Prefetch folder size: $([math]::Round($size/1MB,2)) MB" -ForegroundColor Gray
                        
                        $confirm = Read-Host "Clear prefetch files? (Y/N)"
                        if ($confirm.ToUpper() -eq 'Y') {
                            Remove-Item -Path "$prefetchPath\*.pf" -Force -ErrorAction SilentlyContinue
                            Write-Host "Prefetch files cleared!" -ForegroundColor Green
                        }
                    }
                } catch {
                    Write-Host "Error: $_" -ForegroundColor Red
                }
            }
            Pause
        }
        'B' { break }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice.ToUpper() -ne 'B')
