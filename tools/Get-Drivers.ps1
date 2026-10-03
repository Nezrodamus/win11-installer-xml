# Fetch and extract the drivers listed in drivers\manifest.json.
# ASCII only - PowerShell 5.1 mangles non-ASCII in a BOM-less .ps1.
# No elevation needed.
#
# Point: stop hand-maintaining a driver folder. Entries with a url are
# downloaded and extracted; entries without one are printed as a to-do list
# with a hint on where to get them, because some vendors' links rotate too
# often to hardcode and a dead hardcoded link is worse than an honest blank.
#
# Everything lands under drivers\<brand>\<name>\, which Inject-Drivers.ps1
# already finds because its resolver recurses.
[CmdletBinding()]
param(
    [string] $ManifestPath,
    [string] $DriversRoot,
    [string] $Only       = "",      # fetch one entry by name
    [string] $Class      = "",      # or everything in one class: network, storage, input, chipset
    [switch] $Verify,               # HEAD-check urls, download nothing
    [switch] $Force                 # re-download even if already extracted
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $ManifestPath) { $ManifestPath = Join-Path $root "drivers\manifest.json" }
if (-not $DriversRoot)  { $DriversRoot  = Join-Path $root "drivers" }

if (-not (Test-Path $ManifestPath)) { throw "manifest not found: $ManifestPath" }
$manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

$sevenZip = "C:\Program Files\7-Zip\7z.exe"
$have7z   = Test-Path $sevenZip

$entries = $manifest.drivers
if ($Only)  { $entries = $entries | Where-Object { $_.name  -eq $Only  } }
if ($Class) { $entries = $entries | Where-Object { $_.class -eq $Class } }
if (-not $entries) { Write-Host "  nothing matched"; exit 0 }

# ----------------------------------------------------------------
#  Verify mode - just check the links are alive
# ----------------------------------------------------------------
if ($Verify) {
    Write-Host ""
    Write-Host "  checking manifest urls (no downloads)"
    Write-Host ""
    foreach ($d in $entries) {
        if (-not $d.url) { Write-Host ("  {0,-22} {1}" -f $d.name, "no url - manual, see searchHint"); continue }
        try {
            $r = Invoke-WebRequest -Uri $d.url -Method Head -UseBasicParsing -TimeoutSec 20
            $mb = if ($r.Headers.'Content-Length') { [math]::Round([int64]$r.Headers.'Content-Length'/1MB,1) } else { "?" }
            Write-Host ("  {0,-22} OK   HTTP {1}, {2} MB" -f $d.name, $r.StatusCode, $mb) -ForegroundColor Green
        } catch {
            Write-Host ("  {0,-22} DEAD {1}" -f $d.name, $_.Exception.Message.Split([char]10)[0]) -ForegroundColor Red
        }
    }
    Write-Host ""
    exit 0
}

# ----------------------------------------------------------------
#  Fetch + extract
# ----------------------------------------------------------------
$got = 0; $skipped = 0; $manual = @(); $failed = @()

