-- E-Ticketing Helpdesk - Supabase Schema
-- Sesuai Software Requirement Specification v2.0.0
-- Role: admin, helpdesk, user (3 role sesuai SRS, technical_support DIHAPUS)

create type user_role as enum ('admin', 'helpdesk', 'user');

create type ticket_status as enum ('open', 'assigned', 'in_progress', 'resolved', 'closed');

create type ticket_priority as enum ('Low', 'Medium', 'High');

create type notification_type as enum (
  'ticket_created',
  'ticket_assigned',
  'ticket_status_changed',
  'ticket_commented',
  'ticket_resolved'
);

-- 2. TABLE: profiles (extends auth.users)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null unique,
  username text not null unique,
  role user_role not null default 'user',
  is_active boolean not null default true,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is 'Data profil pengguna, role: admin/helpdesk/user sesuai SRS 2.2';

-- 3. TABLE: tickets
create table public.tickets (
  id uuid primary key default gen_random_uuid(),
  ticket_number text not null unique, 
  title text not null,
  description text not null,
  category text not null,
  priority ticket_priority not null default 'Medium',
  status ticket_status not null default 'open',

  user_id uuid not null,
  assigned_helpdesk_id uuid,

  resolution_note text,
  resolved_at timestamptz,
  closed_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint tickets_user_id_fkey
    foreign key (user_id) references public.profiles(id) on delete cascade,
  constraint tickets_assigned_helpdesk_id_fkey
    foreign key (assigned_helpdesk_id) references public.profiles(id) on delete set null
);

comment on table public.tickets is 'Tiket keluhan, alur: open -> assigned -> in_progress -> resolved -> closed (FR-005/006/007)';

create index idx_tickets_user_id on public.tickets(user_id);
create index idx_tickets_assigned_helpdesk_id on public.tickets(assigned_helpdesk_id);
create index idx_tickets_status on public.tickets(status);

-- Auto-generate ticket_number
create sequence public.ticket_number_seq start 1;

create or replace function public.generate_ticket_number()
returns trigger as $$
begin
  new.ticket_number := 'TKT-' || lpad(nextval('public.ticket_number_seq')::text, 4, '0');
  return new;
end;
$$ language plpgsql;

create trigger trg_generate_ticket_number
before insert on public.tickets
for each row
when (new.ticket_number is null)
execute function public.generate_ticket_number();

-- Auto-update updated_at
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

create trigger trg_tickets_updated_at
before update on public.tickets
for each row execute function public.set_updated_at();

create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

