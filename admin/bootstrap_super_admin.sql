-- Run ONCE in the Supabase SQL editor to create the first super admin.
-- 1) Supabase Dashboard -> Authentication -> Users -> "Add user" (email + a strong temporary password, tick "Auto confirm").
-- 2) Put that email below and run. The dashboard then forces: new password + authenticator-app (TOTP) 2FA.
-- No password is stored anywhere in this repo.
do $$
declare uid uuid; em text := 'REPLACE_WITH_ADMIN_EMAIL';
begin
  select id into uid from auth.users where lower(email) = lower(em);
  if uid is null then raise exception 'Create the user in Authentication first'; end if;
  insert into public.staff_roles(user_id, role) values (uid, 'super_admin') on conflict do nothing;
  update public.profiles set must_change_password = true where id = uid;
end $$;
