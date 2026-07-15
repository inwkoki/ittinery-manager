# Itinerary Manager

A single-file travel itinerary planner (one `index.html`) backed by Supabase.
Plan trips day-by-day, track bookings and budgets, see everything on a map, and
keep it all offline-capable.

## Features

- **Trips & itinerary items** — day-grouped cards with times, categories
  (flight/train/bus/car/lodging/activity/food), places, notes and photos.
- **Google Places** autocomplete — auto-fills address, opening hours and photo.
- **Flight lookup** (AviationStack) — fills airports, times, terminal/gate.
- **Booking reminders** — "remind me N days before", with overdue highlighting
  and optional **browser notifications** (🔔).
- **💰 Budget dashboard** — totals by category and by day, with **multi-currency
  conversion** (live rates from open.er-api.com, cached, with an offline fallback).
- **🗺️ Map view** — all places geocoded and pinned on a Google Map.
- **Per-day weather** — forecast icons/highs/lows via Open-Meteo (no key needed),
  shown for dates within the ~16-day forecast window.
- **🎒 Packing / checklist** — per-trip, with progress count.
- **🔗 Share** — copy/share a deep link to a trip.
- **Duplicate trip** — clone a trip and all its items as a template.
- **QR tickets**, **Google Calendar** quick-add, **PDF/JPG/text export**.
- **Offline (PWA)** — installable, service-worker-cached app shell + libraries.
- **🌐 Thai / English** UI toggle.
- **Optional accounts** — email/password sign-in (Supabase Auth). Signed-in users'
  trips are private to them; signed out, the app still works on shared data.
- Light/dark theme.

## Setup

1. Create a Supabase project and run [`schema.sql`](schema.sql) in its SQL Editor.
2. Put your project URL + publishable key in `index.html` (`SUPABASE_URL` / `SUPABASE_KEY`).
3. Serve the folder over HTTP (e.g. `python -m http.server`) or any static host.
   A secure context (`https://` or `localhost`) is required for the service worker.
4. Optional: add your **Google Maps** and **AviationStack** keys in Settings (⚙).
   The Google Maps key must have the **Places API** and **Maps JavaScript API**
   enabled (client-side by design — restrict it by API + quota in Google Cloud).

### Enabling accounts (optional)

`schema.sql` adds a `user_id` column and per-user Row Level Security policies:
existing rows (`user_id IS NULL`) stay shared/accessible via the publishable key,
while rows created when signed in are private to that user. To use it, run the
updated `schema.sql`, then enable **Email** auth in your Supabase dashboard
(Authentication → Providers).

## Tech

Vanilla HTML/CSS/JS, [Supabase JS](https://supabase.com/), QRCode.js,
html2canvas, Google Maps JS API, Open-Meteo, open.er-api.com. No build step.
