# ADB-Extractor
Python tool to extract Private, Public and APK File from Android emulator or device using ADB.

## Requirements
- Python 3
- ADB
- Android Emulator or Device
- tar 
- gzip
- PysimpleGUI (optional)

## Installation

```bash
git clone 
cd ADB-Extractor
pip3 install -r requirements.txt
```

## GUI Usage

```bash
python3 adb_GUI.py
```

## Scripts Usage

```bash
adb shell pm path <package name>

# Trích xuất thư mục public:
adb pull /storage/emulated/0/Android/data/<package name> /path/to/save/public_data

# Trích xuất thư mục private(yêu cầu root):
adb shell su -c "cp -r /data/data/<package name> /path/to/save/private_data"

```

## OS
Tested on  Windows and MacOS.

## Credits

Script based on the work of @mfrade and is bash implementation https://github.com/labcif/AndroidAcquisitionScript .
