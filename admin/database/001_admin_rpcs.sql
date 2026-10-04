-- Seculate admin: server-side functions. Every function checks has_permission() (which also requires a
-- 2-step-verified session, aal2) before it reads or changes anything, and every sensitive read or change is audited.
-- Run once in the Supabase SQL editor. Contains no secrets.

-- ---------- permissions ----------
insert into public.role_permissions(role, permission)
select r, p from (values
  ('admin','subscriptions.manage'),('finance','subscriptions.manage'),
  ('admin','reviews.moderate'),('moderator','reviews.moderate'),
  ('admin','users.notify'),('support','users.notify'),('moderator','users.notify'),
  ('admin','users.notes'),('support','users.notes'),('moderator','users.notes'),('compliance','users.notes'),('finance','users.notes'),
  ('admin','payments.read'),('support','reports.read'),('admin','reports.read'),('moderator','reports.read'),('compliance','reports.read')
) v(r,p)
where not exists (select 1 from public.role_permissions x where x.role = v.r and x.permission = v.p);

-- ---------- notes table (only reachable through the functions below) ----------
create table if not exists public.user_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  author_id uuid,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);
alter table public.user_notes enable row level security;
revoke all on public.user_notes from anon, authenticated;

-- ---------- helpers ----------
create or replace function public._adm_like(p text) returns text language sql immutable as
$$ select '%' || replace(replace(replace(coalesce(p,''), '\', '\\'), '%', '\%'), '_', '\_') || '%' $$;
create or replace function public._adm_name(p uuid) returns text language sql stable security definer set search_path = public as
$$ select nullif(trim(coalesce(first_name,'') || ' ' || coalesce(last_name,'')), '') from public.profiles where id = p $$;
create or replace function public._adm_today() returns date language sql stable as
$$ select (now() at time zone 'Africa/Lagos')::date $$;
revoke all on function public._adm_like(text), public._adm_name(uuid), public._adm_today() from public, anon, authenticated;

-- ---------- users: search ----------
create or replace function public.admin_user_search(
  p_q text default '', p_status text default null, p_verification text default null, p_plan text default null,
  p_sort text default 'newest', p_limit int default 25, p_offset int default 0) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare q text := btrim(coalesce(p_q,'')); res jsonb; tot int; lim int := least(greatest(coalesce(p_limit,25),1),100);
begin
  if not public.has_permission('users.read') then raise exception 'Not allowed'; end if;
  with base as (
    select p.*, coalesce((select s.plan_id from public.subscriptions s where s.user_id = p.id and s.status in ('active','grace')
        and (s.current_period_end is null or s.current_period_end > now()) order by s.current_period_end desc nulls last limit 1), 'on_code') plan
    from public.profiles p
    where (q = '' or (coalesce(p.first_name,'') || ' ' || coalesce(p.last_name,'')) ilike public._adm_like(q)
        or p.email ilike public._adm_like(q) or coalesce(p.phone,'') ilike public._adm_like(q)
        or coalesce(p.business_name,'') ilike public._adm_like(q) or p.id::text = q or p.id::text ilike (replace(q,'%','') || '%'))
      and (p_status is null or p_status = '' or p.account_status = p_status)
      and (p_verification is null or p_verification = '' or p.verification_status = p_verification))
  select count(*) into tot from base where (p_plan is null or p_plan = '' or plan = p_plan);
  select coalesce(jsonb_agg(to_jsonb(x)), '[]') into res from (
    select b.id, b.first_name, b.last_name, b.email, b.phone, b.avatar_url, b.city, b.verification_status, b.account_status,
           b.violation_count, b.rating_avg, b.rating_count, b.completed_transactions, b.created_at, b.last_seen_at, b.plan,
           (select count(*) from public.listings l where l.owner_id = b.id and l.status <> 'draft') listings
    from (select * from (
      select p.*, coalesce((select s.plan_id from public.subscriptions s where s.user_id = p.id and s.status in ('active','grace')
        and (s.current_period_end is null or s.current_period_end > now()) order by s.current_period_end desc nulls last limit 1), 'on_code') plan
      from public.profiles p
      where (q = '' or (coalesce(p.first_name,'') || ' ' || coalesce(p.last_name,'')) ilike public._adm_like(q)
        or p.email ilike public._adm_like(q) or coalesce(p.phone,'') ilike public._adm_like(q)
        or coalesce(p.business_name,'') ilike public._adm_like(q) or p.id::text = q or p.id::text ilike (replace(q,'%','') || '%'))
        and (p_status is null or p_status = '' or p.account_status = p_status)
        and (p_verification is null or p_verification = '' or p.verification_status = p_verification)) z
      where (p_plan is null or p_plan = '' or z.plan = p_plan)) b
    order by case when p_sort = 'oldest' then b.created_at end asc, case when p_sort = 'active' then b.last_seen_at end desc nulls last,
             case when p_sort = 'violations' then b.violation_count end desc, b.created_at desc
    limit lim offset greatest(coalesce(p_offset,0),0)) x;
  return jsonb_build_object('total', tot, 'rows', res);
end $$;

-- ---------- users: full profile ("CV") ----------
create or replace function public.admin_user_360(p_user uuid) returns jsonb
language plpgsql security definer set search_path = public, auth as $$
declare prof public.profiles; out jsonb; sens boolean; pay boolean; v_last timestamptz; v_created timestamptz; v_conf timestamptz; v_prov jsonb;
begin
  if not public.has_permission('users.read') then raise exception 'Not allowed'; end if;
  select * into prof from public.profiles where id = p_user;
  if not found then raise exception 'User not found'; end if;
  sens := public.has_permission('users.read_sensitive'); pay := public.has_permission('payments.read');
  select u.last_sign_in_at, u.created_at, u.email_confirmed_at, u.raw_app_meta_data->'providers' into v_last, v_created, v_conf, v_prov from auth.users u where u.id = p_user;
  perform public.write_audit('user.view', 'user', p_user::text, null);

  out := jsonb_build_object(
    'access', jsonb_build_object('sensitive', sens, 'payments', pay, 'chats', public.has_permission('chats.review'),
              'notes', public.has_permission('users.notes'), 'notify', public.has_permission('users.notify'),
              'moderate', public.has_permission('users.moderate'), 'plans', public.has_permission('subscriptions.manage')),
    'profile', to_jsonb(prof) - 'must_change_password' - 'onboarding_step',
    'auth', jsonb_build_object('last_sign_in_at', v_last, 'created_at', v_created, 'email_confirmed_at', v_conf, 'providers', v_prov),
    'plan', (select to_jsonb(s) || jsonb_build_object('plan_name', sp.name, 'price', sp.price_ngn) from public.subscriptions s join public.subscription_plans sp on sp.id = s.plan_id
             where s.user_id = p_user and s.status in ('active','grace') and (s.current_period_end is null or s.current_period_end > now())
             order by s.current_period_end desc nulls last limit 1),
    'subscriptions', coalesce((select jsonb_agg(to_jsonb(s) || jsonb_build_object('plan_name', sp.name) order by s.created_at desc) from (select * from public.subscriptions where user_id = p_user order by created_at desc limit 20) s join public.subscription_plans sp on sp.id = s.plan_id), '[]'),
    'verification', coalesce((select jsonb_agg(jsonb_build_object('id', v.id, 'doc_type', v.doc_type, 'provider', v.provider, 'status', v.status, 'verified_name', v.verified_name,
              'id_last4', case when sens then v.id_last4 end, 'failure_reason', v.failure_reason, 'created_at', v.created_at) order by v.created_at desc) from public.verification_records v where v.user_id = p_user), '[]'),
    'stats', jsonb_build_object(
      'listings_total', (select count(*) from public.listings where owner_id = p_user and status <> 'draft'),
      'listings_live', (select count(*) from public.listings where owner_id = p_user and status in ('live','reserved')),
      'tasks_posted', (select count(*) from public.tasks where requester_id = p_user and status <> 'draft'),
      'tx_as_borrower', (select count(*) from public.transactions where payer_id = p_user),
      'tx_as_lender', (select count(*) from public.transactions where payee_id = p_user),
      'tx_value', (select coalesce(sum(amount),0) from public.transactions where (payer_id = p_user or payee_id = p_user) and state in ('released','confirmed','release_pending')),
      'paid_total', case when pay then (select coalesce(sum(amount),0) from public.payments where user_id = p_user and status = 'successful') end,
      'reviews_received', (select count(*) from public.reviews where reviewee_id = p_user and status = 'published'),
      'reviews_given', (select count(*) from public.reviews where reviewer_id = p_user),
      'reports_against', (select count(*) from public.reports where target_id = p_user::text and target_type = 'user'),
      'reports_filed', (select count(*) from public.reports where reporter_id = p_user),
      'violations', (select count(*) from public.violations where user_id = p_user),
      'disputes', (select count(*) from public.disputes d join public.transactions t on t.id = d.transaction_id where t.payer_id = p_user or t.payee_id = p_user),
      'tickets', (select count(*) from public.support_tickets where user_id = p_user),
      'conversations', (select count(*) from public.conversation_members where user_id = p_user),
      'messages_sent', (select count(*) from public.messages where sender_id = p_user),
      'flagged_messages', (select count(*) from public.messages where sender_id = p_user and flagged),
      'blocked_by', (select count(*) from public.user_blocks where blocked_id = p_user),
      'blocking', (select count(*) from public.user_blocks where blocker_id = p_user),
      'unread_notifications', (select count(*) from public.notifications where user_id = p_user and read_at is null)),
    'devices', coalesce((select jsonb_agg(jsonb_build_object('platform', platform, 'since', created_at)) from public.push_tokens where user_id = p_user), '[]'),
    'listings', coalesce((select jsonb_agg(x) from (select id, title, kind, status, category_label, price_per_day, collateral, rating_avg, rating_count, created_at from public.listings where owner_id = p_user and status <> 'draft' order by created_at desc limit 50) x), '[]'),
    'tasks', coalesce((select jsonb_agg(x) from (select id, title, status, category_label, proposed_price, agreed_price, created_at from public.tasks where requester_id = p_user and status <> 'draft' order by created_at desc limit 50) x), '[]'),
    'transactions', coalesce((select jsonb_agg(x) from (select t.id, t.title, t.kind, t.state, t.amount, t.collateral, t.created_at,
         case when t.payer_id = p_user then 'borrower' else 'lender' end role, public._adm_name(case when t.payer_id = p_user then t.payee_id else t.payer_id end) other_party,
         case when t.payer_id = p_user then t.payee_id else t.payer_id end other_id
         from public.transactions t where t.payer_id = p_user or t.payee_id = p_user order by t.created_at desc limit 50) x), '[]'),
    'payments', case when pay then coalesce((select jsonb_agg(x) from (select id, purpose, amount, status, plan_id, tx_ref, created_at from public.payments where user_id = p_user order by created_at desc limit 50) x), '[]') end,
    'reviews_received', coalesce((select jsonb_agg(x) from (select r.id, r.rating, r.body, r.status, r.created_at, public._adm_name(r.reviewer_id) reviewer, r.reviewer_id from public.reviews r where r.reviewee_id = p_user order by r.created_at desc limit 50) x), '[]'),
    'reviews_given', coalesce((select jsonb_agg(x) from (select r.id, r.rating, r.body, r.status, r.created_at, public._adm_name(r.reviewee_id) reviewee, r.reviewee_id from public.reviews r where r.reviewer_id = p_user order by r.created_at desc limit 50) x), '[]'),
    'reports_against', coalesce((select jsonb_agg(x) from (select r.id, r.reason, r.details, r.status, r.created_at, public._adm_name(r.reporter_id) reporter, r.reporter_id from public.reports r where r.target_type = 'user' and r.target_id = p_user::text order by r.created_at desc limit 50) x), '[]'),
    'reports_filed', coalesce((select jsonb_agg(x) from (select r.id, r.target_type, r.target_id, r.reason, r.status, r.created_at from public.reports r where r.reporter_id = p_user order by r.created_at desc limit 50) x), '[]'),
    'violations', coalesce((select jsonb_agg(x) from (select id, source, severity, note, created_at from public.violations where user_id = p_user order by created_at desc limit 50) x), '[]'),
    'suspensions', coalesce((select jsonb_agg(x) from (select id, kind, status, reason, starts_at, ends_at, created_at from public.account_suspensions where user_id = p_user order by created_at desc limit 20) x), '[]'),
    'disputes', coalesce((select jsonb_agg(x) from (select d.id, d.status, d.reason, d.created_at, t.title, t.amount from public.disputes d join public.transactions t on t.id = d.transaction_id where t.payer_id = p_user or t.payee_id = p_user order by d.created_at desc limit 30) x), '[]'),
    'tickets', coalesce((select jsonb_agg(x) from (select id, subject, category, status, priority, created_at from public.support_tickets where user_id = p_user order by created_at desc limit 30) x), '[]'),
    'notes', case when public.has_permission('users.notes') then coalesce((select jsonb_agg(x) from (select n.id, n.body, n.created_at, public._adm_name(n.author_id) author from public.user_notes n where n.user_id = p_user order by n.created_at desc limit 50) x), '[]') end,
    'staff_actions', coalesce((select jsonb_agg(x) from (select created_at, actor_role, action, reason from public.audit_logs where target_type = 'user' and target_id = p_user::text and action <> 'user.view' order by created_at desc limit 30) x), '[]'));

  out := out || jsonb_build_object('timeline', coalesce((select jsonb_agg(to_jsonb(e) order by e.ts desc) from (
      select * from (
        select created_at ts, 'joined' kind, 'Joined Seculate' label from public.profiles where id = p_user
        union all select created_at, 'listing', 'Posted ' || kind || ': ' || title from public.listings where owner_id = p_user and status <> 'draft'
        union all select created_at, 'task', 'Posted errand: ' || title from public.tasks where requester_id = p_user and status <> 'draft'
        union all select created_at, 'transaction', 'Deal "' || title || '" (' || state || ')' from public.transactions where payer_id = p_user or payee_id = p_user
        union all select created_at, 'review', 'Reviewed someone (' || rating || ' stars)' from public.reviews where reviewer_id = p_user
        union all select created_at, 'review', 'Received a ' || rating || '-star review' from public.reviews where reviewee_id = p_user
        union all select created_at, 'report', 'Reported: ' || reason from public.reports where reporter_id = p_user
        union all select created_at, 'report', 'Was reported: ' || reason from public.reports where target_type = 'user' and target_id = p_user::text
        union all select created_at, 'violation', 'Violation (sev ' || severity || '): ' || coalesce(note,'') from public.violations where user_id = p_user
        union all select created_at, 'ticket', 'Support ticket: ' || subject from public.support_tickets where user_id = p_user
        union all select created_at, 'payment', 'Payment ' || status || ' (' || purpose || ')' from public.payments where user_id = p_user and pay
        union all select created_at, 'plan', 'Plan ' || plan_id || ' (' || status || ')' from public.subscriptions where user_id = p_user
        union all select created_at, 'verification', 'Identity check: ' || status from public.verification_records where user_id = p_user
        union all select v_last, 'login', 'Last sign-in' where v_last is not null
      ) u order by ts desc limit 80) e), '[]'));
  return out;
end $$;

-- ---------- users: conversations (chat history is listed here, read per-chat with a reason) ----------
create or replace function public.admin_user_conversations(p_user uuid, p_reason text) returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  if not public.has_permission('chats.review') then raise exception 'Not allowed'; end if;
  if coalesce(btrim(p_reason),'') = '' then raise exception 'A reason is required'; end if;
  perform public.write_audit('chat.list', 'user', p_user::text, p_reason);
  return coalesce((select jsonb_agg(x order by x.last_message_at desc nulls last) from (
    select c.id, c.kind, c.last_message_at, c.created_at,
      (select l.title from public.listings l where l.id = c.listing_id) listing_title,
      (select count(*) from public.messages m where m.conversation_id = c.id) messages,
      (select count(*) from public.messages m where m.conversation_id = c.id and m.flagged) flagged,
      (select jsonb_agg(jsonb_build_object('id', cm.user_id, 'name', public._adm_name(cm.user_id))) from public.conversation_members cm where cm.conversation_id = c.id) members
    from public.conversations c where c.id in (select conversation_id from public.conversation_members where user_id = p_user) order by c.last_message_at desc nulls last limit 100) x), '[]');
end $$;

-- ---------- users: notes, notifications ----------
create or replace function public.admin_add_note(p_user uuid, p_body text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.has_permission('users.notes') then raise exception 'Not allowed'; end if;
  if char_length(btrim(coalesce(p_body,''))) < 1 then raise exception 'Write a note first'; end if;
  insert into public.user_notes(user_id, author_id, body) values (p_user, (select auth.uid()), left(btrim(p_body), 2000));
  perform public.write_audit('user.note', 'user', p_user::text, left(btrim(p_body), 200));
end $$;

create or replace function public.admin_notify_user(p_user uuid, p_title text, p_body text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.has_permission('users.notify') then raise exception 'Not allowed'; end if;
  if char_length(btrim(coalesce(p_title,''))) < 2 or char_length(btrim(coalesce(p_body,''))) < 2 then raise exception 'Add a title and a message'; end if;
  perform public.notify(p_user, 'announcement', left(btrim(p_title), 80), left(btrim(p_body), 500), 'support', null);
  perform public.write_audit('user.notify', 'user', p_user::text, left(btrim(p_title), 80));
end $$;

create or replace function public.admin_broadcast(p_title text, p_body text, p_audience text default 'all') returns int
language plpgsql security definer set search_path = public as $$
declare n int := 0; r record; sent_today int;
begin
  if not public.has_permission('users.notify') or not public.has_permission('settings.manage') then raise exception 'Not allowed'; end if;
  if char_length(btrim(coalesce(p_title,''))) < 2 or char_length(btrim(coalesce(p_body,''))) < 2 then raise exception 'Add a title and a message'; end if;
  select count(*) into sent_today from public.audit_logs where action = 'broadcast' and created_at > now() - interval '24 hours';
  if sent_today >= 3 then raise exception 'Daily broadcast limit reached'; end if;
  for r in select id from public.profiles where account_status = 'active' and (
       p_audience = 'all' or (p_audience = 'verified' and verification_status = 'verified')
       or (p_audience like 'plan:%' and exists (select 1 from public.subscriptions s where s.user_id = profiles.id and s.status = 'active' and s.plan_id = substr(p_audience, 6)))) loop
    perform public.notify(r.id, 'announcement', left(btrim(p_title), 80), left(btrim(p_body), 500), 'announcement', null); n := n + 1;
  end loop;
  perform public.write_audit('broadcast', 'audience', p_audience, left(btrim(p_title), 80), jsonb_build_object('recipients', n));
  return n;
end $$;

-- ---------- plans ----------
create or replace function public.admin_grant_plan(p_user uuid, p_plan text, p_days int, p_reason text) returns void
language plpgsql security definer set search_path = public as $$
declare pl public.subscription_plans; d int := least(greatest(coalesce(p_days,30),1),365);
begin
  if not public.has_permission('subscriptions.manage') then raise exception 'Not allowed'; end if;
  if coalesce(btrim(p_reason),'') = '' then raise exception 'A reason is required'; end if;
  select * into pl from public.subscription_plans where id = p_plan and is_active;
  if not found then raise exception 'Unknown plan'; end if;
  update public.subscriptions set status = 'cancelled', updated_at = now() where user_id = p_user and status in ('active','grace');
  insert into public.subscriptions(user_id, plan_id, status, current_period_start, current_period_end, payment_ref)
    values (p_user, p_plan, 'active', now(), now() + make_interval(days => d), 'staff_grant');
  perform public.write_audit('plan.grant', 'user', p_user::text, p_reason, jsonb_build_object('plan', p_plan, 'days', d));
  perform public.notify(p_user, 'payment_plan', 'Your plan was updated', 'You are now on the ' || pl.name || ' plan for ' || d || ' days.', 'plan', p_plan);
end $$;

-- ---------- lists with names (support can finally see who is who) ----------
create or replace function public.admin_list_tickets(p_status text default null, p_q text default '', p_limit int default 50, p_offset int default 0) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare q text := btrim(coalesce(p_q,'')); tot int;
begin
  if not public.has_permission('tickets.manage') then raise exception 'Not allowed'; end if;
  select count(*) into tot from public.support_tickets t join public.profiles u on u.id = t.user_id
    where (p_status is null or p_status = '' or t.status = p_status) and (q = '' or t.subject ilike public._adm_like(q) or u.email ilike public._adm_like(q) or (coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')) ilike public._adm_like(q));
  return jsonb_build_object('total', tot, 'rows', coalesce((select jsonb_agg(x) from (
    select t.id, t.subject, t.category, t.status, t.priority, t.created_at, t.updated_at, t.user_id, u.email user_email, u.phone user_phone,
           public._adm_name(t.user_id) user_name, public._adm_name(t.assigned_to) assignee,
           (select count(*) from public.support_messages m where m.ticket_id = t.id) messages
    from public.support_tickets t join public.profiles u on u.id = t.user_id
    where (p_status is null or p_status = '' or t.status = p_status) and (q = '' or t.subject ilike public._adm_like(q) or u.email ilike public._adm_like(q) or (coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')) ilike public._adm_like(q))
    order by case t.priority when 'urgent' then 0 when 'high' then 1 when 'normal' then 2 else 3 end, t.updated_at desc
    limit least(greatest(p_limit,1),100) offset greatest(p_offset,0)) x), '[]'));
end $$;

create or replace function public.admin_ticket_detail(p_ticket uuid) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare t public.support_tickets;
begin
  if not public.has_permission('tickets.manage') then raise exception 'Not allowed'; end if;
  select * into t from public.support_tickets where id = p_ticket;
  if not found then raise exception 'Ticket not found'; end if;
  return jsonb_build_object('ticket', to_jsonb(t),
    'user', (select jsonb_build_object('id', u.id, 'name', public._adm_name(u.id), 'email', u.email, 'phone', u.phone, 'avatar_url', u.avatar_url, 'account_status', u.account_status, 'verification_status', u.verification_status, 'joined', u.created_at) from public.profiles u where u.id = t.user_id),
    'transaction', (select jsonb_build_object('id', x.id, 'title', x.title, 'state', x.state, 'amount', x.amount) from public.transactions x where x.id = t.transaction_id),
    'messages', coalesce((select jsonb_agg(jsonb_build_object('id', m.id, 'body', m.body, 'is_staff', m.is_staff, 'internal', m.internal, 'created_at', m.created_at, 'sender', public._adm_name(m.sender_id)) order by m.created_at) from public.support_messages m where m.ticket_id = t.id), '[]'));
end $$;

create or replace function public.admin_list_listings(p_kind text default null, p_status text default null, p_q text default '', p_limit int default 50, p_offset int default 0) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare q text := btrim(coalesce(p_q,'')); tot int;
begin
  if not public.has_permission('listings.moderate') then raise exception 'Not allowed'; end if;
  select count(*) into tot from public.listings l join public.profiles u on u.id = l.owner_id where l.status <> 'draft'
    and (p_kind is null or p_kind = '' or l.kind = p_kind) and (p_status is null or p_status = '' or l.status = p_status)
    and (q = '' or l.title ilike public._adm_like(q) or u.email ilike public._adm_like(q) or (coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')) ilike public._adm_like(q));
  return jsonb_build_object('total', tot, 'rows', coalesce((select jsonb_agg(x) from (
    select l.id, l.kind, l.title, l.description, l.features, l.category_label, l.sub_category, l.price_per_day, l.collateral, l.stock, l.lending_period, l.availability,
           l.delivery_option, l.location_label, l.status, l.review_note, l.risk_score, l.submitted_at, l.created_at, l.expires_at, l.rating_avg, l.rating_count, l.featured_until,
           l.owner_id, public._adm_name(l.owner_id) owner_name, u.email owner_email, u.verification_status owner_verification,
           coalesce((select jsonb_agg(i.path order by i.sort_order) from public.listing_images i where i.listing_id = l.id), '[]') images
    from public.listings l join public.profiles u on u.id = l.owner_id where l.status <> 'draft'
      and (p_kind is null or p_kind = '' or l.kind = p_kind) and (p_status is null or p_status = '' or l.status = p_status)
      and (q = '' or l.title ilike public._adm_like(q) or u.email ilike public._adm_like(q) or (coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')) ilike public._adm_like(q))
    order by (l.status = 'pending_review') desc, coalesce(l.submitted_at, l.created_at) desc
    limit least(greatest(p_limit,1),100) offset greatest(p_offset,0)) x), '[]'));
end $$;

create or replace function public.admin_list_tasks(p_status text default null, p_q text default '', p_limit int default 50, p_offset int default 0) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare q text := btrim(coalesce(p_q,'')); tot int;
begin
  if not public.has_permission('tasks.moderate') then raise exception 'Not allowed'; end if;
  select count(*) into tot from public.tasks t join public.profiles u on u.id = t.requester_id where t.status <> 'draft'
    and (p_status is null or p_status = '' or t.status = p_status)
    and (q = '' or t.title ilike public._adm_like(q) or u.email ilike public._adm_like(q) or (coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')) ilike public._adm_like(q));
  return jsonb_build_object('total', tot, 'rows', coalesce((select jsonb_agg(x) from (
    select t.id, t.title, t.description, t.category_label, t.proposed_price, t.agreed_price, t.location_label, t.needed_by, t.status, t.review_note, t.risk_score, t.created_at,
           t.requester_id, public._adm_name(t.requester_id) requester_name, u.email requester_email, public._adm_name(t.worker_id) worker_name,
           coalesce((select jsonb_agg(i.path) from public.task_images i where i.task_id = t.id), '[]') images
    from public.tasks t join public.profiles u on u.id = t.requester_id where t.status <> 'draft'
      and (p_status is null or p_status = '' or t.status = p_status)
      and (q = '' or t.title ilike public._adm_like(q) or u.email ilike public._adm_like(q) or (coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')) ilike public._adm_like(q))
    order by (t.status = 'pending_review') desc, t.created_at desc
    limit least(greatest(p_limit,1),100) offset greatest(p_offset,0)) x), '[]'));
end $$;

create or replace function public.admin_list_transactions(p_state text default null, p_q text default '', p_limit int default 50, p_offset int default 0) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare q text := btrim(coalesce(p_q,'')); tot int;
begin
  if not (public.has_permission('payments.read') or public.has_permission('disputes.read')) then raise exception 'Not allowed'; end if;
  select count(*) into tot from public.transactions t where (p_state is null or p_state = '' or t.state = p_state)
    and (q = '' or t.title ilike public._adm_like(q) or t.tx_ref ilike public._adm_like(q) or public._adm_name(t.payer_id) ilike public._adm_like(q) or public._adm_name(t.payee_id) ilike public._adm_like(q));
  return jsonb_build_object('total', tot, 'rows', coalesce((select jsonb_agg(x) from (
    select t.id, t.title, t.kind, t.state, t.amount, t.collateral, t.platform_fee, t.rental_days, t.start_date, t.due_date, t.tx_ref, t.created_at, t.state_changed_at,
           t.payer_id, public._adm_name(t.payer_id) payer_name, (select email from public.profiles where id = t.payer_id) payer_email,
           t.payee_id, public._adm_name(t.payee_id) payee_name, (select email from public.profiles where id = t.payee_id) payee_email,
           (select e.status from public.escrow_transactions e where e.transaction_id = t.id order by e.created_at desc limit 1) escrow_status
    from public.transactions t where (p_state is null or p_state = '' or t.state = p_state)
      and (q = '' or t.title ilike public._adm_like(q) or t.tx_ref ilike public._adm_like(q) or public._adm_name(t.payer_id) ilike public._adm_like(q) or public._adm_name(t.payee_id) ilike public._adm_like(q))
    order by t.created_at desc limit least(greatest(p_limit,1),100) offset greatest(p_offset,0)) x), '[]'));
end $$;

create or replace function public.admin_list_payments(p_status text default null, p_purpose text default null, p_q text default '', p_limit int default 50, p_offset int default 0) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare q text := btrim(coalesce(p_q,'')); tot int;
begin
  if not public.has_permission('payments.read') then raise exception 'Not allowed'; end if;
  select count(*) into tot from public.payments p join public.profiles u on u.id = p.user_id where (p_status is null or p_status = '' or p.status = p_status) and (p_purpose is null or p_purpose = '' or p.purpose = p_purpose)
    and (q = '' or p.tx_ref ilike public._adm_like(q) or u.email ilike public._adm_like(q) or (coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')) ilike public._adm_like(q));
  return jsonb_build_object('total', tot, 'rows', coalesce((select jsonb_agg(x) from (
    select p.id, p.purpose, p.amount, p.currency, p.status, p.plan_id, p.tx_ref, p.created_at, p.user_id, public._adm_name(p.user_id) user_name, u.email user_email
    from public.payments p join public.profiles u on u.id = p.user_id where (p_status is null or p_status = '' or p.status = p_status) and (p_purpose is null or p_purpose = '' or p.purpose = p_purpose)
      and (q = '' or p.tx_ref ilike public._adm_like(q) or u.email ilike public._adm_like(q) or (coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')) ilike public._adm_like(q))
    order by p.created_at desc limit least(greatest(p_limit,1),100) offset greatest(p_offset,0)) x), '[]'));
end $$;

create or replace function public.admin_list_subscriptions(p_status text default null, p_q text default '', p_limit int default 50, p_offset int default 0) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare q text := btrim(coalesce(p_q,'')); tot int;
begin
  if not (public.has_permission('payments.read') or public.has_permission('subscriptions.manage')) then raise exception 'Not allowed'; end if;
  select count(*) into tot from public.subscriptions s join public.profiles u on u.id = s.user_id where (p_status is null or p_status = '' or s.status = p_status)
    and (q = '' or u.email ilike public._adm_like(q) or (coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')) ilike public._adm_like(q));
  return jsonb_build_object('total', tot,
    'plans', (select coalesce(jsonb_agg(jsonb_build_object('id', sp.id, 'name', sp.name, 'emoji', sp.emoji, 'price', sp.price_ngn, 'item_limit', sp.item_limit_per_month, 'days', sp.listing_duration_days, 'visibility', sp.visibility,
                 'subscribers', (select count(*) from public.subscriptions s where s.plan_id = sp.id and s.status = 'active'),
                 'revenue', (select coalesce(sum(p.amount),0) from public.payments p where p.plan_id = sp.id and p.status = 'successful')) order by sp.sort_order), '[]') from public.subscription_plans sp),
    'rows', coalesce((select jsonb_agg(x) from (
      select s.id, s.plan_id, s.status, s.current_period_start, s.current_period_end, s.payment_ref, s.created_at, s.user_id, public._adm_name(s.user_id) user_name, u.email user_email
      from public.subscriptions s join public.profiles u on u.id = s.user_id where (p_status is null or p_status = '' or s.status = p_status)
        and (q = '' or u.email ilike public._adm_like(q) or (coalesce(u.first_name,'')||' '||coalesce(u.last_name,'')) ilike public._adm_like(q))
      order by s.created_at desc limit least(greatest(p_limit,1),100) offset greatest(p_offset,0)) x), '[]'));
end $$;

create or replace function public.admin_list_reviews(p_status text default null, p_q text default '', p_limit int default 50, p_offset int default 0) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare q text := btrim(coalesce(p_q,'')); tot int;
begin
  if not public.has_permission('reviews.moderate') then raise exception 'Not allowed'; end if;
  select count(*) into tot from public.reviews r where (p_status is null or p_status = '' or r.status = p_status)
    and (q = '' or r.body ilike public._adm_like(q) or public._adm_name(r.reviewer_id) ilike public._adm_like(q) or public._adm_name(r.reviewee_id) ilike public._adm_like(q));
  return jsonb_build_object('total', tot, 'rows', coalesce((select jsonb_agg(x) from (
    select r.id, r.rating, r.body, r.status, r.created_at, r.reviewer_id, public._adm_name(r.reviewer_id) reviewer, r.reviewee_id, public._adm_name(r.reviewee_id) reviewee,
           (select t.title from public.transactions t where t.id = r.transaction_id) deal
    from public.reviews r where (p_status is null or p_status = '' or r.status = p_status)
      and (q = '' or r.body ilike public._adm_like(q) or public._adm_name(r.reviewer_id) ilike public._adm_like(q) or public._adm_name(r.reviewee_id) ilike public._adm_like(q))
    order by r.created_at desc limit least(greatest(p_limit,1),100) offset greatest(p_offset,0)) x), '[]'));
end $$;

create or replace function public.admin_moderate_review(p_id uuid, p_action text, p_note text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.has_permission('reviews.moderate') then raise exception 'Not allowed'; end if;
  if p_action not in ('hide','restore') then raise exception 'Unknown action'; end if;
  if p_action = 'hide' and coalesce(btrim(p_note),'') = '' then raise exception 'A reason is required'; end if;
  update public.reviews set status = case when p_action = 'hide' then 'hidden' else 'published' end where id = p_id;
  perform public.write_audit('review.' || p_action, 'review', p_id::text, p_note);
end $$;

create or replace function public.admin_list_reports(p_status text default 'open', p_limit int default 50, p_offset int default 0) returns jsonb
language plpgsql stable security definer set search_path = public as $$
begin
  if not (public.has_permission('reports.read') or public.has_permission('chats.review')) then raise exception 'Not allowed'; end if;
  return jsonb_build_object('rows', coalesce((select jsonb_agg(x) from (
    select r.id, r.target_type, r.target_id, r.reason, r.details, r.status, r.created_at, r.handled_at, r.reporter_id, public._adm_name(r.reporter_id) reporter, (select email from public.profiles where id = r.reporter_id) reporter_email,
      case r.target_type
        when 'user' then public._adm_name(public.safe_uuid(r.target_id))
        when 'listing' then (select title from public.listings where id = public.safe_uuid(r.target_id))
        when 'task' then (select title from public.tasks where id = public.safe_uuid(r.target_id))
        when 'transaction' then (select title from public.transactions where id = public.safe_uuid(r.target_id))
        when 'review' then (select left(body, 80) from public.reviews where id = public.safe_uuid(r.target_id))
        else null end target_label,
      case r.target_type when 'user' then public.safe_uuid(r.target_id) when 'listing' then (select owner_id from public.listings where id = public.safe_uuid(r.target_id)) when 'task' then (select requester_id from public.tasks where id = public.safe_uuid(r.target_id)) else null end target_user
    from public.reports r where (p_status is null or p_status = '' or r.status = p_status) order by r.created_at desc
    limit least(greatest(p_limit,1),100) offset greatest(p_offset,0)) x), '[]'));
end $$;

create or replace function public.admin_handle_report(p_id uuid, p_status text, p_note text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not (public.has_permission('reports.read') or public.has_permission('chats.review')) then raise exception 'Not allowed'; end if;
  if p_status not in ('reviewing','actioned','dismissed') then raise exception 'Unknown status'; end if;
  update public.reports set status = p_status, handled_by = (select auth.uid()), handled_at = now() where id = p_id;
  perform public.write_audit('report.' || p_status, 'report', p_id::text, p_note);
end $$;

-- ---------- analytics ----------
create or replace function public._adm_series(p_src text, p_days int) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare r jsonb;
begin
  execute format('select coalesce(jsonb_agg(jsonb_build_object(''day'', g.dy, ''value'', coalesce(c.v,0)) order by g.dy), ''[]''::jsonb) from (select (%L::date - n) as dy from generate_series(0, %s - 1) as n) g left join (%s) c on c.dy = g.dy', public._adm_today(), p_days, p_src) into r;
  return r;
end $$;
revoke all on function public._adm_series(text, int) from public, anon, authenticated;

create or replace function public.admin_analytics(p_days int default 30) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare d int := least(greatest(coalesce(p_days,30),7),365);
begin
  if not public.has_permission('analytics.read') then raise exception 'Not allowed'; end if;
  return jsonb_build_object('days', d,
    'series', jsonb_build_object(
      'users', public._adm_series('select (created_at at time zone ''Africa/Lagos'')::date as dy, count(*) as v from public.profiles group by 1', d),
      'listings', public._adm_series('select (created_at at time zone ''Africa/Lagos'')::date as dy, count(*) as v from public.listings where status <> ''draft'' group by 1', d),
      'transactions', public._adm_series('select (created_at at time zone ''Africa/Lagos'')::date as dy, count(*) as v from public.transactions group by 1', d),
      'revenue', public._adm_series('select (created_at at time zone ''Africa/Lagos'')::date as dy, sum(amount) as v from public.payments where status = ''successful'' and purpose = ''subscription'' group by 1', d),
      'disputes', public._adm_series('select (created_at at time zone ''Africa/Lagos'')::date as dy, count(*) as v from public.disputes group by 1', d),
      'reports', public._adm_series('select (created_at at time zone ''Africa/Lagos'')::date as dy, count(*) as v from public.reports group by 1', d)),
    'breakdowns', jsonb_build_object(
      'listings_by_category', (select coalesce(jsonb_agg(x), '[]') from (select coalesce(category_label,'Other') as label, count(*) as value from public.listings where status in ('live','reserved') group by 1 order by 2 desc limit 12) x),
      'users_by_city', (select coalesce(jsonb_agg(x), '[]') from (select coalesce(nullif(city,''),'Unknown') as label, count(*) as value from public.profiles group by 1 order by 2 desc limit 12) x),
      'transactions_by_state', (select coalesce(jsonb_agg(x), '[]') from (select state as label, count(*) as value from public.transactions group by 1 order by 2 desc) x),
      'users_by_verification', (select coalesce(jsonb_agg(x), '[]') from (select verification_status as label, count(*) as value from public.profiles group by 1 order by 2 desc) x),
      'users_by_plan', (select coalesce(jsonb_agg(x), '[]') from (select plan_id as label, count(*) as value from public.subscriptions where status = 'active' group by 1 order by 2 desc) x),
      'reports_by_reason', (select coalesce(jsonb_agg(x), '[]') from (select reason as label, count(*) as value from public.reports group by 1 order by 2 desc limit 8) x)),
    'totals', jsonb_build_object(
      'gmv', (select coalesce(sum(amount),0) from public.transactions where state in ('released','release_pending','confirmed') and created_at > now() - make_interval(days => d)),
      'new_users', (select count(*) from public.profiles where created_at > now() - make_interval(days => d)),
      'plan_revenue', (select coalesce(sum(amount),0) from public.payments where status = 'successful' and purpose = 'subscription' and created_at > now() - make_interval(days => d)),
      'dispute_rate', (select round(100.0 * (select count(*) from public.disputes where created_at > now() - make_interval(days => d)) / greatest((select count(*) from public.transactions where created_at > now() - make_interval(days => d)),1), 1)),
      'avg_rating', (select round(avg(rating)::numeric, 2) from public.reviews where status = 'published')));
end $$;

create or replace function public.admin_timeseries(p_metric text, p_days integer default 30) returns table(day date, value numeric)
language plpgsql stable security definer set search_path = public as $$
declare s jsonb;
begin
  if not public.has_permission('analytics.read') then raise exception 'Not allowed'; end if;
  s := public.admin_analytics(p_days) -> 'series' -> (case p_metric when 'completed' then 'transactions' else p_metric end);
  return query select (e->>'day')::date, (e->>'value')::numeric from jsonb_array_elements(coalesce(s,'[]'::jsonb)) as e;
end $$;

-- ---------- overview ----------
create or replace function public.admin_overview() returns jsonb
language plpgsql stable security definer set search_path = public as $$
begin
  if not (public.has_permission('analytics.read') or public.has_permission('users.read')) then raise exception 'Not allowed'; end if;
  return jsonb_build_object(
    'users_total', (select count(*) from public.profiles),
    'users_verified', (select count(*) from public.profiles where verification_status='verified'),
    'users_new_7d', (select count(*) from public.profiles where created_at > now() - interval '7 days'),
    'users_new_today', (select count(*) from public.profiles where (created_at at time zone 'Africa/Lagos')::date = public._adm_today()),
    'users_active_7d', (select count(*) from public.profiles where last_seen_at > now() - interval '7 days'),
    'users_suspended', (select count(*) from public.profiles where account_status in ('suspended','banned')),
    'listings_live', (select count(*) from public.listings where status in ('live','reserved') and kind='item'),
    'services_live', (select count(*) from public.listings where status in ('live','reserved') and kind='service'),
    'listings_pending', (select count(*) from public.listings where status='pending_review'),
    'tasks_pending', (select count(*) from public.tasks where status='pending_review'),
    'tasks_open', (select count(*) from public.tasks where status='open'),
    'transactions_total', (select count(*) from public.transactions),
    'transactions_active', (select count(*) from public.transactions where state in ('escrow_held','active','return_pending')),
    'release_pending', (select count(*) from public.transactions where state = 'release_pending'),
    'transaction_volume', (select coalesce(sum(amount),0) from public.transactions where state in ('released','release_pending','confirmed')),
    'escrow_held', (select coalesce(sum(amount+collateral),0) from public.escrow_transactions where status in ('held','locked_dispute','release_approved')),
    'subscription_revenue', (select coalesce(sum(amount),0) from public.payments where purpose='subscription' and status='successful'),
    'revenue_30d', (select coalesce(sum(amount),0) from public.payments where purpose='subscription' and status='successful' and created_at > now() - interval '30 days'),
    'payments_ok', (select count(*) from public.payments where status='successful'),
    'payments_failed', (select count(*) from public.payments where status in ('failed','abandoned')),
    'disputes_open', (select count(*) from public.disputes where status not in ('RESOLVED','REFUNDED','RELEASED','CLOSED')),
    'reports_open', (select count(*) from public.reports where status='open'),
    'flagged_chats', (select count(*) from public.message_flags where status='open'),
    'tickets_open', (select count(*) from public.support_tickets where status in ('open','escalated')),
    'reviews_flagged', (select count(*) from public.reviews where status = 'flagged'),
    'avg_rating', (select round(avg(rating)::numeric, 2) from public.reviews where status = 'published'),
    'subs_by_plan', (select coalesce(jsonb_object_agg(plan_id, c), '{}'::jsonb) from (select plan_id, count(*) as c from public.subscriptions where status='active' group by 1) s));
end $$;

-- ---------- categories ----------
create or replace function public.admin_list_categories() returns jsonb
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.has_permission('settings.manage') then raise exception 'Not allowed'; end if;
  return coalesce((select jsonb_agg(x order by x.kind, x.sort_order, x.label) from (
    select c.id, c.kind, c.label, c.slug, c.parent_id, c.sort_order, c.is_active, (select label from public.categories p where p.id = c.parent_id) parent_label,
           (select count(*) from public.listings l where l.category_id = c.id and l.status in ('live','reserved')) live_listings,
           (select count(*) from public.tasks t where t.category_id = c.id and t.status = 'open') open_tasks
    from public.categories c) x), '[]');
end $$;
create or replace function public.admin_set_category(p_id uuid, p_active boolean, p_label text default null) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.has_permission('settings.manage') then raise exception 'Not allowed'; end if;
  update public.categories set is_active = coalesce(p_active, is_active), label = coalesce(nullif(btrim(p_label),''), label) where id = p_id;
  perform public.write_audit('category.update', 'category', p_id::text, null, jsonb_build_object('active', p_active, 'label', p_label));
end $$;
create or replace function public.admin_add_category(p_kind text, p_parent uuid, p_label text) returns void
language plpgsql security definer set search_path = public as $$
declare slug text;
begin
  if not public.has_permission('settings.manage') then raise exception 'Not allowed'; end if;
  if p_kind not in ('item','service','task') or char_length(btrim(coalesce(p_label,''))) < 2 then raise exception 'Enter a category name'; end if;
  slug := trim(both '-' from regexp_replace(lower(btrim(p_label)), '[^a-z0-9]+', '-', 'g'));
  insert into public.categories(kind, parent_id, label, slug, sort_order, is_active) values (p_kind, p_parent, btrim(p_label), slug, 99, true);
  perform public.write_audit('category.add', 'category', slug, btrim(p_label));
end $$;

-- ---------- export audit ----------
create or replace function public.admin_log_export(p_kind text, p_target text, p_format text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.has_permission('users.read') and not public.has_permission('analytics.read') and not public.has_permission('payments.read') and not public.has_permission('tickets.manage') and not public.has_permission('listings.moderate') then raise exception 'Not allowed'; end if;
  perform public.write_audit('export', left(coalesce(p_kind,'data'), 40), left(coalesce(p_target,''), 80), left(coalesce(p_format,''), 10));
end $$;

-- ---------- lock everything down: signed-in staff only, never anonymous ----------
do $$
declare f record;
begin
  for f in select p.oid::regprocedure as sig from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname like 'admin\_%' loop
    execute format('revoke all on function %s from public, anon', f.sig);
    execute format('grant execute on function %s to authenticated', f.sig);
  end loop;
end $$;
