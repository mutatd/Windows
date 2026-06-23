# System File Checker & DISM
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    System File Checker & DISM" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: This tool requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please restart PowerShell as Administrator" -ForegroundColor Yellow
    Pause
    return
}

do {
    Write-Host "  [1] Run SFC Scan (Quick)"
    Write-Host "  [2] Run DISM CheckHealth"
    Write-Host "  [3] Run DISM ScanHealth"
    Write-Host "  [4] Run DISM RestoreHealth"
    Write-Host "  [5] Full System Repair (SFC + DISM)"
    Write-Host "  [6] View Recent CBS Logs"
    Write-Host "  [7] Check Windows Image Version"
    Write-Host "  [B] Back to Main Menu"
    Write-Host ""
    
    $choice = Read-Host "Select option"
    
    switch ($choice.ToUpper()) {
        '1' {
            Write-Host "`nRunning System File Checker (SFC)..." -ForegroundColor Yellow
            Write-Host "This will verify system files and repair if needed" -ForegroundColor Gray
            Write-Host "Progress:" -ForegroundColor Cyan
            
            try {
                $result = sfc /scannow
                Write-Host "`nSFC scan completed!" -ForegroundColor Green
                
                # Check CBS log for details
                $cbsLog = "$env:windir\Logs\CBS\CBS.log"
                if (Test-Path $cbsLog) {
                    $lastEntry = Get-Content $cbsLog -Tail 20 | Select-String "CSI|Cannot repair"
                    if ($lastEntry) {
                        Write-Host "`nLast relevant log entries:" -ForegroundColor Yellow
                        $lastEntry | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
                    }
                }
            } catch {
                Write-Host "Error running SFC: $_" -ForegroundColor Red
            }
            Pause
        }
        '2' {
            Write-Host "`nRunning DISM CheckHealth..." -ForegroundColor Yellow
            Write-Host "This checks if the image has been flagged as corrupted" -ForegroundColor Gray
            
            try {
                DISM /Online /Cleanup-Image /CheckHealth
                Write-Host "`nCheckHealth completed!" -ForegroundColor Green
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '3' {
            Write-Host "`nRunning DISM ScanHealth..." -ForegroundColor Yellow
            Write-Host "This performs a more thorough scan for corruption" -ForegroundColor Gray
            Write-Host "This may take 10-20 minutes..." -ForegroundColor Yellow
            
            try {
                DISM /Online /Cleanup-Image /ScanHealth
                Write-Host "`nScanHealth completed!" -ForegroundColor Green
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '4' {
            Write-Host "`nRunning DISM RestoreHealth..." -ForegroundColor Yellow
            Write-Host "This will attempt to repair any corruption found" -ForegroundColor Gray
            Write-Host "This may take 15-30 minutes..." -ForegroundColor Yellow
            
            try {
                DISM /Online /Cleanup-Image /RestoreHealth
                Write-Host "`nRestoreHealth completed!" -ForegroundColor Green
                Write-Host "Recommended to run SFC scan after this" -ForegroundColor Yellow
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
                Write-Host "You may need to specify a repair source with /Source flag" -ForegroundColor Yellow
            }
            Pause
        }
        '5' {
            Write-Host "`nStarting Full System Repair..." -ForegroundColor Yellow
            Write-Host "================================" -ForegroundColor Cyan
            Write-Host "Step 1/2: Running DISM RestoreHealth..." -ForegroundColor Yellow
            Write-Host "This may take 15-30 minutes..." -ForegroundColor Yellow
            
            try {
                DISM /Online /Cleanup-Image /RestoreHealth
                Write-Host "`nDISM completed!" -ForegroundColor Green
                
                Write-Host "`nStep 2/2: Running SFC /scannow..." -ForegroundColor Yellow
                sfc /scannow
                Write-Host "`nFull system repair completed!" -ForegroundColor Green
                
                $restart = Read-Host "`nA system restart may be required. Restart now? (Y/N)"
                if ($restart.ToUpper() -eq 'Y') {
                    Restart-Computer -Force
                }
            } catch {
                Write-Host "Error during repair: $_" -ForegroundColor Red
            }
            Pause
        }
        '6' {
            Write-Host "`nRecent CBS Log Entries:" -ForegroundColor Yellow
            Write-Host "========================" -ForegroundColor Cyan
            $cbsLog = "$env:windir\Logs\CBS\CBS.log"
            
            if (Test-Path $cbsLog) {
                Write-Host "Showing last 50 lines with errors or repairs:" -ForegroundColor Gray
                try {
                    $entries = Get-Content $cbsLog -Tail 200 | Select-String "Error|Failed|Cannot repair|Corrupted" | Select-Object -Last 50
                    if ($entries) {
                        foreach ($entry in $entries) {
                            Write-Host $entry -ForegroundColor $(if($entry -match "Cannot repair"){'Red'}else{'Yellow'})
                        }
                    } else {
                        Write-Host "No recent errors found in CBS log" -ForegroundColor Green
                    }
                } catch {
                    Write-Host "Error reading CBS log: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "CBS log not found" -ForegroundColor Red
            }
            Pause
        }
        '7' {
            Write-Host "`nWindows Image Information:" -ForegroundColor Yellow
            Write-Host "=========================" -ForegroundColor Cyan
            
            try {
                Write-Host "OS Version:" -ForegroundColor White
                Get-ComputerInfo | Select-Object WindowsVersion, OsName, OsBuildNumber, OsArchitecture | Format-List
                
                Write-Host "`nDISM Image Version:" -ForegroundColor White
                DISM /Online /Get-CurrentEdition
                DISM /Online /Get-TargetEditions
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        'B' { break }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice.ToUpper() -ne 'B')
