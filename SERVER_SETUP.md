# Server Setup Guide

Follow these steps to set up your Parallax Connect server on your computer.

---

## Prerequisites

- **Python 3.8+** installed on your computer
- **Git** (to clone the repository)

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/ManishModak/parallax-connect.git
cd parallax-connect
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

---

## Choose Your Connection Mode

### ☁️ Cloud Mode (Connect from Anywhere)

**Best for:** Accessing your server over the internet (4G/5G/Different Wi-Fi)

#### Setup Steps

1. **Get Ngrok Token:**
   - Sign up at [ngrok.com](https://dashboard.ngrok.com) (Free)
   - Copy your **Authtoken** from the dashboard

2. **Configure Ngrok:**

   ```bash
   ngrok config add-authtoken <PASTE_YOUR_TOKEN_HERE>
   ```

3. **Start Server:**

   ```bash
   python server.py
   ```

4. **Connect:**
   - A **Cloud QR Code** will appear in the terminal
   - Scan it with the Parallax Connect app

**Free Limits:** 1GB bandwidth/month, sufficient for personal use.

---

### 🏠 Local Mode (Same Wi-Fi Only)

**Best for:** Low latency, no internet required, unlimited bandwidth

#### Setup Steps

1. **Start Server:**

   ```bash
   python server.py
   ```

2. **Connect:**
   - Ensure your phone and computer are on the **same Wi-Fi network**
   - A **Local QR Code** will appear in the terminal
   - Scan it with the Parallax Connect app

**Troubleshooting Tip:** If connection fails, try using your phone's Hotspot for both devices.

---

## Running Both Modes Simultaneously

Good news! When you run `python server.py`, **both modes are active**:

- If Ngrok is configured → You get a Cloud URL
- Always → You get a Local URL

You can connect using either QR code depending on your needs.

---

## Next Steps

Once the server is running, open the **Parallax Connect** app on your phone and scan the QR code to connect!
