# OPTIMA – Optimal Platform for Tracking, Inventory & Material Allocation

## Overview
OPTIMA is an IoT-enabled hardware + software system designed to intelligently track and manage material movement in heavy industries such as construction. The system provides real-time visibility, reduces material wastage, detects anomalies, and enables data-driven inventory decisions.

## Problem Statement
In industries like construction, materials are frequently mismanaged due to manual tracking, poor visibility, lack of accountability and delayed reporting.

This results in:
- Inventory loss
- Higher operational cost
- Resource misuse / wastage
- Delayed project workflows

OPTIMA solves this by digitizing and automating the material tracking process.

## Solution
The system uses RFID Tags attached to materials, which are scanned by RFID Readers connected to an ESP32 microcontroller. Movement & status data is transmitted to the cloud, where it is monitored through a software dashboard.

Users receive real-time notifications for:
- New orders
- Low stock levels
- Abnormal material activity (anomaly detection)

An active buzzer provides immediate on-site alerts.

## Hardware Used
- RFID Reader – scans tagged materials
- RFID Tags – unique ID for each material item
- ESP32 – sends data to cloud
- Active Buzzer – on-site alert notifications

## Software Features
- Inventory dashboard / material status
- Realtime push notifications
- Order tracking
- Anomaly detection module
- Historical usage insights

## Tech Stack
**Hardware:** RFID Sensors, ESP32  
**Communication:** Wi-Fi / MQTT / REST  
**Backend:** Cloud Database + Server API (e.g., Firebase)  
**Frontend:** Web / Mobile Application (UI for inventory & notifications)

## Flow Summary
1. Material item is tagged with RFID.
2. RFID reader detects entry/exit events via ESP32.
3. Data is pushed to cloud platform.
4. Application displays current material status.
5. If abnormal patterns occur → alert & buzzer trigger.

## Target Users
- Construction contractors
- Supply chain supervisors
- Warehouse material managers
- Project execution teams

## Impact
- Optimized resource usage → reduced operational costs
- Real-time inventory visibility → faster decision making
- Anomaly detection → reduces theft / misuse
- Digital tracking → transparent supply chain

## Team
**Team LUMENIS – 2507ID05**

- Nivaashini Thangaraj (Team Lead)
- Harini Nachammai P
- Rithanya S
- Nija Priya S

Mentor: Dr. Manimegalai R (Professor – CSE)
