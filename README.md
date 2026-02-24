# Smart Academic Attendance & Notification Management System  
## Faculty Desktop Application

---

## 📌 Overview

This repository contains the **Faculty Desktop Application** for the final year project:

**Smart Academic Attendance and Notification Management System**

The desktop application enables faculty members to manage lecture sessions, monitor live attendance, and control attendance recording through an integrated software + hardware workflow.

The system aims to reduce proxy attendance and digitize academic attendance management using session-based authentication and biometric verification.

---

## 🎯 Purpose

The Faculty Desktop App is responsible for:

- Starting and ending lecture sessions
- Viewing live attendance updates
- Monitoring student attendance status
- Managing lecture details (course, batch, room, time slot)
- Interacting with backend services for session control

This application acts as the **control panel** for classroom attendance operations.

---

## 🖥️ Main Features

### ✔ Faculty Dashboard

- Displays faculty profile information
- Navigation panel (Home, Batches, Courses)
- Quick access to session controls

---

### ✔ Lecture Information Panel

Displays active lecture details:

- Course Name
- Lecturer
- Time Slot
- Room Number
- Department
- Batch

---

### ✔ Session Management

Faculty can:

- ▶ **Start Session**
- ⏹ **End Session**

When a session starts:

- Backend generates a unique Session UUID
- ESP32 device broadcasts the session SSID
- Students inside the classroom can mark attendance

---

### ✔ Live Attendance Monitoring

- Real-time attendance count
- Student list with attendance status
- Visual indicators:

✔ Present
✖ Absent


---

### ✔ Attendance Progress

Shows total attendance marked during the session.

Example:
25 out of 63 students marked present


---

## 🧱 Architecture Role

This desktop application works as:
Faculty UI
↓
Backend REST APIs
↓
Database + ESP32 Integration


The desktop app does **not** directly communicate with hardware or the database.  
All operations are performed via backend APIs.

---

## 🛠️ Tech Stack

- Flutter (Desktop)
- Dart
- REST API Integration
- AWS Backend Services (via APIs)

---

## 🔄 Workflow (High Level)

1. Faculty opens dashboard
2. Selects lecture / batch
3. Clicks **Start Session**
4. Backend creates Session UUID
5. ESP32 broadcasts session SSID
6. Students authenticate via mobile app
7. Attendance updates live on dashboard
8. Faculty ends session

---
## 🚀 Future Enhancements

- Real-time socket updates
- Attendance analytics & reports
- Notification controls
- Session history
- Export attendance reports

---

## 👨‍💻 Project Context

Final Year Project — Computer Engineering  

This module is part of a larger system including:

- Student Mobile Application
- Backend REST APIs
- AWS Cloud Database
- ESP32 WiFi Device Integration