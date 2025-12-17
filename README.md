# **hypr-yubilock**

**hypr-yubilock** is a robust security tool for **Arch Linux** and **Hyprland** that automatically locks your session immediately upon removing your YubiKey.  
Unlike simple udev rules, it leverages systemd-run to interact securely with the user session, overcoming common Wayland/Udev limitations. It features a smart **Grace Period** (to prevent accidental lockouts) and a **Pause Mode** (for port usage/charging).

## **🚀 Features**

* **⚡ Instant Detection:** Hooks directly into Udev removal events.  
* **🛡️ Systemd Integration:** Safely launches hyprlock within the user session (avoiding environment issues).  
* **⏳ Smart Grace Period:** A configurable delay (default: 5s) allows you to remove and re-insert the key (or swap keys) without locking the screen.  
* **⏸️ Pause/Maintenance Mode:** A keyboard shortcut toggles the mechanism on/off, useful when you need the USB-C port for a charger.  
* **📝 Debug Logging:** Detailed logs available in /tmp/yubikey-debug.log.

## **📋 Prerequisites**

### **1\. Required Packages**

Ensure you have the necessary tools installed:
```
sudo pacman \-S yubikey-manager yubikey-personalization libnotify
```

### **2\. Enable USB Serial Visibility (Crucial)**

By default, YubiKeys often hide their unique serial number from the USB descriptor. udev requires this serial to distinguish your specific key.  
**Check if enabled:**  
```
lsusb \-v 2\>/dev/null | grep \-A 2 "Yubico" | grep iSerial  
```
\# Expected output: iSerial 3 12345678

If you see 0 or no serial number, enable it using ykpersonalize:  
\# Warning: This writes to the key configuration.  
```
ykpersonalize \-y \-o serial-usb-visible
```
*Repeat this for all YubiKeys you intend to use.*

## **⚙️ Installation**

### **1\. Identify Your Serial Numbers**

Run the monitor command and **remove** your YubiKey to capture the identifier:  
```
udevadm monitor \--environment \--udev | grep ID\_SERIAL\_SHORT
```
*Note down your numbers (e.g., 12345678).*

### **2\. Install Scripts**

Copy the scripts from this repository to your local binary path:  
```
sudo cp yubikey-lock.sh /usr/local/bin/  
sudo cp yubikey-toggle.sh /usr/local/bin/  
sudo chmod \+x /usr/local/bin/yubikey-lock.sh  
sudo chmod \+x /usr/local/bin/yubikey-toggle.sh
```

### **3\. Configure the Lock Script**

Open /usr/local/bin/yubikey-lock.sh and edit the configuration variables at the top:

* **TARGET\_USER**: Change this to your actual **Linux username**.  
* **ALLOWED\_SERIALS**: Add your serial numbers using Regex format (separated by pipes |).  
  * *Example:* ALLOWED\_SERIALS="11111111|22222222"

### **4\. Setup Udev Rules**

Copy the udev rule file from this repository:  
```
sudo cp 99-yubikey.rules /etc/udev/rules.d/
```

**Important:** Edit the file /etc/udev/rules.d/99-yubikey.rules and replace the placeholder serial numbers (YOUR\_PRIMARY\_SERIAL, etc.) with the actual ID\_SERIAL\_SHORT values you found in Step 1\.  
**Apply the changes:**  
```
sudo udevadm control \--reload-rules  
sudo udevadm trigger
```

### **5\. Hyprland Configuration**

Add a keybinding to \~/.config/hypr/hyprland.conf to use the Pause/Toggle feature:  
\# Toggle YubiKey Auto-Lock (Example: Super \+ Alt \+ Y)  
```
bind \= $mainMod ALT, Y, exec, /usr/local/bin/yubikey-toggle.sh
```

## **🎮 Usage**

### **Standard Behavior**

1. **Remove YubiKey.**  
2. A 5-second invisible timer starts.  
3. **If key is NOT returned:** The screen locks via hyprlock.  
4. **If key IS returned:** The lock is cancelled (Grace Period).

### **Pause Mode (Maintenance)**

Useful if you have limited ports and need to unplug the key to charge the laptop.

1. Press Super \+ Alt \+ Y (or your configured bind).  
2. **Notification:** "🔴 Auto-Lock PAUSED".  
3. You can now safely remove the key without locking the screen.  
4. Press the shortcut again to re-arm.  
5. **Notification:** "🟢 Auto-Lock ENABLED".

*Note: The pause state is reset (Security ON) automatically after a reboot.*

## **🔍 Troubleshooting**

If the lock isn't triggering, check the debug log:  
```
tail \-f /tmp/yubikey-debug.log
```

* **"User ... not logged in":** The script thinks the user session is not active. Double-check the TARGET\_USER variable in yubikey-lock.sh.  
* **Log file does not exist:** The Udev rule isn't triggering. Verify your serials in /etc/udev/rules.d/99-yubikey.rules and ensure you reloaded udev rules.  
* **"PAUSE ACTIVE":** The lock is currently paused. Press your shortcut to re-enable it.

## **License**

MIT License. See [LICENSE](https://github.com/B4b4u/hypr-yubilock/blob/main/LICENSE) file for details.
