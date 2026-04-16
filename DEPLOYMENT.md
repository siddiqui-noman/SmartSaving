# SmartSaving Deployment Guide (Render)

This guide explains how to deploy the SmartSaving backend to **Render** and connect your mobile app to it.

## 🛠️ Prerequisites
- A [Render](https://render.com/) account.
- Your project pushed to a GitHub repository.
- A **Gemini API Key** from [Google AI Studio](https://aistudio.google.com/).

---

## 🏗️ Step 1: Deploy the Backend to Render

1.  Log in to [Render Dashboard](https://dashboard.render.com/).
2.  Click **New +** and select **Web Service**.
3.  Connect your GitHub repository.
4.  Configure the service:
    *   **Name**: `smartsaving-backend` (or any name you like).
    *   **Root Directory**: `backend`
    *   **Environment**: `Docker`
    *   **Instance Type**: `Free` (or higher for persistent storage).
5.  Click **Advanced** and add the following **Environment Variables**:
    *   `GEMINI_API_KEY`: Your real API Key.
    *   `PORT`: `10000` (Render will set this automatically, but good to know).
    *   `ENV`: `production`
    *   `CORS_ALLOW_ORIGINS`: `*`
6.  Click **Create Web Service**.
7.  Once the build finishes, copy your **Service URL** (e.g., `https://smartsaving-backend.onrender.com`).

> [!WARNING]
> **SQLite Note**: On Render's Free tier, the `app.db` file (SQLite) will reset every time the server restarts. To keep your data permanent, you would need Render's paid **Persistent Disk** feature or an external database like **Neon (Postgres)**.

---

## 📱 Step 2: Connect the Flutter App

1.  Open `lib/services/api_config.dart` in your project.
2.  Update `productionBaseUrl` with your new Render URL:
    ```dart
    static const String productionBaseUrl = 'https://smartsaving-backend.onrender.com';
    ```
3.  Set `isProduction` to `true`:
    ```dart
    static const bool isProduction = true;
    ```
4.  Build your production APK:
    ```bash
    flutter build apk --release
    ```

---

## ✅ Step 3: Verify the Deployment
- Open your browser to `https://your-service-url.onrender.com/health`.
- You should see `{"status": "ok"}`.
- Install the APK on your phone and test the AI Assistant!

---

## 💡 Pro Tip: Moving to Persistent Data
If you want to save tracked products forever for free, I recommend creating a free PostgreSQL database on [Neon.tech](https://neon.tech/) and updating your `backend/.env` with the `DATABASE_URL`.
