-- CCD BTVTeD Sync Supabase schema.
-- Apply with `supabase db push` after linking your Supabase project, or run
-- this migration in the Supabase SQL Editor. Supabase Auth owns passwords.

create type public.app_role as enum ('student', 'admin');
create type public.paper_status as enum ('pending', 'approved', 'rejected');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text unique,
  full_name text not null default 'New user',
  student_number text unique,
  program text,
  year_level smallint check (year_level between 1 and 8),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_roles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role public.app_role not null default 'student',
  created_at timestamptz not null default now()
);

create table public.administrator_profiles (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  admin_title text,
  created_by_user_id uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.privacy_consents (
  consent_id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  terms_version text not null check (length(btrim(terms_version)) > 0),
  privacy_version text not null check (length(btrim(privacy_version)) > 0),
  accepted_at timestamptz not null default now()
);

create index privacy_consents_user_date_idx
  on public.privacy_consents (user_id, accepted_at desc);

create table public.categories (
  category_id uuid primary key default gen_random_uuid(),
  name text not null unique
);

create table public.research_papers (
  paper_id uuid primary key default gen_random_uuid(),
  title text not null,
  authors text not null,
  abstract text not null default '',
  pub_year smallint not null,
  category_id uuid not null references public.categories (category_id),
  citation text,
  file_name text,
  file_path text,
  submitted_by uuid references public.profiles (id) on delete set null,
  status public.paper_status not null default 'pending',
  admin_note text,
  submitted_at timestamptz not null default now(),
  approved_by uuid references public.profiles (id) on delete set null,
  approved_at timestamptz,
  defense_date date,
  constraint research_papers_approval_fields_check check (
    status <> 'approved' or approved_by is not null or submitted_by is null
  ),
  constraint research_papers_file_path_check check (
    file_path is null or file_path !~ '^/'
  ),
  constraint research_papers_seed_title_authors_key unique (title, authors)
);

create index research_papers_status_idx on public.research_papers (status);
create index research_papers_year_idx on public.research_papers (pub_year);
create index research_papers_category_idx on public.research_papers (category_id);
create index research_papers_submitter_idx on public.research_papers (submitted_by);
create index research_papers_search_idx
  on public.research_papers using gin (
    to_tsvector('english', title || ' ' || authors || ' ' || abstract)
  );

create table public.paper_views (
  view_id bigint generated always as identity primary key,
  paper_id uuid not null references public.research_papers (paper_id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  session_id uuid not null,
  viewed_at timestamptz not null default now(),
  constraint paper_views_one_per_user_session unique (paper_id, user_id, session_id)
);

create index paper_views_user_idx on public.paper_views (user_id);

-- Role checks use a definer function so RLS policies can check protected roles
-- without granting clients write access to user_roles.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_roles
    where user_id = (select auth.uid())
      and role = 'admin'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- Create a basic profile and student role for new Auth accounts. Never accept
-- a role from user metadata; admin assignment is a separate trusted operation.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, username, full_name)
  values (
    new.id,
    coalesce(
      nullif(lower(btrim(new.raw_user_meta_data ->> 'username')), ''),
      'user-' || left(new.id::text, 8)
    ),
    coalesce(nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''), 'New user')
  )
  on conflict (id) do nothing;

  insert into public.user_roles (user_id, role)
  values (new.id, 'student')
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- Backfill Auth users that existed before this migration.
insert into public.profiles (id, username, full_name)
select
  id,
  coalesce(
    nullif(lower(btrim(raw_user_meta_data ->> 'username')), ''),
    'user-' || left(id::text, 8)
  ),
  coalesce(nullif(btrim(raw_user_meta_data ->> 'full_name'), ''), 'New user')
from auth.users
on conflict (id) do nothing;

insert into public.user_roles (user_id, role)
select id, 'student' from auth.users
on conflict (user_id) do nothing;

create or replace function public.set_profile_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_profile_updated_at();

insert into public.categories (name)
values
  ('Computer Science'),
  ('Agriculture'),
  ('Environment & Disaster Management')
on conflict (name) do nothing;

insert into public.research_papers (
  title, authors, abstract, pub_year, category_id, citation, status
)
select
  seed.title,
  seed.authors,
  seed.abstract,
  seed.pub_year,
  category.category_id,
  seed.citation,
  'approved'::public.paper_status
