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
    Write-Host "  [3] Delete Old User Profiles (DelProf)"
    Write-Host ""
    Write-Host "  [R] Refresh Controller"
    Write-Host "  [Q] Quit"
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    
    $choice = Read-Host "`nSelect option"
    
    switch ($choice.ToUpper()) {
        '1' { 
            Write-Host "Loading System Info..." -ForegroundColor Yellow
            $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/system-info.ps1'
            iex $script
        }
        '2' { 
            Write-Host "Loading Temp Cleaner..." -ForegroundColor Yellow
            $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/clear-temp.ps1'
            iex $script
        }
        '3' { 
            Write-Host "Loading Profile Cleaner..." -ForegroundColor Yellow
            $script = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/scripts/delprof.ps1'
            iex $script
        }
        'R' { 
            Write-Host "Refreshing controller from GitHub..." -ForegroundColor Yellow
            $newController = irm 'https://raw.githubusercontent.com/mutatd/Windows/refs/heads/main/controller.ps1'
            iex $newController
            return
        }
        'Q' { Write-Host "Exiting..." -ForegroundColor Yellow }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice.ToUpper() -ne 'Q')
