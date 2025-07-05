Write-Host "Gathering all services is in progress, please wait..." -ForegroundColor Yellow

$serviceList = @()

# Get all services
$allServices = Get-Service

foreach ($svc in $allServices) {
    $displayName = $svc.DisplayName
    $svcName     = $svc.Name
    $status      = $svc.Status
    $path        = ""
    $startName   = ""
    $description = ""
    $publisher   = "Unknown"
    $isSuspicious = $false

    try {
        $serviceDetails = Get-CimInstance -ClassName Win32_Service -Filter "Name='$svcName'" -ErrorAction Stop
        $path        = $serviceDetails.PathName
        $startName   = $serviceDetails.StartName
        $description = $serviceDetails.Description
    }
    catch {
        $scOutput = sc.exe qc $svcName 2>$null
        foreach ($line in $scOutput) {
            if ($line -match "BINARY_PATH_NAME\s+:\s+(.+)") {
                $path = $matches[1].Trim()
            }
            if ($line -match "SERVICE_START_NAME\s+:\s+(.+)") {
                $startName = $matches[1].Trim()
            }
        }

        try {
            $svcObj = Get-WmiObject -Class Win32_Service -Filter "Name='$svcName'" -ErrorAction Stop
            $description = $svcObj.Description
        } catch {}
    }

    $exePath = ""

    if (![string]::IsNullOrWhiteSpace($path)) {
        if ($path.StartsWith('"')) {
            $exePath = $path -replace '^"([^"]+).*', '$1'
        } else {
            $exePath = $path.Split(" ")[0]
        }

        if (![string]::IsNullOrWhiteSpace($exePath) -and (Test-Path $exePath)) {
            try {
                $signature = Get-AuthenticodeSignature -FilePath $exePath
                $publisher = if ($signature.SignerCertificate) {
                    $signature.SignerCertificate.Subject -replace "^CN=", ""
                } else {
                    "Unsigned"
                }
            } catch {
                $publisher = "Error Reading Signature"
            }

            if (
                $publisher -eq "Unsigned" -or
                ($publisher -ne "Microsoft Windows" -and $publisher -notmatch "Microsoft") -or
                ($exePath -match "AppData|Temp|Users\\.*\\Downloads")
            ) {
                $isSuspicious = $true
            }
        } else {
            $publisher = "Executable Not Found"
        }
    } else {
        $publisher = "No Path"
    }

    $serviceList += [pscustomobject]@{
        DisplayName = $displayName
        Name        = $svcName
        Description = $description
        State       = $status
        StartName   = $startName
        PathName    = $path
        Publisher   = $publisher
        Suspicious  = $isSuspicious
    }
}

# Sort by DisplayName
$sortedList = $serviceList | Sort-Object DisplayName

# Show on screen
$sortedList | Format-Table -AutoSize

# Save to CSV (first pass)
$timestamp = Get-Date -Format "yyyy-MM-dd_hh_mm_ss_tt"
$csvPath = "$env:USERPROFILE\Desktop\ServicesList_$timestamp.csv"
$sortedList | Export-Csv -Path $csvPath -NoTypeInformation -Force

# === NOW: RE-READ CSV, ADD ROW NUMBERS, RESAVE ===
$finalList = @()
$i = 1
Import-Csv $csvPath | ForEach-Object {
    $row = $_ | Select-Object @{Name='#'; Expression={ $i } }, *
    $finalList += $row
    $i++
}

$finalList | Export-Csv -Path $csvPath -NoTypeInformation -Force

Write-Host "`nServices saved to $csvPath (with row numbers added)" -ForegroundColor Green
