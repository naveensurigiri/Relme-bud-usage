"""Adds Bluetooth permissions to the generated AndroidManifest.xml."""
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

permissions = """    <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
    <uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
    <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
"""

if "BLUETOOTH_SCAN" not in text:
    text = text.replace("<application", permissions + "    <application", 1)
    path.write_text(text, encoding="utf-8")
    print("Bluetooth permissions added")
else:
    print("Bluetooth permissions already present")
