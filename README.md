# CCD BTVTeD Sync

A browser-based research repository prototype for the Bachelor of Technical Vocational Teacher Education program at City College of Davao. It includes searchable sample research papers, student submissions and admin review, view counts, and a keyword-matching FAQ chatbot.

## Project files

- `index.html` — Vercel/GitHub Pages entry point; loads seed data from the root `papers-data.js`.
- `papers-data.js` — sample research papers displayed in the application.
- `CCD BTVTeD Sync - Open Student Research Search.html` — standalone copy with seed data embedded.
- `DATABASE.sql` — MySQL/MariaDB schema, sample records, and example queries. It is not connected to the browser application.

## Run locally

Open `index.html` in a modern browser from the repository root. Keep `papers-data.js` beside it. The standalone HTML file can also be opened on its own.

Tailwind CSS loads from its CDN, so an internet connection is needed for styling. The application stores accounts, submissions, and view counts in the current browser's local storage; this data is not shared with other users or devices.

## Important limitations

This is a prototype, not a production multi-user system. Authentication and role checks run in the browser, and the default demo accounts are defined in the application code. Do not use real or sensitive account information. Use server-side authentication and authorization plus a backend database before deploying for real users.

The SQL file is a separate MySQL/MariaDB schema and sample-data script; the HTML application does not connect to it or to Supabase. Its sample categories and papers can be seeded repeatedly without deleting existing rows or duplicating the five seed papers. It does not create demo accounts with placeholder passwords.

Seed papers do not include attached PDF files, so the document-opening action is available only for submissions with an uploaded PDF.

## Publish with GitHub Pages

Vercel and GitHub Pages can serve the root `index.html` directly. Keep `papers-data.js` in the repository root so the page can load its sample data.

This project remains a static prototype: local-storage accounts, submissions, and view counts are isolated to each visitor's browser. Supabase is not connected. No Vercel or Supabase project credentials are included in this repository.
