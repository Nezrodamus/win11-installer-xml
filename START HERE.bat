@echo off
setlocal EnableExtensions

REM ============================================================
REM  Windows 11 Easy Install USB Helper
REM  Double-click this file. It will walk you through everything.
REM ============================================================

REM Capture this script's folder BEFORE turning on delayed expansion,
REM so folder names containing "!" are preserved correctly.
set "HERE=%~dp0"
setlocal EnableDelayedExpansion

REM --- Turn on colored text (works on Windows 10 and 11) ---
for /F %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RST=%ESC%[0m"
set "TTL=%ESC%[96m"
set "OK=%ESC%[92m"
set "WRN=%ESC%[93m"
set "ERR=%ESC%[91m"
set "INF=%ESC%[97m"
set "ACC=%ESC%[95m"
set "DIM=%ESC%[90m"

REM --- Session log, written next to this script ---
for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "STAMP=%%a"
if not defined STAMP set "STAMP=nodate"
set "LOGFILE=!HERE!StartHere_!STAMP!.log"
>"!LOGFILE!" echo === Windows 11 Easy Install USB Helper ===
call :LOG "Session started"
REM NOTE: paths built from HERE can contain "!" (this folder does).
REM Never pass those through "call" - call re-parses its arguments and
REM would eat them. Write them straight to the log instead.
>>"!LOGFILE!" echo [%DATE% %TIME%] Script folder: !HERE!

title  Windows 11  -  Easy Install USB Helper


:WELCOME
cls
echo.
echo  %TTL%============================================================%RST%
echo  %TTL%                                                            %RST%
echo  %TTL%        WINDOWS 11  -  EASY INSTALL USB HELPER              %RST%
echo  %TTL%                                                            %RST%
echo  %TTL%============================================================%RST%
echo.
echo  %INF%Hi there^^! This little helper gets your USB stick ready%RST%
echo  %INF%to install Windows 11 on a computer.%RST%
echo.
echo  %INF%You do NOT need to be a computer expert. Just read each%RST%
echo  %INF%screen and follow along. We will go one tiny step at a%RST%
echo  %INF%time, and nothing bad can happen if you take your time.%RST%
echo.
echo  %DIM%  What we are going to do:%RST%
echo  %DIM%   1. Make sure your Windows USB stick is plugged in.%RST%
echo  %DIM%   2. Pick which USB stick it is.%RST%
echo  %DIM%   3. Decide if you want to name the account now or later.%RST%
echo  %DIM%   4. Drop the magic setup file onto the USB. Done^^!%RST%
echo.
echo  %WRN%  Before we start: did you already make this USB stick%RST%
echo  %WRN%  using Microsoft's Media Creation Tool? If not, please%RST%
echo  %WRN%  read the README first and do that part first.%RST%
echo.
echo  %DIM%------------------------------------------------------------%RST%
echo  %INF%  Press any key when you are ready to begin...%RST%
pause >nul


:STEP1
cls
echo.
echo  %TTL%  STEP 1 of 4   -   Plug in your USB stick%RST%
echo  %TTL%------------------------------------------------------------%RST%
echo.
echo  %INF%  Take your Windows 11 USB stick (the one you made with the%RST%
echo  %INF%  Media Creation Tool) and plug it into this computer now.%RST%
echo.
echo  %INF%  If it is already plugged in, that is perfect too.%RST%
echo.
echo  %DIM%  Tip: it is the USB stick that has the Windows installer%RST%
echo  %DIM%  on it - NOT a regular empty memory stick.%RST%
echo.
echo  %DIM%------------------------------------------------------------%RST%
echo  %INF%  Press any key once your USB stick is plugged in...%RST%
pause >nul


:STEP2
cls
echo.
echo  %TTL%  STEP 2 of 4   -   Which drive is your USB stick?%RST%
echo  %TTL%------------------------------------------------------------%RST%
echo.
echo  %INF%  Below is a list of the drives on this computer. Look for%RST%
echo  %INF%  your USB stick. The one that says %OK%YES%INF% in the last column%RST%
echo  %INF%  is almost certainly the Windows USB stick you want.%RST%
echo.
call :LISTDRIVES
echo.
echo  %DIM%  (A drive "letter" is just one letter like E, F or G.)%RST%
echo.

:ASKDRIVE
echo.
set "INPUT="
set /p "INPUT=%ACC%  Type the drive letter of your USB stick and press Enter: %RST%"
if not defined INPUT goto ASKDRIVE
set "DRIVE=!INPUT:~0,1!"

REM Make sure that drive actually exists
if not exist "!DRIVE!:\" (
    echo.
    echo  %ERR%  Hmm, I could not find a drive called !DRIVE!.%RST%
    echo  %WRN%  Please look at the list again and type just the letter.%RST%
    goto ASKDRIVE
)

