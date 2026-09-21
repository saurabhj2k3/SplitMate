# 📒 SplitMate — Modern Expense Splitting & Debt Simplification App

A full-stack, fintech expense-sharing application built with a responsive **Flutter (Web & Mobile)** frontend and a **Node.js/Express + Prisma ORM + Supabase PostgreSQL** backend. Features accurate cent-based split calculations, zero-loss remainder distribution, greedy debt graph simplification, and a retro notebook aesthetic.

---

## 🚀 Features

- **📒 Retro Notebook UI:** 24px grid paper, sticky tape accents, tactile borders, offset shadows, and clean responsive layouts.
- **⚡ Flexible Expense Splitting:**
  - Equal split with zero-cent loss remainder distribution.
  - Custom exact amounts.
  - Percentage-based splits.
- **🔄 Smart Debt Simplification:** Greedy algorithm minimizes total transaction hops across group members.
- **👥 Unregistered / Guest Member Support:** Add friends by name/email without requiring them to register in advance. Past histories automatically merge upon sign-up.
- **👑 Owner Permissions:** Only group creators/owners can delete groups.
- **☁️ Production-Ready Database:** Live PostgreSQL hosted on **Supabase** with connection pooling.

---

## 📁 Project Structure

`
SplitMate/
├── backend/                  # Node.js + TypeScript + Express + Prisma Backend
│   ├── api/                  # Vercel serverless entry point
│   ├── prisma/               # Database schema & seed scripts
│   ├── src/
│   │   ├── controllers/      # Request handlers (auth, group, expense, settlement)
│   │   ├── middleware/       # Auth JWT & validation middleware
│   │   ├── routes/           # REST API routes (/api/v1/...)
│   │   ├── services/         # Business logic, split algorithms & debt simplifier
│   │   └── server.ts         # Local development server
│   └── vercel.json           # Vercel deployment configuration
│
└── mobile/                   # Flutter Web & Mobile Application
    ├── lib/
    │   ├── core/             # Theme, colors, notebook scaffold, API client
    │   ├── features/         # Auth, Dashboard, Groups, Expenses, Settlements
    │   ├── models/           # Dart data models
    │   └── providers/        # Riverpod state management
    └── pubspec.yaml          # Flutter dependencies
`

---

## 🛠️ Local Development

### 1. Backend Setup
`ash
cd backend
npm install
cp .env.example .env     # Configure your DATABASE_URL / Supabase credentials
npx prisma generate
npx prisma db push
npm run dev
`
Backend runs on http://localhost:5000.

### 2. Flutter App Setup
`ash
cd mobile
flutter pub get
flutter run -d chrome     # Or flutter run -d web-server --web-port 3000
`

---

## 🌐 Deployment Guide

### A. Deploy Backend (Vercel)
1. Import the repository on [Vercel](https://vercel.com).
2. Set **Root Directory** to ackend.
3. Add Environment Variables:
   - DATABASE_URL: Your Supabase PostgreSQL connection string.
   - DIRECT_URL: Supabase direct connection string.
   - JWT_SECRET: A secure random secret key.
   - CORS_ORIGIN: * (or your frontend domain).
4. Click **Deploy**.

### B. Deploy Frontend (Flutter Web on Vercel / Netlify / Cloudflare Pages)
1. Build the release bundle:
   `ash
   cd mobile
   flutter build web --release --dart-define=API_URL=https://your-backend-domain.vercel.app/api/v1
   `
2. Deploy the mobile/build/web folder to Vercel, Netlify, or GitHub Pages.

### C. Build Android APK
`ash
cd mobile
flutter build apk --release --dart-define=API_URL=https://your-backend-domain.vercel.app/api/v1
`
Output APK is located at:
mobile/build/app/outputs/flutter-apk/app-release.apk

---

## 📜 License
MIT License.
