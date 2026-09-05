<#
.SYNOPSIS
    Bakes drivers into Windows 11 install media so they are present during
    Setup and on the installed machine, with no internet required.

.DESCRIPTION
    Windows 11 24H2 ships far fewer inbox drivers than older builds, and
    machines that were never certified for Windows 11 (older Dell, HP and
    Lenovo laptops) frequently come up with no network adapter at all. With
    no network there is no Windows Update, so there is no way to fetch the
    driver that would give you a network - a dead end that has to be solved
    before the install, not after.

    This mounts each image in install.wim, adds every driver found under the
    drivers folder, and commits. It also injects into boot.wim index 2
    (Windows Setup) so Setup itself can see storage and network hardware -
    without that, a machine whose disk controller needs a driver will show
    "no drives found" no matter what is in install.wim.

    Unsigned drivers are allowed via -ForceUnsigned, which is often required
    for older vendor drivers.

.PARAMETER MediaRoot
    Folder containing sources\install.wim. Defaults to ..\build\iso relative
    to this script.

.PARAMETER DriverPath
    Folder tree containing .inf drivers. Defaults to ..\drivers.

.PARAMETER Index
    Which install.wim indexes to inject into. Default is all of them.
    Injecting one index is much faster if you only deploy one edition -
    e.g. -Index 6 for Windows 11 Pro.

.PARAMETER SkipBootWim
    Skip boot.wim injection. Only safe if you know Setup can already see the
    disk and network on the target hardware.

.PARAMETER Split
    After injection, split install.wim into install*.swm under 4 GB so the
    media still fits on a FAT32 stick. Required for USB media.

.EXAMPLE
    .\Inject-Drivers.ps1 -Index 6 -Split
    Inject into Windows 11 Pro only, then re-split for FAT32.

.NOTES
    MUST run elevated - DISM image mounting requires administrator.
    Needs roughly 15 GB free for mount scratch space.
#>

[CmdletBinding()]
param(
    [string]  $MediaRoot,
    [string]  $DriverPath,
    [int[]]   $Index       = @(),
    [switch]  $SkipBootWim,
    [switch]  $ForceUnsigned,
    [switch]  $Split,
    [int]     $SplitSizeMB = 3800
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projRoot  = Split-Path -Parent $scriptDir

if (-not $MediaRoot)  { $MediaRoot  = Join-Path $projRoot 'build\iso' }
if (-not $DriverPath) { $DriverPath = Join-Path $projRoot 'drivers' }

$installWim = Join-Path $MediaRoot 'sources\install.wim'
$bootWim    = Join-Path $MediaRoot 'sources\boot.wim'
$mountDir   = Join-Path $projRoot  'build\_mount'
$log        = Join-Path $projRoot  'build\inject-drivers.log'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $line = "{0}  [{1}] {2}" -f (Get-Date -Format 'HH:mm:ss'), $Level, $Message
    Write-Host $line
    Add-Content -LiteralPath $log -Value $line -Encoding UTF8
}

# ------------------------------------------------------------------
#  Preflight
# ------------------------------------------------------------------
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "  ERROR: must run elevated. DISM cannot mount images otherwise." -ForegroundColor Red
    Write-Host "  Right-click Start -> Terminal (Admin), then re-run." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
Write-Log "=== driver injection starting ==="
Write-Log "media   : $MediaRoot"
Write-Log "drivers : $DriverPath"

if (-not (Test-Path -LiteralPath $installWim)) {
    Write-Log "install.wim not found at $installWim" 'FAIL'
    Write-Log "Run build\make-media.ps1 first - it converts install.esd to install.wim." 'FAIL'
    exit 1
}
if (-not (Test-Path -LiteralPath $DriverPath)) {
    Write-Log "driver folder not found: $DriverPath" 'FAIL'
    exit 1
}

$infs = @(Get-ChildItem -LiteralPath $DriverPath -Filter '*.inf' -Recurse -ErrorAction SilentlyContinue)
if ($infs.Count -eq 0) {
    Write-Log "no .inf files found under $DriverPath - nothing to inject." 'FAIL'
    Write-Log "Extract vendor driver packages there first (see drivers\README.txt)." 'FAIL'
    exit 1
}
Write-Log "found $($infs.Count) .inf files to inject"

