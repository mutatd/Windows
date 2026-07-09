# Network Profile & Firewall Manager
Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "=== NETWORK PROFILE & FIREWALL MANAGER ===" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Must run as admin
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This tool requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please restart PowerShell as Administrator." -ForegroundColor Yellow
    Pause
    return
}

Write-Host "[1] View saved Wi-Fi profiles & passwords" -ForegroundColor Cyan
Write-Host "[2] Show active firewall rules (inbound)" -ForegroundColor Cyan
Write-Host "[3] Show active firewall rules (outbound)" -ForegroundColor Cyan
Write-Host "[4] Block a program in Windows Firewall" -ForegroundColor Cyan
Write-Host "[5] Unblock a program in Windows Firewall" -ForegroundColor Cyan
Write-Host "[6] Backup current firewall rules" -ForegroundColor Cyan
Write-Host "[7] Restore firewall rules from backup" -ForegroundColor Cyan
Write-Host "[8] Reset Windows Firewall to defaults" -ForegroundColor Cyan
Write-Host "[9] Show current network profile" -ForegroundColor Cyan
Write-Host "[Q] Return to main menu" -ForegroundColor Gray
Write-Host ""

$fwChoice = Read-Host "Select option"

switch ($fwChoice.ToUpper()) {
    '1' {
        Clear-Host
        Write-Host "=== SAVED WI-FI PROFILES ===" -ForegroundColor Yellow
        Write-Host ""
        $wifiProfiles = netsh wlan show profiles | Select-String ":\s+(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }
        if (-not $wifiProfiles) {
            Write-Host "No saved Wi-Fi profiles found." -ForegroundColor Gray
        } else {
            foreach ($profile in $wifiProfiles) {
                Write-Host "  SSID: $profile" -ForegroundColor Cyan
                $pw = netsh wlan show profile name="$profile" key=clear | Select-String "Key Content" | ForEach-Object { $_ -replace ".*:\s+", "" }
                if ($pw) {
                    Write-Host "    Password: $pw" -ForegroundColor Yellow
                } else {
                    Write-Host "    Password: (open network or unavailable)" -ForegroundColor Gray
                }
                Write-Host ""
            }
        }
        Pause
    }
    '2' {
        Clear-Host
        Write-Host "=== ACTIVE INBOUND RULES ===" -ForegroundColor Yellow
        Write-Host ""
        Get-NetFirewallRule -Direction Inbound -Enabled True -Action Allow | 
            Select-Object DisplayName, Profile, Program |
            Format-Table -AutoSize -Wrap
        Write-Host "Total rules: $((Get-NetFirewallRule -Direction Inbound -Enabled True).Count)" -ForegroundColor Cyan
        Pause
    }
    '3' {
        Clear-Host
        Write-Host "=== ACTIVE OUTBOUND RULES ===" -ForegroundColor Yellow
        Write-Host ""
        Get-NetFirewallRule -Direction Outbound -Enabled True -Action Allow | 
            Select-Object DisplayName, Profile, Program |
            Format-Table -AutoSize -Wrap
        Write-Host "Total rules: $((Get-NetFirewallRule -Direction Outbound -Enabled True).Count)" -ForegroundColor Cyan
        Pause
    }
    '4' {
        Clear-Host
        Write-Host "=== BLOCK A PROGRAM ===" -ForegroundColor Yellow
        Write-Host ""
        $progPath = Read-Host "Enter full path to the program (.exe)"
        if (-not (Test-Path $progPath)) {
            Write-Host "ERROR: File not found at: $progPath" -ForegroundColor Red
            Pause
            break
        }
        $progName = Read-Host "Enter a display name for this rule"
        if (-not $progName) { $progName = Split-Path $progPath -Leaf }
        
        try {
            New-NetFirewallRule -DisplayName "$progName (Blocked)" -Direction Outbound -Program $progPath -Action Block -ErrorAction Stop
            Write-Host "Outbound rule created and enabled for: $progName" -ForegroundColor Green
        } catch {
            Write-Host "ERROR: $_" -ForegroundColor Red
        }
        Pause
    }
    '5' {
        Clear-Host
        Write-Host "=== UNBLOCK A PROGRAM ===" -ForegroundColor Yellow
        Write-Host ""
        $blockedRules = Get-NetFirewallRule -Action Block -Enabled True | Where-Object { $_.Program -ne $null }
        if ($blockedRules.Count -eq 0) {
            Write-Host "No blocked program rules found." -ForegroundColor Gray
            Pause
            break
        }
        Write-Host "Currently blocked programs:" -ForegroundColor Cyan
        $i = 1
        foreach ($rule in $blockedRules) {
            Write-Host "  [$i] $($rule.DisplayName) -> $($rule.Program)" -ForegroundColor Yellow
            $i++
        }
        Write-Host ""
        $ruleNum = Read-Host "Enter number to unblock (or 0 to cancel)"
        if ($ruleNum -match '^\d+$' -and [int]$ruleNum -gt 0 -and [int]$ruleNum -le $blockedRules.Count) {
            $selectedRule = $blockedRules[[int]$ruleNum - 1]
            Remove-NetFirewallRule -DisplayName $selectedRule.DisplayName -ErrorAction SilentlyContinue
            Write-Host "Removed rule: $($selectedRule.DisplayName)" -ForegroundColor Green
        }
        Pause
    }
    '6' {
        Clear-Host
        Write-Host "=== BACKUP FIREWALL RULES ===" -ForegroundColor Yellow
        Write-Host ""
        $backupFolder = "$env:USERPROFILE\Documents\FirewallBackup"
        if (-not (Test-Path $backupFolder)) { New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null }
        $backupFile = "$backupFolder\FirewallRules_$(Get-Date -Format 'yyyyMMdd_HHmmss').fwpolicy"
        try {
            netsh advfirewall export "$backupFile"
            Write-Host "Firewall rules exported to:" -ForegroundColor Green
            Write-Host "  $backupFile" -ForegroundColor Yellow
        } catch {
            Write-Host "ERROR: $_" -ForegroundColor Red
        }
        Pause
    }
    '7' {
        Clear-Host
        Write-Host "=== RESTORE FIREWALL RULES ===" -ForegroundColor Yellow
        Write-Host ""
        $backupFolder = "$env:USERPROFILE\Documents\FirewallBackup"
        if (-not (Test-Path $backupFolder)) {
            Write-Host "No backup folder found." -ForegroundColor Gray
            Pause
            break
        }
        $backups = Get-ChildItem $backupFolder -Filter "*.fwpolicy" | Sort-Object LastWriteTime -Descending
        if ($backups.Count -eq 0) {
            Write-Host "No backup files found." -ForegroundColor Gray
            Pause
            break
        }
        Write-Host "Available backups:" -ForegroundColor Cyan
        $j = 1
        foreach ($bkp in $backups) {
            Write-Host "  [$j] $($bkp.Name) - $($bkp.LastWriteTime)" -ForegroundColor Yellow
            $j++
        }
        Write-Host ""
        $bkpNum = Read-Host "Enter number to restore (or 0 to cancel)"
        if ($bkpNum -match '^\d+$' -and [int]$bkpNum -gt 0 -and [int]$bkpNum -le $backups.Count) {
            $selectedBkp = $backups[[int]$bkpNum - 1]
            Write-Host "WARNING: This will overwrite current firewall rules!" -ForegroundColor Red
            $confirmRestore = Read-Host "Are you sure? (y/N)"
            if ($confirmRestore -eq 'y') {
                netsh advfirewall import "$($selectedBkp.FullName)"
                Write-Host "Firewall rules restored." -ForegroundColor Green
            }
        }
        Pause
    }
    '8' {
        Clear-Host
        Write-Host "=== RESET FIREWALL TO DEFAULTS ===" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "WARNING: This will remove ALL custom firewall rules!" -ForegroundColor Red
        Write-Host "Windows will return to its default out-of-the-box firewall state." -ForegroundColor Red
        Write-Host ""
        $resetConfirm = Read-Host "Type 'RESET' to confirm"
        if ($resetConfirm -eq 'RESET') {
            netsh advfirewall reset
            Write-Host "Firewall has been reset to defaults." -ForegroundColor Green
        } else {
            Write-Host "Cancelled." -ForegroundColor Yellow
        }
        Pause
    }
    '9' {
        Clear-Host
        Write-Host "=== CURRENT NETWORK PROFILES ===" -ForegroundColor Yellow
        Write-Host ""
        Get-NetConnectionProfile | Select-Object Name, InterfaceAlias, NetworkCategory, IPv4Connectivity, IPv6Connectivity | Format-List
        Write-Host ""
        Write-Host "Network Category key:" -ForegroundColor Gray
        Write-Host "  Public = Strict firewall, device not discoverable" -ForegroundColor Gray
        Write-Host "  Private = Relaxed firewall, device discoverable" -ForegroundColor Gray
        Write-Host "  Domain = Workplace network managed by domain controller" -ForegroundColor Gray
        Pause
    }
    'Q' { break }
    default { Write-Host "Invalid option." -ForegroundColor Red; Start-Sleep 1 }
}
