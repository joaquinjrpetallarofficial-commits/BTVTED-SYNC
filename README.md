# CCD BTVTeD Sync

A browser-based research repository prototype for the Bachelor of Technical Vocational Teacher Education program at City College of Davao. It includes searchable sample research papers, student submissions and admin review, view counts, and a keyword-matching FAQ chatbot.

## Project files

- `index.html` — Vercel/GitHub Pages entry point; loads seed data from the root `papers-data.js`.
- `papers-data.js` — sample research papers displayed in the application.
- `CCD BTVTeD Sync - Open Student Research Search.html` — standalone copy with seed data embedded.
- `DATABASE.sql` — MySQL/MariaDB schema for accounts and roles, user profiles, signup-consent records, research papers, categories, and views. It is not connected to the browser application.

## Run locally

Open `index.html` in a modern browser from the repository root. Keep `papers-data.js` beside it. The standalone HTML file can also be opened on its own.

Tailwind CSS loads from its CDN, so an internet connection is needed for styling. The application stores accounts, submissions, view counts, and signup-consent versions/timestamps in the current browser's local storage; this data is not shared with other users or devices. New signups must accept both the Terms and Conditions and Privacy Policy. Sign-in requires choosing the matching student or administrator account type; public signup can only create student accounts.

## Important limitations

This is a prototype, not a production multi-user system. Authentication and role checks run in the browser, and can be altered by visitors; the default demo accounts are defined in the application code. Do not use real or sensitive account information. Use server-side authentication and authorization plus a backend database before deploying for real users. Create administrator accounts only through a trusted, authorized setup process.

The SQL file is a separate MySQL/MariaDB schema and sample-data script; the HTML application does not connect to it or to Supabase. Its sample categories and papers can be seeded repeatedly without deleting existing rows or duplicating the five seed papers. It does not create accounts with placeholder passwords. Passwords must be hashed and verified in trusted server code; never send password hashes to the browser.

The signup policies are draft templates that describe this browser-only prototype. Before real institutional use, have the responsible institution review them and specify its data controller/contact, lawful basis, retention periods, user-rights process, and service providers.

Seed papers do not include attached PDF files, so the document-opening action is available only for submissions with an uploaded PDF.

## Publish with GitHub Pages

Vercel and GitHub Pages can serve the root `index.html` directly. Keep `papers-data.js` in the repository root so the page can load its sample data.

This project remains a static prototype: local-storage accounts, submissions, and view counts are isolated to each visitor's browser. Supabase is not connected. No Vercel or Supabase project credentials are included in this repository.
