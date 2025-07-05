# Windows Services Exporter

A PowerShell script that gathers all Windows services and exports them to a detailed, timestamped CSV file — including service name, description, path, startup user, digital signature publisher, and whether the service appears suspicious.

## 🔍 Features

- Export all installed Windows services to CSV
- Sorts results by service **DisplayName**
- Adds **row numbers** to each service
- Retrieves:
  - Service `Name` and `DisplayName`
  - Service `Description` and `State`
  - Executable `Path` and `StartName`
  - Publisher from **digital signature** of the executable
  - Flags services as **Suspicious** if:
    - Unsigned
    - Publisher is not Microsoft
    - Located in `AppData`, `Temp`, or `Downloads` folders
- Output saved to Desktop with timestamp (e.g. `ServicesList_2025-07-04_09_45_30_AM.csv`)

## 📁 Output Example

| # | DisplayName             | Name      | Description | State  | StartName | PathName       | Publisher         | Suspicious |
|---|-------------------------|-----------|-------------|--------|-----------|----------------|-------------------|------------|
| 1 | Application Information | Appinfo   | ...         | Running| LocalSystem | C:\Windows\... | Microsoft Windows | False      |
| 2 | XYZ Service             | xyzsvc    | ...         | Stopped| .\User     | C:\Users\...   | Unsigned          | True       |

## 🚀 How to Use

1. Open PowerShell as Administrator
2. Run the script:
   ```powershell
   .\Get-WindowsServices.ps1
The script will display progress and save a CSV file to your Desktop.

✅ Requirements
Windows 10/11

PowerShell 5.1 or later

Admin privileges recommended (to access all services)
