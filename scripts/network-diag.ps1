# Network Diagnostics
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "        Network Diagnostics" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

do {
    Write-Host "  [1] Network Adapter Information"
    Write-Host "  [2] IP Configuration"
    Write-Host "  [3] Test Internet Connectivity"
    Write-Host "  [4] Trace Route to Google"
    Write-Host "  [5] Open TCP Connections"
    Write-Host "  [6] Speed Test (Ping various servers)"
    Write-Host "  [B] Back to Main Menu"
    Write-Host ""
    
    $choice = Read-Host "Select option"
    
    switch ($choice.ToUpper()) {
        '1' {
            Write-Host "`nNetwork Adapters:" -ForegroundColor Yellow
            Write-Host "=================" -ForegroundColor Cyan
            $adapters = Get-NetAdapter | Where-Object Status -eq 'Up'
            foreach ($adapter in $adapters) {
                Write-Host "Name: $($adapter.Name)" -ForegroundColor White
                Write-Host "Status: $($adapter.Status)" -ForegroundColor Green
                Write-Host "Speed: $($adapter.LinkSpeed)" -ForegroundColor Gray
                Write-Host "MAC: $($adapter.MacAddress)" -ForegroundColor Gray
                Write-Host "Driver: $($adapter.DriverVersion)" -ForegroundColor Gray
                Write-Host "---" -ForegroundColor DarkGray
            }
            Pause
        }
        '2' {
            Write-Host "`nIP Configuration:" -ForegroundColor Yellow
            Write-Host "================" -ForegroundColor Cyan
            $configs = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null }
            foreach ($config in $configs) {
                Write-Host "Interface: $($config.InterfaceAlias)" -ForegroundColor White
                Write-Host "IPv4: $($config.IPv4Address.IPAddress)" -ForegroundColor Green
                Write-Host "Gateway: $($config.IPv4DefaultGateway.NextHop)" -ForegroundColor Gray
                Write-Host "DNS Servers:" -ForegroundColor Gray
                foreach ($dns in $config.DNSServer) {
                    Write-Host "  - $($dns.ServerAddresses)" -ForegroundColor Gray
                }
                Write-Host "---" -ForegroundColor DarkGray
            }
            Pause
        }
        '3' {
            Write-Host "`nTesting Internet Connectivity..." -ForegroundColor Yellow
            $tests = @(
                @{Name="Google DNS"; Address="8.8.8.8"},
                @{Name="Cloudflare DNS"; Address="1.1.1.1"},
                @{Name="Google"; Address="google.com"},
                @{Name="Microsoft"; Address="microsoft.com"}
            )
            
            foreach ($test in $tests) {
                Write-Host "Testing $($test.Name)..." -ForegroundColor White -NoNewline
                $result = Test-Connection -ComputerName $test.Address -Count 2 -Quiet
                if ($result) {
                    Write-Host " SUCCESS" -ForegroundColor Green
                } else {
                    Write-Host " FAILED" -ForegroundColor Red
                }
            }
            Pause
        }
        '4' {
            Write-Host "`nTracing route to google.com..." -ForegroundColor Yellow
            Write-Host "=================================" -ForegroundColor Cyan
            try {
                $trace = Test-NetConnection -ComputerName google.com -TraceRoute
                Write-Host "Ping: $($trace.PingSucceeded)" -ForegroundColor $(if($trace.PingSucceeded){'Green'}else{'Red'})
                Write-Host "Latency: $($trace.Latency)ms" -ForegroundColor White
                Write-Host "`nHops:" -ForegroundColor Yellow
                $hopCount = 0
                foreach ($hop in $trace.TraceRoute) {
                    $hopCount++
                    Write-Host "$hopCount`: $hop" -ForegroundColor White
                }
            } catch {
                Write-Host "Error: $_" -ForegroundColor Red
            }
            Pause
        }
        '5' {
            Write-Host "`nActive TCP Connections:" -ForegroundColor Yellow
            Write-Host "=======================" -ForegroundColor Cyan
            $connections = Get-NetTCPConnection | Where-Object State -eq 'Established' | 
                Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, 
                @{Name="Process";Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Name}}
            
            foreach ($conn in $connections) {
                Write-Host "Local: $($conn.LocalAddress):$($conn.LocalPort)" -ForegroundColor White
                Write-Host "Remote: $($conn.RemoteAddress):$($conn.RemotePort)" -ForegroundColor Gray
                Write-Host "Process: $($conn.Process)" -ForegroundColor Gray
                Write-Host "---" -ForegroundColor DarkGray
            }
            Pause
        }
        '6' {
            Write-Host "`nSpeed Test (Ping Response Times):" -ForegroundColor Yellow
            Write-Host "=================================" -ForegroundColor Cyan
            $targets = @(
                @{Name="Local Gateway"; Address=(Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select -First 1).NextHop},
                @{Name="Google DNS"; Address="8.8.8.8"},
                @{Name="Cloudflare"; Address="1.1.1.1"},
                @{Name="AWS"; Address="amazon.com"},
                @{Name="Azure"; Address="azure.microsoft.com"}
            )
            
            foreach ($target in $targets) {
                if ($target.Address) {
                    Write-Host "Testing $($target.Name)..." -ForegroundColor White
                    $result = Test-Connection -ComputerName $target.Address -Count 4 | 
                        Measure-Object -Property ResponseTime -Average -Minimum -Maximum
                    
                    Write-Host "  Min: $($result.Minimum)ms" -ForegroundColor Gray
                    Write-Host "  Max: $($result.Maximum)ms" -ForegroundColor Gray
                    Write-Host "  Avg: $([math]::Round($result.Average, 2))ms" -ForegroundColor $(if($result.Average -lt 50){'Green'}elseif($result.Average -lt 100){'Yellow'}else{'Red'})
                    Write-Host ""
                }
            }
            Pause
        }
        'B' { break }
        default { Write-Host "Invalid option" -ForegroundColor Red; Start-Sleep 1 }
    }
} while ($choice.ToUpper() -ne 'B')