REM Check it looks like a Windows installer USB.
REM install.swm is what you get on FAT32 sticks, where the image is
REM split because FAT32 cannot hold a single file over 4 GB.
set "ISWIN="
if exist "!DRIVE!:\sources\install.wim" set "ISWIN=1"
if exist "!DRIVE!:\sources\install.esd" set "ISWIN=1"
if exist "!DRIVE!:\sources\install.swm" set "ISWIN=1"
if exist "!DRIVE!:\setup.exe" set "ISWIN=1"

call :LOG "Drive chosen: !DRIVE!  (looks like Windows media: !ISWIN!)"

if not defined ISWIN (
    call :LOG "WARNING: drive !DRIVE! does not look like Windows installer media"
    echo.
    echo  %WRN%  Warning: drive !DRIVE! does not look like a Windows%RST%
    echo  %WRN%  installer USB. I did not find the Windows setup files%RST%
    echo  %WRN%  on it.%RST%
    echo.
    echo  %INF%  If you are SURE this is the right USB stick, you can%RST%
    echo  %INF%  keep going. Otherwise pick a different letter.%RST%
    echo.
    choice /c YN /n /m "  Use drive !DRIVE! anyway?  (Y = yes,  N = pick again): "
    if errorlevel 2 goto ASKDRIVE
)

echo.
echo  %OK%  Great^^! We will use drive !DRIVE! for your USB stick.%RST%
echo.
echo  %DIM%  Press any key to continue...%RST%
pause >nul


:STEP3
cls
echo.
echo  %TTL%  STEP 3 of 4   -   The account name%RST%
echo  %TTL%------------------------------------------------------------%RST%
echo.
echo  %INF%  Every Windows computer has a user account (this is the%RST%
echo  %INF%  name that shows up when you log in).%RST%
echo.
echo  %INF%  You have two easy choices:%RST%
echo.
echo  %ACC%   [1]  Choose the name NOW%RST%
echo  %INF%        I will type in the name and Windows will set it up%RST%
echo  %INF%        all by itself with no questions during install.%RST%
echo.
echo  %ACC%   [2]  Choose the name LATER    %WRN%(no longer works)%RST%
echo  %INF%        Windows used to ask for the name during install.%RST%
echo  %WRN%        Current Windows 11 builds removed that screen, so%RST%
echo  %WRN%        this now fails after the install finishes. Pick [1].%RST%
echo.
echo  %DIM%------------------------------------------------------------%RST%
echo.
choice /c 12 /n /m "  Type 1 or 2 and press Enter: "
if errorlevel 2 goto LATER
goto NOWNAME


:NOWNAME
cls
echo.
echo  %TTL%  STEP 3 of 4   -   Type the account name%RST%
echo  %TTL%------------------------------------------------------------%RST%
echo.
echo  %INF%  What should the account be called? This is usually a%RST%
echo  %INF%  first name, like  Sarah  or  Grandpa  or  Office.%RST%
echo.
echo  %DIM%  Please use plain letters and numbers (no symbols).%RST%
echo.

:ASKNAME
set "NAME="
set /p "NAME=%ACC%  Type the account name and press Enter: %RST%"
if not defined NAME (
    echo  %WRN%  Please type a name first.%RST%
    goto ASKNAME
)
set "ACCT=!NAME!"
REM Whitelist rather than blacklist: letters, digits, space, _ and -,
REM starting with a letter or digit. This also keeps out characters that
REM are legal in a Windows name but would break the XML (notably "&").
powershell -NoProfile -ExecutionPolicy Bypass -Command "if ([string]::IsNullOrWhiteSpace($env:ACCT) -or $env:ACCT.Length -gt 20 -or $env:ACCT -notmatch '^[A-Za-z0-9][A-Za-z0-9 _-]*$') { exit 1 } else { exit 0 }"
if errorlevel 1 (
    call :LOG "Rejected account name (invalid characters or too long)"
    echo  %WRN%  That name has characters Windows does not allow, or it%RST%
    echo  %WRN%  is too long. Please try a simpler name - letters and%RST%
    echo  %WRN%  numbers, up to 20 characters.%RST%
    goto ASKNAME
)

