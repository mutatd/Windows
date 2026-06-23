# Windows Controller
Clear-Host
$Host.UI.RawUI.WindowTitle = "Windows Toolkit"

do {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "         Windows Toolkit" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] System Information Summary"
    Write-Host "  [2] Clear Temp Files & Recycle Bin"
    Write-Host "  [3] Delete Old User Profiles"
    Write-Host "  [4] Windows Update Manager"
    Write-Host "  [5] Startup Program Manager"
    Write-Host "  [6] Network Diagnostics"
    Write-Host "  [7] DNS Flush & Reset"
    Write-Host "  [8] Disk Cleanup & Optimisation"
    Write-Host "  [9] System File Checker & DISM"
    Write-Host " [10] Privacy Settings Tweaker"
    Write-Host " [11] Installed Software Auditor"
    Write-Host ""
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
        '3' { 
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
        '4' { 
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
        '5' { 
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
        '6' { 
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
        '7' { 
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
        '8' { 
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
        '9' { 
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
        '10' { 
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
        '11' { 
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
