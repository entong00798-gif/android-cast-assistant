## 下载与运行（Windows）

**直接下载：** [点击下载 ZIP 压缩包](https://github.com/entong00798-gif/android-cast-assistant/archive/refs/heads/main.zip)。下载后解压文件夹，双击 `start.bat` 启动。

也可以在仓库页面点击绿色 **Code** 按钮，再点 **Download ZIP**。目前提供的是源码压缩包，不是 `.exe` 安装包。

首次启动需要联网下载官方 scrcpy。手机需要开启 USB 调试，并在手机弹窗中允许这台电脑调试。

# Android Cast Assistant

A small Windows desktop launcher for mirroring and controlling Android phones over USB. It uses the open-source [scrcpy](https://github.com/Genymobile/scrcpy) project and does not install an app on the phone.

## Requirements

- Windows 10 or 11
- Android 5.0 or later with USB debugging enabled
- A USB data cable
- Internet access on first launch to download the official Windows scrcpy release

## Start

Run `start.bat`. On first launch, the helper downloads scrcpy from the official Genymobile GitHub Releases API and caches it under `%LOCALAPPDATA%\Neo7Cast\scrcpy`. The scrcpy files are not bundled in this repository.

## Connect a phone

1. On the phone, open **Settings → About phone** and tap **Build number** or **Software version** seven times to enable Developer options. Menu names vary by manufacturer.
2. Open Developer options and enable **USB debugging**.
3. Connect the unlocked phone using a USB data cable. Approve the USB debugging prompt on the phone.
4. In the helper, click **Refresh devices**, select the phone, then click **Start mirroring**.

For HONOR phones, the Developer options menu is typically under **Settings → System & updates → Developer options**. If Windows does not detect the device, check the cable and USB port, then install the manufacturer's USB driver.

## Notes

- USB debugging grants this computer ADB access to the phone. Revoke the computer's authorization or turn USB debugging off when you no longer need it.
- Windows PowerShell 5.1 is used to display the desktop interface.
- Some manufacturer builds restrict ADB or require an additional USB setting.