echo.
echo  %INF%  You chose the name:  %OK%!NAME!%RST%
echo.
choice /c YN /n /m "  Is that correct?  (Y = yes,  N = type it again): "
if errorlevel 2 goto NOWNAME

REM Build the setup file with the chosen name and copy to the USB
set "SRCXML=!HERE!autounattend_predefined-user.xml"
set "DSTXML=!DRIVE!:\autounattend.xml"
echo.
echo  %DIM%  Working on it...%RST%
call :LOG "Mode: name now"
>>"!LOGFILE!" echo [%DATE% %TIME%] Source: !SRCXML!
call :LOG "Writing to: !DSTXML!"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$enc=New-Object System.Text.UTF8Encoding($false); $t=[System.IO.File]::ReadAllText($env:SRCXML,$enc) -replace '<Name>User</Name>',('<Name>'+$env:ACCT+'</Name>') -replace '<DisplayName>User</DisplayName>',('<DisplayName>'+$env:ACCT+'</DisplayName>') -replace '<FullName>User</FullName>',('<FullName>'+$env:ACCT+'</FullName>'); [System.IO.File]::WriteAllText($env:DSTXML,$t,$enc)"

if not exist "!DSTXML!" (
    call :LOG "FAILED: file was not created on the USB"
    goto WRITEFAIL
)

REM Verify what actually landed on the USB: it must parse as XML and it
REM must contain the name we asked for. Existing-file is not good enough.
echo  %DIM%  Checking the file on the USB...%RST%
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $raw=[System.IO.File]::ReadAllText($env:DSTXML,(New-Object System.Text.UTF8Encoding($false))); $null=[xml]$raw; if ($raw -notmatch [regex]::Escape('<Name>'+$env:ACCT+'</Name>')) { exit 2 }; if ($env:ACCT -ne 'User' -and $raw -match '<Name>User</Name>') { exit 2 }; exit 0 } catch { exit 3 }"
if errorlevel 1 (
    call :LOG "FAILED: verification of !DSTXML! did not pass"
    goto VERIFYFAIL
)
call :LOG "Verified OK: valid XML and account name is !NAME!"
set "CHOSEN=the account will be named  !NAME!"
goto DONE


:LATER
REM ------------------------------------------------------------------
REM  This branch deploys autounattend_prompt-user.xml, which relies on
REM  OOBE showing a local-account creation page after the online-account
REM  screens are hidden. Microsoft removed that fall-through: bypassnro
REM  went away in 26100.3775, and the local-account paths were closed
REM  further after that. Observed failure: install completes, reboots,
REM  then OOBE dies with "Windows could not complete the installation."
REM  Confirmed on 26100.8037 (24H2) and 26200.9168 (25H2), Sept 2026.
REM  Kept behind a warning rather than deleted, in case a future build
REM  or an older ISO restores the behaviour.
REM ------------------------------------------------------------------
cls
echo.
echo  %WRN%============================================================%RST%
echo  %WRN%   WARNING - this option does not work on current Windows%RST%
echo  %WRN%============================================================%RST%
echo.
echo  %INF%  Windows 11 removed the "create a local account" screen that%RST%
echo  %INF%  this option depends on. The install will run all the way%RST%
echo  %INF%  through, reboot a few times, and then stop with:%RST%
echo.
echo  %ERR%     "Windows could not complete the installation.%RST%
echo  %ERR%      To install Windows on this computer, restart the%RST%
echo  %ERR%      installation."%RST%
echo.
echo  %INF%  Confirmed on builds 26100.8037 and 26200.9168.%RST%
echo.
echo  %OK%  Choosing the name NOW avoids this completely - the account%RST%
echo  %OK%  is created by the setup file instead of by Windows.%RST%
echo.
echo  %DIM%------------------------------------------------------------%RST%
echo.
choice /c YN /n /m "  Use it anyway?  (Y = yes,  N = go back and name it now): "
if errorlevel 2 goto NOWNAME
call :LOG "WARNING: operator chose name-later despite the OOBE warning"

REM Copy the prompt-during-install version to the USB
set "DSTXML=!DRIVE!:\autounattend.xml"
echo.
echo  %DIM%  Working on it...%RST%
call :LOG "Mode: name later"
>>"!LOGFILE!" echo [%DATE% %TIME%] Source: !HERE!autounattend_prompt-user.xml
call :LOG "Writing to: !DSTXML!"
copy /y "!HERE!autounattend_prompt-user.xml" "!DSTXML!" >nul

