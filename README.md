**Installing libimobiledevice**
The app relies on libimobiledevice to communicate with iOS devices. Follow these steps to install it:

Install Homebrew (if not already installed):
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

Install libimobiledevice:
brew install libimobiledevice

Verify Installation:
/opt/homebrew/bin/ideviceinfo --version

Using libimobiledevice with the App
The app uses libimobiledevice tools (idevice_id, ideviceinfo, idevicediagnostics) to fetch device information. Ensure the following:

Device Connection:

Connect your iPhone/iPad via USB.
Unlock the device and tap Trust when prompted.


Check Device Detection:

Run:/opt/homebrew/bin/idevice_id -l

**Launch the App:**
Clone the project from the Github
Open the project in Xcode and build/run (Cmd+R).
The app window shows:
Title: "iPhone USB Monitor"

Features:

Manual Refresh: Click Refresh or press Cmd+R to update immediately.
Remove Device: Click Remove on a device card to delete it (confirms via alert).
Clear All Devices: Click Clear All Devices to remove all stored devices (confirms via alert)


