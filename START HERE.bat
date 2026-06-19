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

REM Check it looks like a Windows installer USB
set "ISWIN="
if exist "!DRIVE!:\sources\install.wim" set "ISWIN=1"
if exist "!DRIVE!:\sources\install.esd" set "ISWIN=1"
if exist "!DRIVE!:\setup.exe" set "ISWIN=1"

if not defined ISWIN (
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
echo  %ACC%   [2]  Choose the name LATER%RST%
echo  %INF%        Windows will ask for the name while it installs, so%RST%
echo  %INF%        whoever sets up the computer can type it in then.%RST%
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
powershell -NoProfile -ExecutionPolicy Bypass -Command "if ([string]::IsNullOrWhiteSpace($env:ACCT) -or $env:ACCT.Length -gt 20 -or $env:ACCT -match '[\\/:*?<>|\[\];=,+]') { exit 1 } else { exit 0 }"
if errorlevel 1 (
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
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=(Get-Content -LiteralPath $env:SRCXML -Raw) -replace '<Name>User</Name>',('<Name>'+$env:ACCT+'</Name>') -replace '<DisplayName>User</DisplayName>',('<DisplayName>'+$env:ACCT+'</DisplayName>') -replace '<FullName>User</FullName>',('<FullName>'+$env:ACCT+'</FullName>'); [System.IO.File]::WriteAllText($env:DSTXML,$t,(New-Object System.Text.UTF8Encoding($false)))"

if not exist "!DSTXML!" (
    echo.
    echo  %ERR%  Oh no - something went wrong copying the file to the USB.%RST%
    echo  %ERR%  Please make sure the USB stick is plugged in and try%RST%
    echo  %ERR%  again.%RST%
    echo.
    pause
    exit /b 1
)
set "CHOSEN=the account will be named  !NAME!"
goto DONE


:LATER
REM Copy the prompt-during-install version to the USB
set "DSTXML=!DRIVE!:\autounattend.xml"
echo.
echo  %DIM%  Working on it...%RST%
copy /y "!HERE!autounattend_prompt-user.xml" "!DSTXML!" >nul

if not exist "!DSTXML!" (
    echo.
    echo  %ERR%  Oh no - something went wrong copying the file to the USB.%RST%
    echo  %ERR%  Please make sure the USB stick is plugged in and try%RST%
    echo  %ERR%  again.%RST%
    echo.
    pause
    exit /b 1
)
set "CHOSEN=Windows will ASK for the account name during install"
goto DONE


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
echo  %DIM%------------------------------------------------------------%RST%
echo  %INF%  Press any key to close this window. Have a great day^^!%RST%
pause >nul
endlocal
exit /b 0


:LISTDRIVES
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Volume | Where-Object {$_.DriveLetter} | Sort-Object DriveLetter | ForEach-Object { $d=$_.DriveLetter; $m=(Test-Path ('{0}:\sources\install.wim' -f $d)) -or (Test-Path ('{0}:\sources\install.esd' -f $d)) -or (Test-Path ('{0}:\setup.exe' -f $d)); [PSCustomObject]@{ 'Drive letter'=('  {0}' -f $d); 'Name'=$_.FileSystemLabel; 'Size (GB)'=[math]::Round($_.Size/1GB,1); 'Kind'=$_.DriveType; 'Windows USB?'=$(if($m){'YES <=== this one'}else{''}) } } | Format-Table -AutoSize | Out-String | Write-Host"
goto :eof
