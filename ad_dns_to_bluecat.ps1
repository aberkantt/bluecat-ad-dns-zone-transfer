$zonesToExport = (Get-DnsServerZone | Where-Object { $_.ZoneType -eq "Primary" -and $_.IsReverseLookupZone -eq $false }).ZoneName


$exportBase = "C:\DNS_Exports_BlueCat"

if (!(Test-Path $exportBase)) {
    New-Item -Path $exportBase -ItemType Directory | Out-Null
}

function Get-DefaultTargetForSRV($zoneName) {
    try {
        return (Get-ADDomainController -Discover -ErrorAction Stop).HostName
    }
    catch {
        $arec = Get-DnsServerResourceRecord -ZoneName $zoneName |
                Where-Object { $_.RecordType -eq "A" -and $_.HostName -eq "@" }

        if ($arec) {
            return ($arec.RecordData.IPv4Address.IPAddressToString)
        }

        return "unknown.$zoneName"
    }
}

foreach ($zoneName in $zonesToExport) {

    $dcTarget = Get-DefaultTargetForSRV $zoneName

    Write-Host "`nExporting: $zoneName" -ForegroundColor Cyan

    $records = Get-DnsServerResourceRecord -ZoneName $zoneName -ErrorAction SilentlyContinue
    if (!$records) { continue }

    $lines = @()

    foreach ($record in $records) {

        $name = if ($record.HostName -eq "") { "@" } else { $record.HostName }
        $ttl  = [int]$record.TimeToLive.TotalSeconds
        $type = $record.RecordType
        $rdata = ""

        switch ($type) {

            "SOA" { continue }

            "A" {
                $rdata = $record.RecordData.IPv4Address.ToString()
            }

            "AAAA" {
                $rdata = $record.RecordData.IPv6Address.ToString()
            }

            "NS" {
                $rdata = $record.RecordData.NameServer.TrimEnd(".")
            }

            "CNAME" {
                $rdata = $record.RecordData.HostNameAlias.TrimEnd(".")
            }

            "TXT" {
                $rdata = ($record.RecordData.DescriptiveText -join " ")
            }

            "MX" {
                $priority = $record.RecordData.Preference
                $exchange = $record.RecordData.MailExchange.TrimEnd(".")
                $rdata = "$priority $exchange"
            }

            "SRV" {
                $priority = $record.RecordData.Priority
                $weight   = $record.RecordData.Weight
                $port     = $record.RecordData.Port
                $target   = $record.RecordData.DomainNameTarget

                if (!$target -or $target -eq "") {
                    $target = $dcTarget
                }

                $target = $target.TrimEnd(".")

                $rdata = "$priority $weight $port $target"
            }

        }

        if ($rdata -eq "") { continue }

        $lines += "add,$name,$ttl,$type,$rdata"
    }

    $outfile = "$exportBase\bulk_$zoneName.csv"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($outfile, $lines, $utf8NoBom)

    Write-Host "✔ Exported $outfile" -ForegroundColor Green
}
