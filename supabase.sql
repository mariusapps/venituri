-- Rulează o singură dată în Supabase > SQL Editor.
-- Fiecare utilizator își vede doar propriile rânduri (RLS).

create table if not exists public.venituri_extra (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  data date not null,
  tip text not null,   -- id-ul categoriei (categoriile sunt definite de utilizator, în Setări)
  suma numeric not null,
  moneda text not null default 'RON' check (moneda in ('RON','USD','EUR')),
  curs numeric not null default 1,
  nota text,
  created_at timestamptz not null default now()
);

create index if not exists venituri_extra_user_data_idx on public.venituri_extra (user_id, data);

alter table public.venituri_extra enable row level security;
drop policy if exists "venituri_extra own rows" on public.venituri_extra;
create policy "venituri_extra own rows" on public.venituri_extra
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create table if not exists public.venituri_extra_setari (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.venituri_extra_setari enable row level security;
drop policy if exists "venituri_extra_setari own row" on public.venituri_extra_setari;
create policy "venituri_extra_setari own row" on public.venituri_extra_setari
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Dacă ai creat deja tabelul cu versiunea veche, rulează și asta (o singură dată),
-- ca să poți salva categorii proprii:
alter table public.venituri_extra drop constraint if exists venituri_extra_tip_check;