if not exist "!DSTXML!" (
    call :LOG "FAILED: file was not created on the USB"
    goto WRITEFAIL
)

REM Same verification as the other branch: must parse as XML, and must
REM still contain the OOBE block that skips the Microsoft account screens.
echo  %DIM%  Checking the file on the USB...%RST%
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $raw=[System.IO.File]::ReadAllText($env:DSTXML,(New-Object System.Text.UTF8Encoding($false))); $null=[xml]$raw; if ($raw -notmatch 'HideOnlineAccountScreens') { exit 2 }; exit 0 } catch { exit 3 }"
if errorlevel 1 (
    call :LOG "FAILED: verification of !DSTXML! did not pass"
    goto VERIFYFAIL
)
call :LOG "Verified OK: valid XML, Windows will prompt for the name"
set "CHOSEN=Windows will ASK for the name  (WARNING: known to fail on current builds)"
goto DONE


:WRITEFAIL
echo.
echo  %ERR%  Oh no - something went wrong copying the file to the USB.%RST%
echo  %ERR%  Please make sure the USB stick is plugged in and try%RST%
echo  %ERR%  again.%RST%
echo.
echo  %DIM%  Details were saved to:%RST%
echo  %ACC%  !LOGFILE!%RST%
echo.
pause
endlocal
exit /b 1


:VERIFYFAIL
echo.
echo  %ERR%  The file was copied, but it did not pass the check.%RST%
echo  %ERR%  Do NOT use this USB stick to install yet.%RST%
echo.
echo  %INF%  The setup file on drive !DRIVE! is either damaged or%RST%
echo  %INF%  incomplete. Try running this helper again. If it fails%RST%
echo  %INF%  twice, the USB stick may be faulty or write-protected.%RST%
echo.
echo  %DIM%  Details were saved to:%RST%
echo  %ACC%  !LOGFILE!%RST%
echo.
pause
endlocal
exit /b 2


:DONE
cls
echo.
echo  %OK%============================================================%RST%
echo  %OK%                                                            %RST%
echo  %OK%                  ALL DONE  -  SUCCESS^^!                     %RST%
echo  %OK%                                                            %RST%
echo  %OK%============================================================%RST%
echo.
echo  %INF%  Your USB stick on drive %OK%!DRIVE!%INF% is now ready.%RST%
echo.
echo  %INF%  - The setup file  %ACC%autounattend.xml%INF%  was placed on it.%RST%
echo  %INF%  - !CHOSEN!.%RST%
echo.
echo  %TTL%  What to do next:%RST%
echo  %INF%   1. Safely remove the USB stick from this computer.%RST%
echo  %INF%   2. Plug it into the computer you want Windows 11 on.%RST%
echo  %INF%   3. Turn that computer on and start it from the USB%RST%
echo  %INF%      stick (the README explains how if you are not sure).%RST%
echo  %INF%   4. Windows will install all by itself. Sit back^^!%RST%
echo.
echo  %DIM%  A record of this session was saved to:%RST%
echo  %ACC%  !LOGFILE!%RST%
echo.
echo  %DIM%------------------------------------------------------------%RST%
echo  %INF%  Press any key to close this window. Have a great day^^!%RST%
call :LOG "Session finished successfully"
pause >nul
endlocal
exit /b 0


:LISTDRIVES
powershell -NoProfile -ExecutionPolicy Bypass -Command "$o = Get-Volume | Where-Object {$_.DriveLetter} | Sort-Object DriveLetter | ForEach-Object { $d=$_.DriveLetter; $m=(Test-Path ('{0}:\sources\install.wim' -f $d)) -or (Test-Path ('{0}:\sources\install.esd' -f $d)) -or (Test-Path ('{0}:\sources\install.swm' -f $d)) -or (Test-Path ('{0}:\setup.exe' -f $d)); [PSCustomObject]@{ 'Drive letter'=('  {0}' -f $d); 'Name'=$_.FileSystemLabel; 'Size (GB)'=[math]::Round($_.Size/1GB,1); 'Kind'=$_.DriveType; 'Windows USB?'=$(if($m){'YES <=== this one'}else{''}) } } | Format-Table -AutoSize | Out-String; Write-Host $o; try { [System.IO.File]::AppendAllText($env:LOGFILE, $o) } catch {}"
goto :eof


:LOG
>>"!LOGFILE!" echo [%DATE% %TIME%] %~1
goto :eof