foreach ($d in $entries) {
    $dest = Join-Path $DriversRoot (Join-Path $d.brand $d.name)

    if (-not $d.url) {
        $manual += $d
        continue
    }

    $infCount = 0
    if (Test-Path $dest) {
        $infCount = @(Get-ChildItem $dest -Filter *.inf -Recurse -ErrorAction SilentlyContinue).Count
    }
    if ($infCount -gt 0 -and -not $Force) {
        Write-Host ("  {0,-22} already have it ({1} .inf) - use -Force to refresh" -f $d.name, $infCount)
        $skipped++
        continue
    }

    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    $file = Join-Path $dest (Split-Path $d.url -Leaf)

    Write-Host ("  {0,-22} downloading..." -f $d.name)
    try {
        Invoke-WebRequest -Uri $d.url -OutFile $file -UseBasicParsing -TimeoutSec 600
    } catch {
        Write-Host ("  {0,-22} DOWNLOAD FAILED: {1}" -f $d.name, $_.Exception.Message.Split([char]10)[0]) -ForegroundColor Red
        $failed += $d.name
        continue
    }
    $mb = [math]::Round((Get-Item $file).Length/1MB,1)
    Write-Host ("  {0,-22} got {1} MB, extracting..." -f $d.name, $mb)

    if (-not $have7z) {
        Write-Host ("  {0,-22} 7-Zip not found - left the .exe in place, extract it yourself" -f $d.name) -ForegroundColor Yellow
        $failed += $d.name
        continue
    }

    # Extract with 7-Zip rather than running the vendor installer. We want the
    # .inf tree, not an install on this machine.
    $out = Join-Path $dest "extracted"
    & $sevenZip x $file ("-o" + $out) -y | Out-Null

    $infs = @(Get-ChildItem $out -Filter *.inf -Recurse -ErrorAction SilentlyContinue)
    if ($infs.Count -eq 0) {
        Write-Host ("  {0,-22} extracted but found no .inf - check it by hand" -f $d.name) -ForegroundColor Yellow
        $failed += $d.name
        continue
    }

    # If the manifest names a subdir (e.g. F6 for Intel RST), promote just that
    # one up to the entry folder. Injecting the whole vendor archive would pull
    # in installers and UWP bits that are not drivers.
    if ($d.extractSubdir) {
        $sub = Get-ChildItem $out -Directory -Recurse -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -eq $d.extractSubdir } | Select-Object -First 1
        if ($sub) {
            Copy-Item (Join-Path $sub.FullName '*') $dest -Recurse -Force
            Write-Host ("  {0,-22} promoted {1}\ ({2} files)" -f $d.name, $d.extractSubdir, @(Get-ChildItem $dest -File).Count) -ForegroundColor Green
        } else {
            Write-Host ("  {0,-22} subdir '{1}' not found in the archive" -f $d.name, $d.extractSubdir) -ForegroundColor Yellow
        }
    }

    Write-Host ("  {0,-22} OK - {1} .inf available" -f $d.name, $infs.Count) -ForegroundColor Green
    $got++
}

# ----------------------------------------------------------------
#  Report
# ----------------------------------------------------------------
Write-Host ""
Write-Host "  ---- $got fetched, $skipped already present, $($failed.Count) failed ----"

if ($manual.Count) {
    Write-Host ""
    Write-Host "  MANUAL - no stable url, fetch these yourself:" -ForegroundColor Yellow
    foreach ($d in $manual) {
        Write-Host ("    {0}  [{1}]" -f $d.name, $d.class) -ForegroundColor Yellow
        if ($d.searchHint) { Write-Host ("      {0}" -f $d.searchHint) -ForegroundColor DarkGray }
        Write-Host ("      drop the extracted .inf tree in: drivers\{0}\{1}\" -f $d.brand, $d.name) -ForegroundColor DarkGray
    }
}

# Coverage, by the two classes that actually matter.
Write-Host ""
Write-Host "  coverage in drivers\ right now:"
$allInf = @(Get-ChildItem $DriversRoot -Filter *.inf -Recurse -ErrorAction SilentlyContinue)
$classes = @{}
foreach ($inf in $allInf) {
    try { $t = Get-Content $inf.FullName -Raw -ErrorAction Stop } catch { continue }
    $m = [regex]::Match($t, '(?im)^\s*Class\s*=\s*([A-Za-z0-9_]+)')
    $k = if ($m.Success) { $m.Groups[1].Value } else { 'Unknown' }
    if (-not $classes.ContainsKey($k)) { $classes[$k] = 0 }
    $classes[$k]++
}
if ($classes.Count -eq 0) { Write-Host "    nothing yet" }
else { foreach ($k in ($classes.Keys | Sort-Object)) { Write-Host ("    {0,-16} {1}" -f $k, $classes[$k]) } }

$hasNet = $classes.ContainsKey('Net')
$hasSto = $classes.ContainsKey('HDC') -or $classes.ContainsKey('SCSIAdapter')
Write-Host ""
Write-Host ("    network driver present : {0}" -f $(if ($hasNet) { 'yes' } else { 'NO - a machine with no inbox WiFi will have no network at all' })) -ForegroundColor $(if ($hasNet) { 'Green' } else { 'Yellow' })
Write-Host ("    storage driver present : {0}" -f $(if ($hasSto) { 'yes' } else { 'NO - Setup may report no drives on Intel VMD machines' })) -ForegroundColor $(if ($hasSto) { 'Green' } else { 'Yellow' })
Write-Host ""
Write-Host "  next: .\tools\Inject-Drivers.ps1 -Index 6 -Split   (elevated)"
Write-Host ""
