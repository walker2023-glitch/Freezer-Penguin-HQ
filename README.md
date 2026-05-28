# Freezer Penguin HQ 🐧❄️
> "Gather up the fragments that remain, that nothing be lost." — John 6:12

**Freezer Penguin HQ** is a full-stack smart-stewardship platform designed to eliminate household food waste. By combining automated inventory tracking with AI-driven culinary orchestration, we help users turn at-risk ingredients into meaningful meals.

---

## 🏗️ Architecture
- **Infrastructure:** Proxmox-virtualized Ubuntu Server hosting a MySQL 3NF database.
- **Backend:** Python (FastAPI) orchestrating dual-API logic.
- **Admin Frontend:** Streamlit dashboard for real-time SQL auditing and inventory management (ITM 220).
- **Consumer Frontend:** Mobile-first web application wrapped via Capacitor (CSE 199).

## 🧠 AI Strategy: The "Chef & Librarian"
We utilize a decoupled AI approach to ensure safety and data integrity:
1. **The Librarian (Spoonacular API):** Provides verified, structured recipe data and nutritional facts.
2. **The Chef (Gemini 1.5 Pro):** Personalizes meal suggestions based on user preferences and analyzes "Handmade Meal" images for shelf-life estimation.

## 📈 Database Schema (3rd Normal Form)
The system relies on a 10-table normalized schema, including:
- `inventory_items` & `barcode_master` for tracking.
- `ai_audit_logs` for semantic entropy and hallucination auditing.
- `waste_logs` for generating stewardship and cost-saving statistics.

## 🚀 Business Model
- **Basic ($1 One-Time):** Unlimited manual tracking and barcode scanning.
- **Premium ($10/Month):** Unlocks AI Computer Vision, automated recipe generation, and multi-device cloud sync.

---
*Developed by Dallas Walker | BYUI Spring 2026*
