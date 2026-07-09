# Windows Controller
Clear-Host
$Host.UI.RawUI.WindowTitle = "Windows Toolkit"

do {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         Windows Toolkit" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  === SYSTEM TOOLS ===" -ForegroundColor DarkYellow
    Write-Host "  [1] System Information Summary"
    Write-Host "  [2] System File Checker & DISM"
    Write-Host "  [3] Installed Software Auditor"
    Write-Host ""
    Write-Host "  === MAINTENANCE ===" -ForegroundColor DarkYellow
    Write-Host "  [4] Clear Temp Files & Recycle Bin"
    Write-Host "  [5] Delete Old User Profiles"
    Write-Host "  [6] Disk Cleanup & Optimisation"
    Write-Host ""
    Write-Host "  === NETWORK ===" -ForegroundColor DarkYellow
    Write-Host "  [7] Network Diagnostics"
    Write-Host "  [8] DNS Flush & Reset"
    Write-Host "  [9] Network Profile & Firewall Manager"
    Write-Host "  [10] Hosts File Editor"
    Write-Host ""
    Write-Host "  === CONFIGURATION ===" -ForegroundColor DarkYellow
    Write-Host "  [11] Windows Update Manager"
    Write-Host "  [12] Startup Program Manager"
    Write-Host "  [13] Privacy Settings Tweaker"
    Write-Host "  [14] Service Manager"
    Write-Host "  [15] Power Plan Manager"
    Write-Host "  [16] Driver Manager"
    Write-Host ""
    Write-Host "  === DIAGNOSTICS ===" -ForegroundColor DarkYellow
    Write-Host "  [17] Event Log Analyst"
    Write-Host ""
    Write-Host "  === OPTIONS ===" -ForegroundColor DarkYellow
    Write-Host "  [R] Refresh Controller"
    Write-Host "  [Q] Quit"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    
    $choice = Read-Host "`nSelect option"
    
    switch ($choice.ToUpper()) {
        '1' { 
            Write-Host "Loading System Info..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/system-info.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '2' { 
            Write-Host "Loading System File Checker & DISM..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/system-repair.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '3' { 
            Write-Host "Loading Installed Software Auditor..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/software-audit.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '4' { 
            Write-Host "Loading Temp Cleaner..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/clear-temp.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '5' { 
            Write-Host "Loading Profile Cleaner..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/del-prof.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '6' { 
            Write-Host "Loading Disk Cleanup & Optimisation..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/disk-optimise.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '7' { 
            Write-Host "Loading Network Diagnostics..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/network-diag.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '8' { 
            Write-Host "Loading DNS Flusher & Reset..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/dns-reset.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '9' { 
            Write-Host "Loading Network Profile & Firewall Manager..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/network-firewall.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '10' { 
            Write-Host "Loading Hosts File Editor..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/hosts-editor.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '11' { 
            Write-Host "Loading Windows Update Manager..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/windows-update.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '12' { 
            Write-Host "Loading Startup Program Manager..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/startup-manager.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '13' { 
            Write-Host "Loading Privacy Settings Tweaker..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/privacy-tweaks.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '14' { 
            Write-Host "Loading Service Manager..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/service-manager.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '15' { 
            Write-Host "Loading Power Plan Manager..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/power-plan.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '16' { 
            Write-Host "Loading Driver Manager..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/driver-manager.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        '17' { 
            Write-Host "Loading Event Log Analyst..." -ForegroundColor Yellow
            try {
                $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/event-viewer.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $script
            } catch {
                Write-Host "ERROR: Could not load script - $_" -ForegroundColor Red
                Pause
            }
        }
        'R' { 
            Write-Host "Refreshing controller from GitHub..." -ForegroundColor Yellow
            try {
                $newController = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/controller.ps1' -UseBasicParsing -ErrorAction Stop
                Clear-Host
                iex $newController
                return
            } catch {
                Write-Host "ERROR: Could not refresh - $_" -ForegroundColor Red
                Pause
            }
        }
        'Q' { Write-Host "Exiting..." -ForegroundColor Yellow }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice.ToUpper() -ne 'Q')