# Clear any stale mount left by an interrupted run, or DISM refuses to mount.
Write-Log "clearing stale mount points"
& dism.exe /English /Cleanup-Mountpoints | Out-Null
if (Test-Path -LiteralPath $mountDir) { Remove-Item -LiteralPath $mountDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $mountDir | Out-Null

# ------------------------------------------------------------------
#  Inject into one image, always unmounting even on failure
# ------------------------------------------------------------------
function Add-DriversToImage {
    param([string]$WimPath, [int]$ImageIndex, [string]$Label)

    Write-Log "[$Label] mounting index $ImageIndex ..."
    & dism.exe /English /Mount-Image /ImageFile:"$WimPath" /Index:$ImageIndex /MountDir:"$mountDir" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "[$Label] mount FAILED (exit $LASTEXITCODE) - skipping this index" 'FAIL'
        return $false
    }

    $ok = $true
    try {
        # NOT $args - that is an automatic variable in PowerShell and
        # assigning to it inside a function breaks argument handling.
        $dismArgs = @('/English','/Image:' + $mountDir,'/Add-Driver','/Driver:' + $DriverPath,'/Recurse')
        if ($ForceUnsigned) { $dismArgs += '/ForceUnsigned' }
        $out = & dism.exe @dismArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Log "[$Label] Add-Driver returned exit $LASTEXITCODE" 'WARN'
            $out | Select-Object -Last 6 | ForEach-Object { Write-Log "    $_" 'WARN' }
            $ok = $false
        } else {
            $added = ($out | Select-String -Pattern 'Installing \d+ of' | Measure-Object).Count
            Write-Log "[$Label] injected drivers into index $ImageIndex (packages processed: $added)"
        }
    }
    finally {
        # Commit even on partial failure so a good subset still lands; a
        # discard here would silently throw away work and leave the image
        # mounted, which then blocks every later run.
        Write-Log "[$Label] committing and unmounting ..."
        & dism.exe /English /Unmount-Image /MountDir:"$mountDir" /Commit | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Log "[$Label] unmount FAILED (exit $LASTEXITCODE)" 'FAIL'
            Write-Log "Run: dism /Cleanup-Mountpoints   before trying again." 'FAIL'
            $ok = $false
        }
    }
    return $ok
}

# ------------------------------------------------------------------
#  install.wim
# ------------------------------------------------------------------
if ($Index.Count -eq 0) {
    $info = & dism.exe /English /Get-ImageInfo /ImageFile:"$installWim"
    $Index = @($info | Select-String -Pattern '^Index : (\d+)' |
                ForEach-Object { [int]$_.Matches[0].Groups[1].Value })
    Write-Log "no -Index given, injecting into all $($Index.Count): $($Index -join ', ')"
    Write-Log "TIP: -Index 6 (Pro) alone is much faster if that is all you deploy"
}

$failed = @()
foreach ($i in $Index) {
    if (-not (Add-DriversToImage -WimPath $installWim -ImageIndex $i -Label 'install.wim')) {
        $failed += "install.wim:$i"
    }
}

# ------------------------------------------------------------------
#  boot.wim index 2 (Windows Setup)
# ------------------------------------------------------------------
if (-not $SkipBootWim) {
    if (Test-Path -LiteralPath $bootWim) {
        # Index 2 is Windows Setup, the environment that enumerates disks and
        # network during install. Index 1 is plain WinPE and is not used here.
        if (-not (Add-DriversToImage -WimPath $bootWim -ImageIndex 2 -Label 'boot.wim')) {
            $failed += 'boot.wim:2'
        }
    } else {
        Write-Log "boot.wim not found, skipping" 'WARN'
    }
}

# ------------------------------------------------------------------
#  Re-split for FAT32
# ------------------------------------------------------------------
if ($Split) {
    $wimGB = [math]::Round((Get-Item -LiteralPath $installWim).Length / 1GB, 2)
    Write-Log "install.wim is $wimGB GB, splitting into <${SplitSizeMB}MB parts for FAT32"
    Get-ChildItem -LiteralPath (Split-Path $installWim) -Filter 'install*.swm' -ErrorAction SilentlyContinue |
        Remove-Item -Force
    $swm = Join-Path (Split-Path $installWim) 'install.swm'
    & dism.exe /English /Split-Image /ImageFile:"$installWim" /SWMFile:"$swm" /FileSize:$SplitSizeMB | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "split FAILED (exit $LASTEXITCODE)" 'FAIL'
        $failed += 'split'
    } else {
        Get-ChildItem -LiteralPath (Split-Path $installWim) -Filter 'install*.swm' | ForEach-Object {
            $sz = [math]::Round($_.Length / 1GB, 2)
            $fat = if ($_.Length -lt 4294967295) { 'OK for FAT32' } else { 'TOO BIG FOR FAT32' }
            Write-Log "  $($_.Name)  $sz GB  $fat"
        }
    }
}

Remove-Item -LiteralPath $mountDir -Recurse -Force -ErrorAction SilentlyContinue

if ($failed.Count -gt 0) {
    Write-Log "=== FINISHED WITH PROBLEMS: $($failed -join ', ') ===" 'FAIL'
    exit 1
}
Write-Log "=== done ==="
Write-Log "Now copy $MediaRoot to the USB stick and add autounattend.xml."
exit 0
