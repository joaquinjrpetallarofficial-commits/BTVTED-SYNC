# CCD BTVTeD Sync

A browser-based research repository prototype for the Bachelor of Technical Vocational Teacher Education program at City College of Davao. It includes searchable sample research papers, student submissions and admin review, view counts, and a keyword-matching FAQ chatbot.

## Project files

- `index.html` — Vercel/GitHub Pages entry point; loads seed data from the root `papers-data.js`.
- `BTVTED.jpg` — BTVTeD / City College of Davao logo used in the page headers.
- `papers-data.js` — sample research papers displayed in the application.
- `CCD BTVTeD Sync - Open Student Research Search.html` — standalone copy with seed data embedded.
- `supabase/config.toml` — Supabase CLI project configuration.
- `supabase/migrations/20261113150000_initial_schema.sql` — Supabase/PostgreSQL migration for Auth-linked profiles, student/admin roles, signup-consent records, research papers, categories, view counts, RLS policies, and private PDF storage.

## Database SQL

The full Supabase schema is in [`supabase/migrations/20261113150000_initial_schema.sql`](./supabase/migrations/20261113150000_initial_schema.sql). It defines the Auth-linked `profiles`, `user_roles`, `administrator_profiles`, and `privacy_consents` tables, along with the research repository tables, access policies, and private PDF storage rules. `privacy_consents` stores separate Terms and Privacy Policy versions plus the acceptance timestamp. If the prototype `public.research_papers` table already exists, the migration preserves it as `public.research_papers_legacy` and creates the new table separately; its existing indexes are renamed to avoid collisions. Review the migration's effect on your data before applying it.

## Run locally

Open `index.html` in a modern browser from the repository root. Keep `papers-data.js` beside it. The standalone HTML file can also be opened on its own.

Tailwind CSS loads from its CDN, so an internet connection is needed for styling. The application stores accounts, submissions, view counts, and signup-consent versions/timestamps in the current browser's local storage; this data is not shared with other users or devices. New signups must separately check that they agree to the Terms and Conditions and acknowledge the Privacy Policy. Sign-in requires choosing the matching student or administrator account type; public signup can only create student accounts.

## Supabase setup

The migration has **not** been run against a Supabase project. To apply it using the Supabase CLI:

1. Install the Supabase CLI and sign in with `supabase login`.
2. From the repository root, link your project with `supabase link --project-ref YOUR_PROJECT_REF`.
3. Review the migration, then apply it using `supabase db push`.

Alternatively, review and run the migration in the Supabase Dashboard SQL Editor. It creates a private `research-papers` storage bucket (PDFs up to 2 MB), enables row-level security, and seeds discipline categories and five sample papers. Promote a trusted account to administrator only by running the commented admin setup statements at the end of the migration in the SQL Editor. Use either the CLI or SQL Editor to apply the migration, not both.

Supabase Auth stores and verifies passwords; there is no password table or password hash in this migration. Public signup creates only student roles. Admin role changes must be performed by an authorized operator.

## Important limitations

The current HTML is still a local-storage prototype and does not call Supabase. Its browser-based login and role checks can be altered by visitors, and demo credentials remain in the application code. Do not use real or sensitive account information until the HTML is integrated with Supabase Auth and the database policies have been tested.

The signup policies are draft templates that describe the browser-only prototype. Before real institutional use, have the responsible institution review them and specify its data controller/contact, lawful basis, retention periods, user-rights process, and service providers.

Seed papers do not include attached PDF files, so the document-opening action is available only for submissions with an uploaded PDF.

## Publish with GitHub Pages

Vercel and GitHub Pages can serve the root `index.html` directly. Keep `papers-data.js` in the repository root so the page can load its sample data.

The app remains a static prototype until connected to Supabase. Never commit Supabase service-role keys, database passwords, or other secrets. No Vercel or Supabase project credentials are included in this repository.
