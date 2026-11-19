# Approved POTS icon manifest

The 13-image art set is a matched glossy, multi-color collection of **1024 × 1024 PNGs**. All icons must be distinct, high-resolution and use clear accessible text labels.

| Source file | Feature | Colors |
|---|---|---|
| 00_App_Icon.png | Home Screen app icon | aqua/cyan |
| 01_Heart_Rate.png | Heart rate | coral pink |
| 02_Blood_Pressure.png | Blood pressure | blue |
| 03_Symptoms.png | Symptoms | amber/orange |
| 04_Hydration.png | Hydration | ocean blue |
| 05_Medications.png | Medications | green |
| 06_Sleep.png | Sleep | violet |
| 07_Calendar.png | Calendar/history | orange/red |
| 08_Reports.png | Reports/trends | mint-green |
| 09_Journal.png | Journal | magenta |
| 10_Posture.png | Posture | teal |
| 11_Reminders.png | Reminders | sky blue |
| 12_Settings.png | Settings | lavender |

Source archive: `POTS_13_Color_Matched_Icons.zip` from the approved design conversation, with entries under `POTS_Icon_Set_13_Colors/`.

Destination: `POTSTracker/Resources/Icons/`.

**Asset gate:** This document is not the artwork itself. Verify all 13 actual PNGs are in GitHub and decode to the expected 1024 × 1024 dimensions before marking icon import completed. Never replace the approved designs with approximate placeholder icons.

Import command: `python3 POTSTracker/tools/import_icons.py POTS_13_Color_Matched_Icons.zip --repo-root .`

For the actual Home Screen icon, remove any manually rounded black edges/padding before placing it in the native AppIcon asset set; iOS performs its own masking.
