# Windows 11 — Easy Install USB Helper

This makes installing Windows 11 **really simple**. You plug in a USB stick,
double-click one file, answer two easy questions, and your USB is ready to
install a clean copy of Windows 11 on a computer.

You do **not** need to be a computer person to use this. If you can plug in a
USB stick and read a few screens, you can do this. 🙂

---

## What this actually does

When you run the helper, it copies a special setup file called
`autounattend.xml` onto your Windows USB stick. That file tells Windows 11 to:

- **Install itself automatically** — almost no clicking during setup.
- **Skip the Microsoft Account nag** — it makes a normal *local* account
  (you can still sign into the Store, Office, etc. afterward).
- **Work on older computers** — it turns off the TPM / Secure Boot / CPU / RAM
  checks that normally block Windows 11.
- **Come out clean** — it removes a lot of the junk apps and ads that Windows
  ships with, and turns off most of the tracking/telemetry.

---

## What you need

1. A **USB stick** that is at least **8 GB** (it will be erased, so don't use
   one with important files on it).
2. The **computer** you want to put Windows 11 on.
3. About 20–30 minutes.

---

## Step 1 — Make the Windows USB stick (do this first)

> ⚠️ This step erases the USB stick and puts the Windows installer on it.
> You only do this once.

1. Go to Microsoft's official page:
   **https://www.microsoft.com/software-download/windows11**
2. Under **"Create Windows 11 Installation Media"**, click **Download Now**.
   This downloads a small program called the **Media Creation Tool**.
3. Plug in your USB stick.
4. Run the Media Creation Tool. When it asks, choose **USB flash drive** and
   pick your USB stick from the list.
5. Let it finish. When it's done, your USB stick has Windows 11 on it.

*(If you prefer, the tool Rufus also works — but the Media Creation Tool is the
easiest official option.)*

---

## Step 2 — Download this helper

On this page (GitHub), click the green **`< > Code`** button near the top, then
click **Download ZIP**. Save it and **unzip / extract** it somewhere easy, like
your Desktop.

You should now have a folder containing:

- **`START HERE.bat`**  ← the file you double-click
- `autounattend_predefined-user.xml`
- `autounattend_prompt-user.xml`
- this README

---

## Step 3 — Run the helper

1. Make sure your Windows USB stick (from Step 1) is plugged in.
2. Double-click **`START HERE.bat`**.
   - If Windows shows a blue **"Windows protected your PC"** box, click
     **More info → Run anyway**. (This happens for any downloaded `.bat` file;
     it's safe.)
3. Follow the colorful on-screen steps. It will:
   - Show you a list of drives and help you pick your USB stick.
   - Ask how you want to handle the **account name** (see below).
   - Copy the right setup file onto your USB. Done!

### The one real choice: the account name

The helper will ask you one important question:

- **Choose the name NOW** — You type a name (like *Sarah* or *Office*) and
  Windows sets everything up by itself, no questions asked during install.
- **Choose the name LATER** — Windows will ask for the name *while it installs*,
  so whoever is setting up the computer can type it in at that moment.

Either choice is fine — pick whatever is easier for you.

---

## Step 4 — Install Windows on the other computer

1. Safely unplug the USB stick from this computer.
2. Plug it into the computer you want Windows 11 on.
3. Turn that computer on and tell it to start from the USB stick:
   - As it powers on, tap the **boot menu key** repeatedly. It's usually
     **F12**, **F11**, **Esc**, or **F9** (it's often shown briefly on screen,
     e.g. *"Press F12 for boot menu"*). On many computers **F2** or **Del**
     opens BIOS settings where you can also pick the boot device.
   - Choose the **USB stick** from the list.
4. Windows 11 will install on its own. When it's finished you'll land on the
   desktop, clean and ready to go.

> ⚠️ Installing Windows this way **erases the target computer**. Make sure
> anything important on it is backed up first.

---

## Questions you might have

**Do I need to rename anything to `autounattend.xml` myself?**
No. The helper does that for you automatically.

**Will this hurt the computer I run the helper on?**
No. The helper only copies a small file onto your USB stick. It does not change
the computer you run it on.

**I picked the wrong USB drive — what now?**
Nothing bad happens; it just copies a small text file. Run the helper again and
pick the right drive.

**Can I run it again to change my choice?**
Yes. Just run `START HERE.bat` again and answer the questions differently. It
will overwrite the setup file on the USB.
