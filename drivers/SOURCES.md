# Common drivers — what to get, and what not to bother with

## The principle: don't build a kitchen sink

You do **not** need a comprehensive driver set in the image. You need exactly
enough to get the machine **on the network** and to let Setup **see the disk**.
Once Windows is online, Windows Update delivers everything else — GPU, audio,
touchpad, card reader, Bluetooth — usually better and newer than anything you'd
have injected.

Every driver you add costs injection time on *every* image index, and a wrong or
badly-signed driver can break an install that would otherwise have worked.

**Two tiers only:**

| Priority | Class | Why |
|---|---|---|
| 1 | **Network / WiFi / Ethernet** | Without it the machine can't fetch anything else. This is the whole ballgame. |
| 2 | **Storage — SATA / RAID / NVMe / VMD** | Without it Setup reports "we couldn't find any drives" and you never start. |
| — | Chipset | Occasionally needed on very old machines. Small, cheap to include. |
| ✗ | GPU, audio, Bluetooth, card reader, printers | Let Windows Update do these. Not worth the injection time or the risk. |

---

## Where to get them

Vendor download roots — deep links rot, so search from these:

| Vendor | URL | Search for |
|---|---|---|
| Dell | https://www.dell.com/support | Service Tag → Drivers → Network |
| HP | https://support.hp.com | Serial → Software and Drivers |
| Lenovo | https://pcsupport.lenovo.com | Serial → Drivers |
| Intel | https://www.intel.com/content/www/us/en/download-center/ | "Wi-Fi", "Ethernet", "Rapid Storage" |
| Realtek | https://www.realtek.com/downloads | "Ethernet", "Card Reader" |
| AMD | https://www.amd.com/en/support | Chipset |

**Where no Windows 11 driver is published, take the Windows 10 x64 one.** It
almost always works, and for machines never certified for Windows 11 it is the
only option that exists.

---

## The high-value set for a repair shop

These cover the large majority of machines that walk in:

### Network — get these first
- **Intel Wireless** — one package covers AC 3160/7260/7265/8260/8265/9560 and
  AX200/AX201/AX210. Intel Download Center → "Wi-Fi Drivers for Windows 10 and
  Windows 11". Single biggest win per megabyte.
- **Intel Ethernet** — I210 / I217 / I218 / I219 are on most business desktops
  and laptops. Intel Download Center → "Ethernet Adapter Complete Driver Pack".
- **Realtek Ethernet** — RTL8168 / 8111 / 8125. Extremely common on consumer
  desktops and budget laptops.
- **Broadcom / Dell DW15xx, DW18xx** — older Dell laptops. Only from Dell's site,
  by Service Tag. No Windows 11 versions exist; use the Windows 10 driver.
- **Qualcomm Atheros / Killer** — gaming laptops, some Dell and MSI.

### Storage — get these second
- **Intel Rapid Storage Technology (IRST / VMD)** — the single most useful
  storage driver. Needed when firmware is in RAID or VMD mode rather than AHCI,
  which is the **factory default on many Dell machines**. Without it Setup shows
  no disks at all. Intel Download Center → "Rapid Storage Technology driver".
- **AMD RAID** — only if you actually meet AMD systems in RAID mode.

### Chipset — cheap, include it
- Intel Chipset Device Software (INF Update Utility)
- AMD Chipset Drivers

---

## Extracting drivers from vendor installers

Injection needs `.inf` files. Most vendor downloads are `.exe` installers. To get
the `.inf` out:

```
7z x driver-installer.exe -odrivers\vendor-name\
```

7-Zip unpacks most of them. If that fails, try running the installer with an
extract switch (`/extract`, `-extract`, `/x`) — many vendor packagers support one.
If it installs on *this* machine instead, you can also pull the driver out of
`C:\Windows\System32\DriverStore\FileRepository\` afterwards.

**Verify before building:** `.\tools\Inject-Drivers.ps1` reports what driver
classes it found and warns if there is no network driver, so you'll know before
you spend twenty minutes injecting.

---

## A note on third-party driver packs

**Snappy Driver Installer Origin** (https://www.snappy-driver-installer.org) is
open source, reputable, and offers offline driver packs. It's a reasonable source
if you want breadth.

**Avoid DriverPack Solution** — it has a long history of bundling adware and
unwanted software, and it is not something to put in front of a customer machine.

Either way, be cautious about mass-injecting a whole pack. A focused set of
network and storage drivers is faster, safer, and solves the actual problem.
