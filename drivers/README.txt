================================================================
 DRIVERS - drop vendor drivers here to bake them into the USB
================================================================

WHY THIS EXISTS
---------------
Windows 11 24H2 ships far fewer built-in drivers than older builds.
On machines that were never certified for Windows 11 - older Dell,
HP and Lenovo laptops - you often finish an install with no working
network adapter at all.

That is a dead end: no network means no Windows Update, and Windows
Update is where the missing network driver would have come from. It
has to be solved BEFORE the install, not after.

Anything you put in this folder gets baked into the USB, so the
drivers are already present during Setup and on the finished machine,
with no internet needed.


WHAT TO PUT HERE
----------------
Extracted driver folders containing .inf files. Subfolders are fine
and are searched recursively - organise however you like, e.g.

    drivers/
      dell-xps-9550/
        network/
          bcmwl63a.inf
          bcmwl63a.sys
        chipset/
      lenovo-t480/
        ...

WHAT WILL NOT WORK
------------------
  * .exe or .msi installers - these are setup programs, not drivers.
    Run them with an extract switch first, or use 7-Zip to unpack
    them, until you have .inf files.
  * .zip archives - extract them.
  * Drivers for the wrong Windows version or wrong architecture
    (must be x64).

If there is no .inf, it cannot be injected.


GETTING DRIVERS
---------------
Dell     https://www.dell.com/support  - enter the Service Tag
HP       https://support.hp.com
Lenovo   https://pcsupport.lenovo.com
Intel    https://www.intel.com/content/www/us/en/download-center/
Realtek  https://www.realtek.com/downloads

For machines with no Windows 11 driver listed, the Windows 10 x64
driver almost always works. Grab that.

Priority order - what actually matters:
  1. Network / WiFi   (without this the machine cannot fetch anything else)
  2. Storage / SATA / RAID / NVMe   (without this Setup may not see the disk)
  3. Chipset
  4. Everything else - Windows Update handles these once online


HOW TO USE
----------
From an ADMIN terminal, in the project folder:

    .\tools\Inject-Drivers.ps1 -Split

That injects into every edition in install.wim plus boot.wim, then
re-splits for FAT32. It takes a while - there are 7 editions.

Much faster if you only deploy one edition:

    .\tools\Inject-Drivers.ps1 -Index 6 -Split     # 6 = Windows 11 Pro

For older vendor drivers that fail signature checks:

    .\tools\Inject-Drivers.ps1 -Index 6 -Split -ForceUnsigned

Requires build\iso to exist - run build\make-media.ps1 first, which
extracts the ISO and converts install.esd to install.wim.

A log is written to build\inject-drivers.log.


WHY BOOT.WIM TOO
----------------
The script injects into boot.wim index 2 (Windows Setup) as well as
install.wim. Without that, a machine whose disk controller needs a
driver shows "we couldn't find any drives" during Setup - and no
amount of drivers inside install.wim helps, because Setup cannot get
far enough to apply it.


IF SOMETHING GOES WRONG
-----------------------
If a run is interrupted, an image may be left mounted, and every
later run will fail to mount. Clear it with:

    dism /Cleanup-Mountpoints

Then re-run.

This folder's contents are gitignored - vendor driver blobs are large
and are not ours to redistribute. Only this README is tracked.
