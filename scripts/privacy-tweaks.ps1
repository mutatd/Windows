# Privacy Settings Tweaker
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "      Privacy Settings Tweaker" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "WARNING: Some features require administrator privileges" -ForegroundColor Yellow
    Write-Host ""
}

do {
    Write-Host "  [1] Disable Telemetry"
    Write-Host "  [2] Disable Cortana"
    Write-Host "  [3] Disable Activity History"
    Write-Host "  [4] Disable Advertising ID"
    Write-Host "  [5] Disable App Diagnostics Access"
    Write-Host "  [6] Apply All Privacy Tweaks"
    Write-Host "  [7] Check Current Privacy Settings"
    Write-Host "  [B] Back to Main Menu"
    Write-Host ""
    
    $choice = Read-Host "Select option"
    
    switch ($choice.ToUpper()) {
        '1' {
            Write-Host "`nDisabling Telemetry..." -ForegroundColor Yellow
            if (-not $isAdmin) {
                Write-Host "This requires Administrator privileges!" -ForegroundColor Red
            } else {
                try {
                    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
                    if (-not (Test-Path $path)) {
                        New-Item -Path $path -Force | Out-Null
                    }
                    Set-ItemProperty -Path $path -Name "AllowTelemetry" -Value 0 -Type DWord
                    
                    # Also disable via service
                    Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
                    Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
                    
                    Write-Host "Telemetry disabled successfully!" -ForegroundColor Green
                    Write-Host "Note: Some telemetry may still be required for Windows Update" -ForegroundColor Yellow
                } catch {
                    Write-Host "Error: $_" -ForegroundColor Red
                }
            }
            Pause
        }
        '2' {
            Write-Host "`nDisabling Cortana..." -ForegroundColor Yellow
            if (-not $isAdmin) {
                Write-Host "This requires Administrator privileges!" -ForegroundColor Red
            } else {
                try {
                    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
                    if (-not (Test-Path $path)) {
                        New-Item -Path $path -Force | Out-Null
                    }
                    Set-ItemProperty -Path $path -Name "AllowCortana" -Value 0 -Type DWord
                    Set-ItemProperty -Path $path -Name "AllowSearchToUseLocation" -Value 0 -Type DWord
                    
                    Write-Host "Cortana disabled!" -ForegroundColor Green
                } catch {
                    Write-Host "Error: $_" -ForegroundColor Red
                }
            }
            Pause
        }
        '3' {
            Write-Host "`nDisabling Activity History..." -ForegroundColor Yellow
            try {
                $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
                if (-not (Test-Path $path)) {
                    New-Item -Path $path -Force | Out-Null
                }
                Set-ItemProperty -Path $path -Name "EnableActivityFeed" -Value 0 -Type DWord
                Set-ItemProperty -Path $path -Name "PublishUserActivities" -Value 0 -Type DWord
                Set-ItemProperty -Path $path -Name "UploadUserActivities" -Value 0 -Type DWord
                
                Write-Host "Activity History disabled!" -ForegroundColor Green
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '4' {
            Write-Host "`nDisabling Advertising ID..." -ForegroundColor Yellow
            try {
                $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
                if (-not (Test-Path $path)) {
                    New-Item -Path $path -Force | Out-Null
                }
                Set-ItemProperty -Path $path -Name "Enabled" -Value 0 -Type DWord
                
                if ($isAdmin) {
                    $pathSystem = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
                    if (-not (Test-Path $pathSystem)) {
                        New-Item -Path $pathSystem -Force | Out-Null
                    }
                    Set-ItemProperty -Path $pathSystem -Name "DisabledByGroupPolicy" -Value 1 -Type DWord
                }
                
                Write-Host "Advertising ID disabled!" -ForegroundColor Green
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '5' {
            Write-Host "`nDisabling App Diagnostics Access..." -ForegroundColor Yellow
            try {
                $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics"
                if (-not (Test-Path $path)) {
                    New-Item -Path $path -Force | Out-Null
                }
                Set-ItemProperty -Path $path -Name "Value" -Value "Deny" -Type String
                
                Write-Host "App diagnostics access disabled!" -ForegroundColor Green
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '6' {
            Write-Host "`nApplying All Privacy Tweaks..." -ForegroundColor Yellow
            Write-Host "===============================" -ForegroundColor Cyan
            
            $confirm = Read-Host "This will apply all privacy tweaks. Continue? (Y/N)"
            if ($confirm.ToUpper() -ne 'Y') {
                Write-Host "Cancelled." -ForegroundColor Gray
                Pause
                break
            }
            
            if (-not $isAdmin) {
                Write-Host "This requires Administrator privileges for full effect!" -ForegroundColor Red
                Write-Host "Applying user-level tweaks only..." -ForegroundColor Yellow
            }
            
            Write-Host "`nApplying privacy settings..." -ForegroundColor Yellow
            
            try {
                # Telemetry
                if ($isAdmin) {
                    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
                    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                    Set-ItemProperty -Path $path -Name "AllowTelemetry" -Value 0 -Type DWord
                    
                    Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
                    Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
                }
                
                # Cortana
                if ($isAdmin) {
                    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
                    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                    Set-ItemProperty -Path $path -Name "AllowCortana" -Value 0 -Type DWord
                    Set-ItemProperty -Path $path -Name "AllowSearchToUseLocation" -Value 0 -Type DWord
                }
                
                # Activity History
                if ($isAdmin) {
                    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
                    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                    Set-ItemProperty -Path $path -Name "EnableActivityFeed" -Value 0 -Type DWord
                    Set-ItemProperty -Path $path -Name "PublishUserActivities" -Value 0 -Type DWord
                    Set-ItemProperty -Path $path -Name "UploadUserActivities" -Value 0 -Type DWord
                }
                
                # Advertising ID
                $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Set-ItemProperty -Path $path -Name "Enabled" -Value 0 -Type DWord
                
                if ($isAdmin) {
                    $pathSystem = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
                    if (-not (Test-Path $pathSystem)) { New-Item -Path $pathSystem -Force | Out-Null }
                    Set-ItemProperty -Path $pathSystem -Name "DisabledByGroupPolicy" -Value 1 -Type DWord
                }
                
                # App Diagnostics
                $path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\appDiagnostics"
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
                Set-ItemProperty -Path $path -Name "Value" -Value "Deny" -Type String
                
                Write-Host "`nAll privacy tweaks applied successfully!" -ForegroundColor Green
                Write-Host "A system restart is recommended for full effect" -ForegroundColor Yellow
            } catch {
                Write-Host "Error applying tweaks: $_" -ForegroundColor Red
            }
            Pause
        }
        '7' {
            Write-Host "`nCurrent Privacy Settings:" -ForegroundColor Yellow
            Write-Host "=========================" -ForegroundColor Cyan
            
            $settings = @(
                @{Name="Telemetry"; Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Value="AllowTelemetry"},
                @{Name="Cortana"; Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Value="AllowCortana"},
                @{Name="Activity History"; Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Value="EnableActivityFeed"},
                @{Name="Advertising ID"; Path="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Value="Enabled"}
            )
            
            foreach ($setting in $settings) {
                try {
                    $value = Get-ItemProperty -Path $setting.Path -Name $setting.Value -ErrorAction Stop
                    $status = if ($value.$($setting.Value) -eq 0 -or $value.$($setting.Value) -eq "Deny") { "Disabled" } else { "Enabled" }
                    Write-Host "$($setting.Name): $status" -ForegroundColor $(if($status -eq 'Disabled'){'Green'}else{'Yellow'})
                } catch {
                    Write-Host "$($setting.Name): Default (not configured)" -ForegroundColor Gray
                }
            }
            
            # Check DiagTrack service
            $diagTrack = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
            if ($diagTrack) {
                Write-Host "Telemetry Service: $($diagTrack.Status) ($($diagTrack.StartType))" -ForegroundColor $(if($diagTrack.StartType -eq 'Disabled'){'Green'}else{'Yellow'})
            }
            
            Pause
        }
        'B' { break }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice.ToUpper() -ne 'B')
