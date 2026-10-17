-- Rebuild the three PIN functions so they can find pgcrypto in the "extensions" schema
create or replace function public.add_kid(p_name text, p_pin text, p_grade int) returns public.kids
language plpgsql security definer set search_path = public, extensions as $$
declare k kids; fid uuid := my_family();
begin
  if fid is null then raise exception 'no family'; end if;
  if p_pin !~ '^[0-9]{4}$' then raise exception 'PIN must be 4 digits'; end if;
  insert into kids(family_id, name, pin_hash, grade) values (fid, trim(p_name), crypt(p_pin, gen_salt('bf')), p_grade) returning * into k;
  insert into dogs(kid_id, breed, name, persona) values
    (k.id, 'bear', 'Bear', 'has a white spot on his chest and loves everybody'),
    (k.id, 'lip', 'Lip', 'black with a white chest spot, nose always on a scent');
  return k;
end $$;

create or replace function public.set_kid_pin(p_kid uuid, p_pin text) returns void
language plpgsql security definer set search_path = public, extensions as $$
begin
  if p_pin !~ '^[0-9]{4}$' then raise exception 'PIN must be 4 digits'; end if;
  update kids set pin_hash = crypt(p_pin, gen_salt('bf')) where id = p_kid and family_id = my_family();
end $$;

create or replace function public.kid_login(p_code text, p_name text, p_pin text) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare k kids; t uuid;
begin
  select k2.* into k from kids k2 join families f on f.id = k2.family_id
   where f.invite_code = upper(trim(p_code)) and lower(k2.name) = lower(trim(p_name));
  if k.id is null or k.pin_hash <> crypt(p_pin, k.pin_hash) then raise exception 'Wrong code, name or PIN'; end if;
  update kid_sessions set active = false where kid_id = k.id;
  insert into kid_sessions(kid_id) values (k.id) returning token into t;
  return jsonb_build_object('token', t, 'state', kid_state(t));
end $$;
