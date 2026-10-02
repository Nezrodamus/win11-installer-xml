# Stamp a USB stick with a manifest of what is actually on it.
# ASCII only - PowerShell 5.1 mangles non-ASCII in a BOM-less .ps1.
# No elevation needed to write the marker; -SetLabel does need admin.
#
# Why: a numbered empty file tells you WHICH stick but not WHAT is on it.
# After a few builds nobody remembers whether #2 is 24H2 or 25H2, which
# answer file is live, or whether the cleanup toolkit is on there. This
# writes that in, generated from the stick itself so it cannot drift.
#
# The hardware serial is recorded too. It is the only identifier that
# survives a reformat - a label and a marker file both get wiped.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $DriveLetter,
    [Parameter(Mandatory)][int]    $Number,
    [string] $Note = "",
    [switch] $SetLabel
)

$ErrorActionPreference = "Stop"
$d = $DriveLetter.TrimEnd(':')
if (-not (Test-Path "${d}:\")) { throw "${d}: is not mounted" }

$vol  = Get-Volume -DriveLetter $d
$part = Get-Partition -DriveLetter $d -ErrorAction SilentlyContinue
$disk = if ($part) { Get-Disk -Number $part.DiskNumber }

# --- work out what is actually on it ---
$lines = @()
$lines += "================================================================"
$lines += " CTC USB #$Number"
$lines += "================================================================"
$lines += ""
if ($Note) { $lines += "  $Note"; $lines += "" }
$lines += "  stamped        : $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
$lines += "  hardware serial: $(if ($disk) { $disk.SerialNumber } else { 'unknown' })"
$lines += "  capacity       : $([math]::Round($vol.Size/1GB,2)) GB  ($([math]::Round($vol.SizeRemaining/1GB,2)) GB free)"
$lines += "  filesystem     : $($vol.FileSystem)  partition style: $(if ($disk) { $disk.PartitionStyle } else { '?' })"
$lines += ""
$lines += "  NOTE: the serial above survives a reformat. The label and this"
$lines += "  file do not. If a stick is rebuilt, match it by serial."
$lines += ""

# Windows install media?
if (Test-Path "${d}:\setup.exe") {
    $build = if (Test-Path "${d}:\sources\setuphost.exe") {
        (Get-Item "${d}:\sources\setuphost.exe").VersionInfo.FileVersion
    } else { "unknown" }
    $lines += "----------------------------------------------------------------"
    $lines += " WINDOWS INSTALL MEDIA"
    $lines += "----------------------------------------------------------------"
    $lines += "  build          : $build"
    $img = Get-ChildItem "${d}:\sources" -Filter "install*" -ErrorAction SilentlyContinue |
           Where-Object { $_.Extension -in '.wim','.esd','.swm' }
    foreach ($i in $img) { $lines += "  image          : $($i.Name)  $([math]::Round($i.Length/1GB,2)) GB" }
    $boot = @('efi\boot\bootx64.efi','bootmgr','boot\bcd') | Where-Object { Test-Path "${d}:\$_" }
    $lines += "  boot files     : $($boot.Count)/3 present$(if ($boot.Count -eq 3) { ' (UEFI + legacy)' })"

    # which answer file is live
    if (Test-Path "${d}:\autounattend.xml") {
        $raw = [System.IO.File]::ReadAllText("${d}:\autounattend.xml")
        $variant = if ($raw -match '<LocalAccount') { "predefined-user" } else { "prompt-user" }
        $acct = if ($raw -match '<Name>([^<]+)</Name>') { $Matches[1] } else { "(none)" }
        $lines += ""
        $lines += "  ACTIVE autounattend.xml"
        $lines += "    variant      : $variant"
        $lines += "    account      : $acct"
        if ($variant -eq "predefined-user") {
            $lines += "    behaviour    : fully hands-off, no prompts"
            $lines += "    WARNING      : blank password - set one before handover"
        } else {
            $lines += "    behaviour    : asks for the name during setup"
            $lines += "    needs        : click 'I don't have internet' then"
            $lines += "                   'Continue with limited setup'"
        }
    } else {
        $lines += ""
        $lines += "  ACTIVE autounattend.xml : NONE - fully manual install"
    }

    $alts = Get-ChildItem "${d}:\autounattend.*.xml" -ErrorAction SilentlyContinue
    if ($alts) {
        $lines += ""
        $lines += "  spare answer files (rename over autounattend.xml to use):"
        foreach ($a in $alts) { $lines += "    $($a.Name)" }
    }
    $lines += ""
}

# cleanup toolkit?
foreach ($folder in (Get-ChildItem "${d}:\" -Directory -Force -ErrorAction SilentlyContinue |
                     Where-Object { $_.Name -like '.CTC*' })) {
    $sc = Join-Path $folder.FullName 'WindowsCleanup.ps1'
    if (Test-Path $sc) {
        $lines += "----------------------------------------------------------------"
        $lines += " CLEANUP TOOLKIT : $($folder.Name)"
        $lines += "----------------------------------------------------------------"
        $lines += "  WindowsCleanup.ps1 : $((Get-Item $sc).Length) bytes, $((Get-Item $sc).LastWriteTime.ToString('yyyy-MM-dd'))"
        $inst = Join-Path $folder.FullName 'installs'
        if (Test-Path $inst) {
            $f = Get-ChildItem $inst -File -Recurse -ErrorAction SilentlyContinue
            $lines += "  installs\          : $($f.Count) files, $([math]::Round((($f | Measure-Object Length -Sum).Sum)/1GB,2)) GB"
        }
        $lines += "  run via            : $($folder.Name)\RunCleanup.cmd"
        $lines += ""
    }
}

# helper scripts sitting in the root
$helpers = Get-ChildItem "${d}:\*.cmd" -ErrorAction SilentlyContinue
if ($helpers) {
    $lines += "----------------------------------------------------------------"
    $lines += " HELPERS IN ROOT"
    $lines += "----------------------------------------------------------------"
    foreach ($h in $helpers) { $lines += "  $($h.Name)" }
    $lines += ""
}

$out = "${d}:\$Number.txt"
[System.IO.File]::WriteAllText($out, (($lines -join "`r`n") + "`r`n"), (New-Object System.Text.ASCIIEncoding))
Write-Host "  wrote $out  ($((Get-Item $out).Length) bytes)" -ForegroundColor Green

if ($SetLabel) {
    $label = "CTC-$Number"
    try {
        Set-Volume -DriveLetter $d -NewFileSystemLabel $label -ErrorAction Stop
        Write-Host "  label set to $label" -ForegroundColor Green
    } catch {
        Write-Host "  could not set label (needs elevation): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