-- 4. TABLE: ticket_history (Riwayat & Tracking - FR-010, FR-011, BR-005)
create table public.ticket_history (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.tickets(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  actor_name text not null,
  actor_role text not null,
  action text not null, -- 'created', 'assigned', 'status_changed', 'commented', 'resolved'
  from_status ticket_status,
  to_status ticket_status,
  note text,
  created_at timestamptz not null default now()
);

comment on table public.ticket_history is 'Histori perubahan status & aktivitas tiket untuk tracking (BR-005)';

create index idx_ticket_history_ticket_id on public.ticket_history(ticket_id);

-- 5. TABLE: ticket_comments
create table public.ticket_comments (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.tickets(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  author_name text not null,
  author_role text not null,
  message text not null,
  created_at timestamptz not null default now()
);

create index idx_ticket_comments_ticket_id on public.ticket_comments(ticket_id);

-- 6. TABLE: ticket_attachments
create table public.ticket_attachments (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.tickets(id) on delete cascade,
  file_path text not null, -- path di Supabase Storage bucket 'ticket-attachments'
  file_name text not null,
  file_type text not null, -- 'image' | 'document'
  uploaded_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create index idx_ticket_attachments_ticket_id on public.ticket_attachments(ticket_id);

-- 7. TABLE: notifications (FR-008, BR-003)
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  ticket_id uuid references public.tickets(id) on delete cascade,
  type notification_type not null,
  title text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

comment on table public.notifications is 'Notifikasi per user, dikonsumsi via Supabase Realtime (BR-003)';

create index idx_notifications_user_id on public.notifications(user_id);
create index idx_notifications_is_read on public.notifications(user_id, is_read);

-- 8. FUNCTION: handle_new_user (trigger saat auth.users baru dibuat via signUp)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, name, email, username, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    'user' -- default role saat register mandiri selalu 'user'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger trg_on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- 9. FUNCTION: notify on ticket events (trigger -> insert ke notifications)
create or replace function public.notify_ticket_created()
returns trigger as $$
begin
  -- Beritahu semua admin bahwa ada tiket baru
  insert into public.notifications (user_id, ticket_id, type, title, body)
  select p.id, new.id, 'ticket_created',
         'Tiket Baru: ' || new.ticket_number,
         new.title
  from public.profiles p
  where p.role = 'admin';

  insert into public.ticket_history (ticket_id, actor_id, actor_name, actor_role, action, to_status, note)
  values (new.id, new.user_id, (select name from public.profiles where id = new.user_id), 'user', 'created', new.status, 'Tiket dibuat');

  return new;
end;
$$ language plpgsql security definer;

create trigger trg_notify_ticket_created
after insert on public.tickets
for each row execute function public.notify_ticket_created();

create or replace function public.notify_ticket_updated()
returns trigger as $$
declare
  v_actor_name text;
begin
  if new.status is distinct from old.status then
    -- Notifikasi ke pemilik tiket
    insert into public.notifications (user_id, ticket_id, type, title, body)
    values (
      new.user_id, new.id, 'ticket_status_changed',
      'Status Tiket Diperbarui: ' || new.ticket_number,
      'Status berubah menjadi ' || new.status::text
    );

    -- Notifikasi ke helpdesk yang ditugaskan (jika ada & bukan dia sendiri yg update)
    if new.assigned_helpdesk_id is not null then
      insert into public.notifications (user_id, ticket_id, type, title, body)
      values (
        new.assigned_helpdesk_id, new.id, 'ticket_status_changed',
        'Status Tiket Diperbarui: ' || new.ticket_number,
        'Status berubah menjadi ' || new.status::text
      );
    end if;

    insert into public.ticket_history (ticket_id, actor_id, actor_name, actor_role, action, from_status, to_status)
    values (new.id, new.assigned_helpdesk_id, coalesce((select name from public.profiles where id = new.assigned_helpdesk_id), 'System'), 'system', 'status_changed', old.status, new.status);
  end if;

  if new.assigned_helpdesk_id is distinct from old.assigned_helpdesk_id and new.assigned_helpdesk_id is not null then
    insert into public.notifications (user_id, ticket_id, type, title, body)
    values (
      new.assigned_helpdesk_id, new.id, 'ticket_assigned',
      'Tiket Ditugaskan: ' || new.ticket_number,
      new.title
    );
  end if;

  return new;
end;
$$ language plpgsql security definer;

create trigger trg_notify_ticket_updated
after update on public.tickets
for each row execute function public.notify_ticket_updated();

create or replace function public.notify_ticket_commented()
returns trigger as $$
declare
  v_ticket public.tickets;
begin
  select * into v_ticket from public.tickets where id = new.ticket_id;

  -- Notify ke pemilik tiket (jika bukan dia yang komen)
  if v_ticket.user_id != new.author_id then
    insert into public.notifications (user_id, ticket_id, type, title, body)
    values (v_ticket.user_id, new.ticket_id, 'ticket_commented', 'Komentar Baru: ' || v_ticket.ticket_number, new.message);
  end if;

  -- Notify ke helpdesk yang ditugaskan (jika bukan dia yang komen)
  if v_ticket.assigned_helpdesk_id is not null and v_ticket.assigned_helpdesk_id != new.author_id then
    insert into public.notifications (user_id, ticket_id, type, title, body)
    values (v_ticket.assigned_helpdesk_id, new.ticket_id, 'ticket_commented', 'Komentar Baru: ' || v_ticket.ticket_number, new.message);
  end if;

  insert into public.ticket_history (ticket_id, actor_id, actor_name, actor_role, action, note)
  values (new.ticket_id, new.author_id, new.author_name, new.author_role, 'commented', new.message);

  return new;
end;
$$ language plpgsql security definer;

create trigger trg_notify_ticket_commented
after insert on public.ticket_comments
for each row execute function public.notify_ticket_commented();

-- 10. ROW LEVEL SECURITY
alter table public.profiles enable row level security;
alter table public.tickets enable row level security;
alter table public.ticket_history enable row level security;
alter table public.ticket_comments enable row level security;
alter table public.ticket_attachments enable row level security;
alter table public.notifications enable row level security;

-- Helper: cek role user yang sedang login
create or replace function public.current_user_role()
returns user_role as $$
  select role from public.profiles where id = auth.uid();
$$ language sql security definer stable;

-- PROFILES policies
create policy "Profiles: user can view own profile" on public.profiles
  for select using (id = auth.uid());

create policy "Profiles: admin & helpdesk can view all profiles" on public.profiles
  for select using (public.current_user_role() in ('admin', 'helpdesk'));

create policy "Profiles: user can update own profile" on public.profiles
  for update using (id = auth.uid());

create policy "Profiles: admin can update any profile" on public.profiles
  for update using (public.current_user_role() = 'admin');

create policy "Profiles: admin can insert profile" on public.profiles
  for insert with check (public.current_user_role() = 'admin');

-- TICKETS policies
create policy "Tickets: user can view own tickets" on public.tickets
  for select using (user_id = auth.uid());

create policy "Tickets: helpdesk can view assigned or unassigned tickets" on public.tickets
  for select using (
    public.current_user_role() = 'helpdesk'
    and (assigned_helpdesk_id = auth.uid() or assigned_helpdesk_id is null)
  );

create policy "Tickets: admin can view all tickets" on public.tickets
  for select using (public.current_user_role() = 'admin');

create policy "Tickets: user can create own ticket" on public.tickets
  for insert with check (user_id = auth.uid());

create policy "Tickets: admin can create ticket for anyone" on public.tickets
  for insert with check (public.current_user_role() = 'admin');

create policy "Tickets: admin can update any ticket" on public.tickets
  for update using (public.current_user_role() = 'admin');

create policy "Tickets: helpdesk can update assigned ticket" on public.tickets
  for update using (
    public.current_user_role() = 'helpdesk'
    and (assigned_helpdesk_id = auth.uid() or assigned_helpdesk_id is null)
  );

create policy "Tickets: user can update own open ticket (limited)" on public.tickets
  for update using (user_id = auth.uid() and status = 'open');

-- TICKET_HISTORY policies (read scoped to ticket access)
create policy "History: view if can view related ticket" on public.ticket_history
  for select using (
    exists (
      select 1 from public.tickets t
      where t.id = ticket_history.ticket_id
      and (
        t.user_id = auth.uid()
        or t.assigned_helpdesk_id = auth.uid()
        or public.current_user_role() = 'admin'
      )
    )
  );

create policy "History: system insert via trigger" on public.ticket_history
  for insert with check (true);

-- TICKET_COMMENTS policies
create policy "Comments: view if can view related ticket" on public.ticket_comments
  for select using (
    exists (
      select 1 from public.tickets t
      where t.id = ticket_comments.ticket_id
      and (
        t.user_id = auth.uid()
        or t.assigned_helpdesk_id = auth.uid()
        or public.current_user_role() = 'admin'
      )
    )
  );

create policy "Comments: insert if can view related ticket" on public.ticket_comments
  for insert with check (
    author_id = auth.uid()
    and exists (
      select 1 from public.tickets t
      where t.id = ticket_comments.ticket_id
      and (
        t.user_id = auth.uid()
        or t.assigned_helpdesk_id = auth.uid()
        or public.current_user_role() = 'admin'
      )
    )
  );

-- TICKET_ATTACHMENTS policies
create policy "Attachments: view if can view related ticket" on public.ticket_attachments
  for select using (
    exists (
      select 1 from public.tickets t
      where t.id = ticket_attachments.ticket_id
      and (
        t.user_id = auth.uid()
        or t.assigned_helpdesk_id = auth.uid()
        or public.current_user_role() = 'admin'
      )
    )
  );

create policy "Attachments: insert own ticket attachment" on public.ticket_attachments
  for insert with check (
    uploaded_by = auth.uid()
    and exists (
      select 1 from public.tickets t
      where t.id = ticket_attachments.ticket_id
      and (
        t.user_id = auth.uid()
        or t.assigned_helpdesk_id = auth.uid()
        or public.current_user_role() = 'admin'
      )
    )
  );

-- NOTIFICATIONS policies
create policy "Notifications: user can view own notifications" on public.notifications
  for select using (user_id = auth.uid());

create policy "Notifications: user can update own (mark as read)" on public.notifications
  for update using (user_id = auth.uid());

create policy "Notifications: system insert via trigger" on public.notifications
  for insert with check (true);

-- 11. REALTIME (BR-003: Supabase Realtime)
alter publication supabase_realtime add table public.tickets;
alter publication supabase_realtime add table public.ticket_comments;
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.ticket_history;

-- 12. STORAGE BUCKET
insert into storage.buckets (id, name, public)
values ('ticket-attachments', 'ticket-attachments', false)
on conflict (id) do nothing;

create policy "Storage: authenticated users can upload attachments"
on storage.objects for insert
with check (bucket_id = 'ticket-attachments' and auth.role() = 'authenticated');

create policy "Storage: authenticated users can view attachments"
on storage.objects for select
using (bucket_id = 'ticket-attachments' and auth.role() = 'authenticated');

-- update public.profiles set role = 'admin' where email = 'admin@helpdesk.unair.ac.id';
-- update public.profiles set role = 'helpdesk' where email = 'helpdesk@helpdesk.unair.ac.id';