from (
  values
    (
      'Automated Drainage Cleaner with Water Level Monitoring and SMS Flood Alert System',
      'Silongan, M. J. A., Lorenzo, C. S. B., Gamus, E. D. C., Mariposque, C. J. A., Romano, R. C., Masangya, R. A., Maguana, G. E., & Pene, J. A.',
      'This project study designs and develops an automated drainage cleaner to clear blockages, combined with real-time water level monitoring and a GSM-based SMS flood alert system to mitigate urban flooding and protect vulnerable communities in Davao City[cite: 1].',
      2025,
      'Environment & Disaster Management',
      'Silongan, M. J. A., et al. (2025). Automated Drainage Cleaner with Water Level Monitoring and SMS Flood Alert System. City College of Davao, Bachelor of Technical Vocational Teacher Education[cite: 1].'
    ),
    (
      'Smart Flood Alert System',
      'Quibol, P. J. B., Gamboa, J. A. B., Demeterio, B. M. J., Escobarte, L. A. M., Felizarta, R. I. A., Bacurnay, C. P., Batitay, M. S., & Teofilo, J. R.',
      'An affordable, community-based early warning system designed to detect rising water levels and identify human presence in danger zones using PIR motion detection, audible alarms, and SMS notifications to prevent casualties during flash floods[cite: 2].',
      2025,
      'Environment & Disaster Management',
      'Quibol, P. J. B., et al. (2025). Smart Flood Alert System. City College of Davao, Bachelor of Technical Vocational Teacher Education[cite: 2].'
    ),
    (
      'Smart Ventilation Control System for Chicken Factories',
      'Perez, C. J., Petallar, J. P., Quicoy, A. M., Autida, R. M., Drama, A., Baldovi, J., & Onio, G.',
      'An IoT-driven agricultural automation project aimed at reducing heat stress and managing air quality (such as ammonia and humidity levels) in poultry housing through automated temperature monitoring and ventilation control[cite: 3].',
      2025,
      'Agriculture',
      'Perez, C. J., et al. (2025). Smart Ventilation Control System for Chicken Factories. City College of Davao, Bachelor of Technical Vocational Teacher Education[cite: 3].'
    ),
    (
      'SmartFish: A Sustainable and Innovative System for Real-Time Water Level Monitoring, Smart Filtration, and Automated Fish Farm Maintenance',
      'Batucan, M. F. V., Magayo, L. L., Turnos, D. N. L., Pagat, A. K. R., Castillo, M. E., Malanas, D. F. A., Talay, R. F., Corlit, R. R. A., & Flores, H. C.',
      'A sustainable aquaculture solution integrating automated water level sensing, smart filtration/recycling mechanisms, and automated feeding to enhance fish yield, reduce water contamination, and modernize traditional fish farming operations.',
      2025,
      'Agriculture',
      'Batucan, M. F. V., et al. (2025). SmartFish: A Sustainable and Innovative System for Real-Time Water Level Monitoring, Smart Filtration, and Automated Fish Farm Maintenance. City College of Davao, Bachelor of Technical Vocational Teacher Education.'
    ),
    (
      'pH Level Monitoring System and Drainer for Aquaculture',
      'Coscos, K. D. M. C., Echavez, C. A. A., Guiang, G. A. O., Concellado, C. J. R., Bermudez, G. P., Alfafara, C. A., Fulguerinas, J. H., & Elivera, C. R.',
      'An IoT-based system for fish farms that continuously measures pond water pH with a sensor controlled by an Arduino Uno and shows the reading on an LCD. When pH becomes unsafe, a SIM800L GSM module sends SMS alerts to the owner, and a servo motor opens a gate to drain the water, closing it again once pH returns to normal. The study tests real-time monitoring, sensor accuracy and drainage effectiveness as a low-cost alternative to manual pH testing for small to medium-sized fish farms.',
      2025,
      'Agriculture',
      'Coscos, K. D. M. C., Echavez, C. A. A., Guiang, G. A. O., Concellado, C. J. R., Bermudez, G. P., Alfafara, C. A., Fulguerinas, J. H., & Elivera, C. R. (2025). pH Level Monitoring System and Drainer for Aquaculture. City College of Davao, Bachelor of Technical Vocational Teacher Education.'
    )
) as seed(title, authors, abstract, pub_year, category_name, citation)
join public.categories as category on category.name = seed.category_name
on conflict (title, authors) do nothing;

alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.administrator_profiles enable row level security;
alter table public.privacy_consents enable row level security;
alter table public.categories enable row level security;
alter table public.research_papers enable row level security;
alter table public.paper_views enable row level security;

create policy "Users can read their own profile or admins can read all"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = id or (select public.is_admin()));

create policy "Users can update their own profile or admins can update all"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = id or (select public.is_admin()))
  with check ((select auth.uid()) = id or (select public.is_admin()));

create policy "Users can read their own role and admins can read all"
  on public.user_roles for select to authenticated
  using ((select auth.uid()) = user_id or (select public.is_admin()));

create policy "Admins can manage administrator profiles"
  on public.administrator_profiles for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy "Users can read their own consent and admins can audit"
  on public.privacy_consents for select to authenticated
  using ((select auth.uid()) = user_id or (select public.is_admin()));

create policy "Users can record their own consent"
  on public.privacy_consents for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Categories are publicly readable"
  on public.categories for select to anon, authenticated
  using (true);

create policy "Admins can manage categories"
  on public.categories for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy "Approved papers, owners, and admins can read papers"
  on public.research_papers for select to anon, authenticated
  using (
    status = 'approved'
    or ((select auth.uid()) is not null and submitted_by = (select auth.uid()))
    or (select public.is_admin())
  );

create policy "Students can submit their own pending papers"
  on public.research_papers for insert to authenticated
  with check (
    submitted_by = (select auth.uid())
    and status = 'pending'
    and approved_by is null
    and approved_at is null
    and admin_note is null
  );

create policy "Admins can review and update papers"
  on public.research_papers for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy "Admins can delete papers"
  on public.research_papers for delete to authenticated
  using ((select public.is_admin()));

create policy "Owners and admins can read paper views"
  on public.paper_views for select to authenticated
  using (
    user_id = (select auth.uid())
    or (select public.is_admin())
    or exists (
      select 1 from public.research_papers p
      where p.paper_id = paper_views.paper_id
        and p.submitted_by = (select auth.uid())
    )
  );

create policy "Users can record their own paper views"
  on public.paper_views for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.research_papers p
      where p.paper_id = paper_views.paper_id
        and p.status = 'approved'
    )
  );

grant select, update on public.profiles to authenticated;
grant select on public.user_roles to authenticated;
grant select, insert, update, delete on public.administrator_profiles to authenticated;
grant select, insert on public.privacy_consents to authenticated;
grant select on public.categories to anon, authenticated;
grant insert, update, delete on public.categories to authenticated;
grant select on public.research_papers to anon, authenticated;
grant insert, update, delete on public.research_papers to authenticated;
grant select, insert on public.paper_views to authenticated;

-- PDFs are private. Store objects under a first-level folder named with the
-- uploader's Auth UUID. Only approved documents are readable publicly.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('research-papers', 'research-papers', false, 2097152, array['application/pdf'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy "Anyone can read approved research PDFs"
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'research-papers'
    and exists (
      select 1 from public.research_papers p
      where p.file_path = storage.objects.name
        and p.status = 'approved'
    )
  );

create policy "Owners and admins can read submitted research PDFs"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'research-papers'
    and (
      (select public.is_admin())
      or (storage.foldername(name))[1] = (select auth.uid())::text
    )
  );

create policy "Users can upload PDFs to their own folder"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'research-papers'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "Owners and admins can update submitted PDFs"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'research-papers'
    and (
      (select public.is_admin())
      or (storage.foldername(name))[1] = (select auth.uid())::text
    )
  )
  with check (
    bucket_id = 'research-papers'
    and (
      (select public.is_admin())
      or (storage.foldername(name))[1] = (select auth.uid())::text
    )
  );

create policy "Owners and admins can delete submitted PDFs"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'research-papers'
    and (
      (select public.is_admin())
      or (storage.foldername(name))[1] = (select auth.uid())::text
    )
  );

-- To promote a verified account, run these statements in the Supabase SQL
-- Editor, replacing the email. Never expose admin role assignment publicly.
-- insert into public.user_roles (user_id, role)
-- select id, 'admin' from auth.users where email = 'admin@example.com'
-- on conflict (user_id) do update set role = 'admin';
-- insert into public.administrator_profiles (user_id, admin_title)
-- select id, 'Repository Administrator'
-- from auth.users where email = 'admin@example.com'
-- on conflict (user_id) do nothing;
