# Pocket Dashcam — Movozen Campus Hiring Challenge -26
A Flutter mobile application that turns a smartphone into a live-streaming dashcam broadcasting camera and microphone media over **RTMP** with **H.264** video and **AAC** audio encoding.

---

## 🚀 Features

- **Live RTMP Streaming:** Real-time hardware-encoded H.264/AAC broadcasting to Movozen ingestion servers.
- **Dual Camera Support:** Smooth switching between Back (road-facing) and Front (driver-facing) cameras.
- **Microphone Audio:** Integrated audio capture with one-tap mute/unmute control.
- **Dynamic Roll Number Keys:** Auto-formats stream keys to `{ROLLNO}_back` and `{ROLLNO}_front`.
- **Live HUD & Telemetry:** In-app status badges, duration timers, and connection states.

---

## 🛠️ Tech Stack & Architecture

- **Framework:** Flutter (Dart)
- **Platform:** Android
- **Streaming Protocol:** RTMP
- **Video Codec:** H.264
- **Audio Codec:** AAC
- **Core Plugins:** `apivideo_live_stream`, `permission_handler`

---

## 📡 Streaming Configuration

- **Ingest Server:** `rtmp://15.207.177.194:1936/hackathon/`
- **Stream Key Pattern:**
  - Back Camera: `{ROLLNO}_back`
  - Front Camera: `{ROLLNO}_front`
- **Live Viewer:** `http://15.207.177.194:8081/web/player.html`

---

## 📱 Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Ketan411/pocket-dashcam.git
   cd pocket-dashcam
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on connected Android device:**
   ```bash
   flutter run
   ```
