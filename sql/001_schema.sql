-- Pup Trail schema v1 (run in Supabase SQL editor, new project)
create extension if not exists pgcrypto;

-- ===== families & parents (parents use Supabase email auth) =====
create table families (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text unique not null default upper(substr(encode(gen_random_bytes(6),'hex'),1,8)),
  season_prize text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz default now()
);
create table parents (
  user_id uuid primary key references auth.users(id) on delete cascade,
  family_id uuid not null references families(id) on delete cascade,
  display_name text,
  created_at timestamptz default now()
);

-- ===== kids (no email; login = family code + name + PIN) =====
create table kids (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  name text not null,
  pin_hash text not null,
  grade int not null default 3 check (grade between 2 and 5),
  grade_locked boolean default true,
  chat_mode text not null default 'text' check (chat_mode in ('play','text','voice')),
  chat_locked boolean default false,
  avatar jsonb not null default '{}'::jsonb,
  shelter_style text not null default 'forest',
  coins int not null default 0,
  career_level int not null default 1,
  career_state jsonb,
  season_start date not null default current_date,
  season_length int not null default 30,
  created_at timestamptz default now(),
  unique (family_id, name)
);
create table kid_sessions (
  token uuid primary key default gen_random_uuid(),
  kid_id uuid not null references kids(id) on delete cascade,
  created_at timestamptz default now(),
  last_seen timestamptz default now(),
  active boolean default true
);
create index on kid_sessions(kid_id) where active;

create table dogs (
  id uuid primary key default gen_random_uuid(),
  kid_id uuid not null references kids(id) on delete cascade,
  breed text not null,
  name text not null,
  persona text,
  happiness int not null default 100 check (happiness between 0 and 100),
  cared_on date default current_date,
  found_at timestamptz default now()
);
create index on dogs(kid_id);

create table inventory (
  kid_id uuid not null references kids(id) on delete cascade,
  item_id text not null,
  qty int not null default 1,
  primary key (kid_id, item_id)
);

create table play_days (
  kid_id uuid not null references kids(id) on delete cascade,
  day date not null,
  seconds int not null default 0,
  primary key (kid_id, day)
);

create table trail_runs (
  id uuid primary key default gen_random_uuid(),
  kid_id uuid not null references kids(id) on delete cascade,
  world text not null,
  mode text not null check (mode in ('quick','career')),
  level int,
  stop_index int not null default 0,
  stops int not null default 10,
  started_at timestamptz default now(),
  finished_at timestamptz,
  coins int default 0,
  correct int default 0,
  total int default 0
);
create index on trail_runs(kid_id, started_at desc);

-- ===== friends: family <-> family, parent-approved on both sides =====
create table friend_links (
  id uuid primary key default gen_random_uuid(),
  family_a uuid not null references families(id) on delete cascade,
  family_b uuid not null references families(id) on delete cascade,
  requested_by uuid not null references auth.users(id),
  status text not null default 'pending' check (status in ('pending','approved','declined')),
  created_at timestamptz default now(),
  unique (family_a, family_b),
  check (family_a <> family_b)
);

create table messages (
  id bigserial primary key,
  from_kid uuid not null references kids(id) on delete cascade,
  to_kid uuid not null references kids(id) on delete cascade,
  body text not null check (length(body) <= 300),
  created_at timestamptz default now()
);
create index on messages(to_kid, created_at desc);
create index on messages(from_kid, created_at desc);

-- ===== RLS: parents see their own family; kids never touch tables directly =====
alter table families enable row level security;
alter table parents enable row level security;
alter table kids enable row level security;
alter table kid_sessions enable row level security;
alter table dogs enable row level security;
alter table inventory enable row level security;
alter table play_days enable row level security;
alter table trail_runs enable row level security;
alter table friend_links enable row level security;
alter table messages enable row level security;

create or replace function my_family() returns uuid language sql stable security definer set search_path=public as
$$ select family_id from parents where user_id = auth.uid() $$;

create policy "parent reads own family" on families for select using (id = my_family());
create policy "parent updates own family" on families for update using (id = my_family());
create policy "parent reads self" on parents for select using (user_id = auth.uid());
create policy "parent reads kids" on kids for select using (family_id = my_family());
create policy "parent updates kids" on kids for update using (family_id = my_family());
create policy "parent reads dogs" on dogs for select using (kid_id in (select id from kids where family_id = my_family()));
create policy "parent reads play" on play_days for select using (kid_id in (select id from kids where family_id = my_family()));
create policy "parent reads runs" on trail_runs for select using (kid_id in (select id from kids where family_id = my_family()));
create policy "parent reads links" on friend_links for select using (family_a = my_family() or family_b = my_family());
create policy "parent reads kid messages" on messages for select using (
  from_kid in (select id from kids where family_id = my_family()) or to_kid in (select id from kids where family_id = my_family()));

-- ===== parent RPCs =====
create or replace function create_family(p_name text, p_parent_name text) returns families
language plpgsql security definer set search_path=public as $$
declare f families;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  if exists (select 1 from parents where user_id = auth.uid()) then raise exception 'already in a family'; end if;
  insert into families(name, created_by) values (p_name, auth.uid()) returning * into f;
  insert into parents(user_id, family_id, display_name) values (auth.uid(), f.id, p_parent_name);
  return f;
end $$;

create or replace function add_kid(p_name text, p_pin text, p_grade int) returns kids
language plpgsql security definer set search_path=public as $$
declare k kids; fid uuid := my_family();
begin
  if fid is null then raise exception 'no family'; end if;
  if p_pin !~ '^[0-9]{4}$' then raise exception 'PIN must be 4 digits'; end if;
  insert into kids(family_id, name, pin_hash, grade) values (fid, trim(p_name), crypt(p_pin, gen_salt('bf')), p_grade) returning * into k;
  -- starter dogs: Bear and Lip
  insert into dogs(kid_id, breed, name, persona) values
    (k.id, 'bear', 'Bear', 'has a white spot on his chest and loves everybody'),
    (k.id, 'lip', 'Lip', 'black with a white chest spot, nose always on a scent');
  return k;
end $$;

create or replace function set_kid_pin(p_kid uuid, p_pin text) returns void
language plpgsql security definer set search_path=public as $$
begin
  if p_pin !~ '^[0-9]{4}$' then raise exception 'PIN must be 4 digits'; end if;
  update kids set pin_hash = crypt(p_pin, gen_salt('bf')) where id = p_kid and family_id = my_family();
end $$;

create or replace function request_friend(p_code text) returns friend_links
language plpgsql security definer set search_path=public as $$
declare other uuid; mine uuid := my_family(); l friend_links;
begin
  select id into other from families where invite_code = upper(trim(p_code));
  if other is null then raise exception 'No family with that code'; end if;
  if other = mine then raise exception 'That is your own code'; end if;
  insert into friend_links(family_a, family_b, requested_by)
    values (least(mine, other), greatest(mine, other), auth.uid())
    on conflict (family_a, family_b) do update set status = friend_links.status
    returning * into l;
  return l;
end $$;

create or replace function respond_friend(p_link uuid, p_approve boolean) returns void
language plpgsql security definer set search_path=public as $$
declare mine uuid := my_family();
begin
  update friend_links set status = case when p_approve then 'approved' else 'declined' end
   where id = p_link and status = 'pending' and requested_by <> auth.uid() and (family_a = mine or family_b = mine);
end $$;

-- ===== kid session helpers =====
create or replace function kid_from_token(p_token uuid) returns kids
language plpgsql security definer set search_path=public as $$
declare k kids;
begin
  select k2.* into k from kid_sessions s join kids k2 on k2.id = s.kid_id where s.token = p_token and s.active;
  if k.id is null then raise exception 'SESSION_EXPIRED'; end if;
  update kid_sessions set last_seen = now() where token = p_token;
  return k;
end $$;

create or replace function kid_login(p_code text, p_name text, p_pin text) returns jsonb
language plpgsql security definer set search_path=public as $$
declare k kids; t uuid;
begin
  select k2.* into k from kids k2 join families f on f.id = k2.family_id
   where f.invite_code = upper(trim(p_code)) and lower(k2.name) = lower(trim(p_name));
  if k.id is null or k.pin_hash <> crypt(p_pin, k.pin_hash) then raise exception 'Wrong code, name or PIN'; end if;
  update kid_sessions set active = false where kid_id = k.id;   -- one active session only
  insert into kid_sessions(kid_id) values (k.id) returning token into t;
  return jsonb_build_object('token', t, 'state', kid_state(t));
end $$;

create or replace function seconds_left(p_kid uuid) returns int language sql stable security definer set search_path=public as
$$ select 1200 - coalesce((select seconds from play_days where kid_id = p_kid and day = current_date), 0) $$;

create or replace function days_played(p_kid uuid) returns int language sql stable security definer set search_path=public as
$$ select count(*)::int from play_days p join kids k on k.id = p.kid_id where p.kid_id = p_kid and p.seconds >= 60 and p.day >= k.season_start $$;

create or replace function kid_state(p_token uuid) returns jsonb
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token); f families;
begin
  select * into f from families where id = k.family_id;
  -- simple care: happiness drops 15 per play-day missed (only counting days the kid actually played)
  update dogs set happiness = greatest(0, happiness - 15), cared_on = current_date
    where kid_id = k.id and cared_on < current_date
      and exists (select 1 from play_days where kid_id = k.id and day = current_date and seconds > 0);
  return jsonb_build_object(
    'id', k.id, 'name', k.name, 'grade', k.grade, 'chat_mode', k.chat_mode, 'chat_locked', k.chat_locked,
    'avatar', k.avatar, 'shelter_style', k.shelter_style, 'coins', k.coins,
    'career_level', k.career_level, 'career_state', k.career_state,
    'season_prize', f.season_prize, 'family_name', f.name,
    'season_length', k.season_length, 'days_played', days_played(k.id), 'seconds_left', seconds_left(k.id),
    'dogs', (select coalesce(jsonb_agg(jsonb_build_object('id',d.id,'breed',d.breed,'name',d.name,'persona',d.persona,'happiness',d.happiness) order by d.found_at), '[]'::jsonb) from dogs d where d.kid_id = k.id),
    'inventory', (select coalesce(jsonb_object_agg(item_id, qty), '{}'::jsonb) from inventory where kid_id = k.id)
  );
end $$;

create or replace function tick(p_token uuid, p_seconds int) returns int
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token);
begin
  insert into play_days(kid_id, day, seconds) values (k.id, current_date, least(p_seconds, 60))
    on conflict (kid_id, day) do update set seconds = least(1200, play_days.seconds + least(p_seconds, 60));
  return seconds_left(k.id);
end $$;

create or replace function start_trail(p_token uuid, p_world text, p_mode text, p_level int, p_stops int) returns uuid
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token); r uuid;
begin
  if seconds_left(k.id) <= 0 then raise exception 'TIME_UP'; end if;
  update trail_runs set finished_at = now() where kid_id = k.id and finished_at is null;
  insert into trail_runs(kid_id, world, mode, level, stops) values (k.id, p_world, p_mode, p_level, p_stops) returning id into r;
  return r;
end $$;

create or replace function trail_progress(p_token uuid, p_run uuid, p_stop int) returns void
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token);
begin
  update trail_runs set stop_index = p_stop where id = p_run and kid_id = k.id;
end $$;

create or replace function finish_trail(p_token uuid, p_run uuid, p_coins int, p_correct int, p_total int, p_dogs jsonb, p_career_level int, p_career_state jsonb) returns jsonb
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token); r trail_runs; d jsonb; capped int;
begin
  select * into r from trail_runs where id = p_run and kid_id = k.id and finished_at is null;
  if r.id is null then raise exception 'no such run'; end if;
  capped := least(p_coins, 30 * (r.stops + 4) + 100);   -- sanity cap vs. tab tricks
  update trail_runs set finished_at = now(), coins = capped, correct = p_correct, total = p_total where id = r.id;
  update kids set coins = coins + capped,
                  career_level = greatest(career_level, coalesce(p_career_level, career_level)),
                  career_state = coalesce(p_career_state, career_state)
   where id = k.id;
  for d in select * from jsonb_array_elements(coalesce(p_dogs, '[]'::jsonb)) loop
    insert into dogs(kid_id, breed, name, persona) values (k.id, d->>'breed', d->>'name', d->>'persona');
  end loop;
  return kid_state(p_token);
end $$;

create or replace function rename_dog(p_token uuid, p_dog uuid, p_name text) returns void
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token);
begin
  update dogs set name = left(trim(p_name), 14) where id = p_dog and kid_id = k.id and length(trim(p_name)) > 0;
end $$;

create or replace function care_dog(p_token uuid, p_dog uuid, p_item text) returns jsonb
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token); q int;
begin
  select qty into q from inventory where kid_id = k.id and item_id = p_item;
  if coalesce(q,0) <= 0 then raise exception 'You need to buy that first'; end if;
  update inventory set qty = qty - 1 where kid_id = k.id and item_id = p_item;
  update dogs set happiness = least(100, happiness + 40), cared_on = current_date where id = p_dog and kid_id = k.id;
  return kid_state(p_token);
end $$;

create or replace function buy_item(p_token uuid, p_item text, p_price int) returns jsonb
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token);
begin
  if p_price < 0 or p_price > 2000 then raise exception 'bad price'; end if;
  if k.coins < p_price then raise exception 'Not enough Pup Coins'; end if;
  update kids set coins = coins - p_price where id = k.id;
  insert into inventory(kid_id, item_id, qty) values (k.id, p_item, 1) on conflict (kid_id, item_id) do update set qty = inventory.qty + 1;
  return kid_state(p_token);
end $$;

create or replace function save_avatar(p_token uuid, p_avatar jsonb) returns void
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token);
begin update kids set avatar = p_avatar where id = k.id; end $$;

create or replace function set_shelter(p_token uuid, p_style text) returns void
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token);
begin
  if p_style not in ('beach','farm','forest','metro','rural') then raise exception 'bad style'; end if;
  update kids set shelter_style = p_style where id = k.id;
end $$;

create or replace function set_chat_mode(p_token uuid, p_mode text) returns void
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token);
begin
  if k.chat_locked then raise exception 'A parent locked chat settings'; end if;
  if p_mode not in ('play','text','voice') then raise exception 'bad mode'; end if;
  update kids set chat_mode = p_mode where id = k.id;
end $$;

-- friends of a kid = all kids in approved linked families
create or replace function friend_kids(p_kid uuid) returns setof kids language sql stable security definer set search_path=public as $$
  select k.* from kids k
   where k.family_id in (
     select case when l.family_a = me.family_id then l.family_b else l.family_a end
       from friend_links l, kids me where me.id = p_kid and l.status = 'approved' and (l.family_a = me.family_id or l.family_b = me.family_id))
      or (k.family_id = (select family_id from kids where id = p_kid) and k.id <> p_kid)
$$;

create or replace function friends_board(p_token uuid) returns jsonb
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token);
begin
  return (select coalesce(jsonb_agg(jsonb_build_object(
      'id', f.id, 'name', f.name, 'avatar', f.avatar, 'coins', f.coins, 'career_level', f.career_level,
      'days_played', days_played(f.id), 'dogs', (select count(*) from dogs where kid_id = f.id),
      'chat_mode', f.chat_mode,
      'today_run', (select jsonb_build_object('world', r.world, 'stop', r.stop_index, 'stops', r.stops, 'done', r.finished_at is not null)
                      from trail_runs r where r.kid_id = f.id and r.started_at::date = current_date order by r.started_at desc limit 1)
    ) order by f.coins desc), '[]'::jsonb) from friend_kids(k.id) f);
end $$;

create or replace function send_message(p_token uuid, p_to uuid, p_body text) returns void
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token); other kids;
begin
  if k.chat_mode = 'play' then raise exception 'Chat is set to play only'; end if;
  select * into other from friend_kids(k.id) where id = p_to;
  if other.id is null then raise exception 'not a friend'; end if;
  if other.chat_mode = 'play' then raise exception 'Your friend has chat turned off right now'; end if;
  insert into messages(from_kid, to_kid, body) values (k.id, p_to, left(trim(p_body), 300));
end $$;

create or replace function get_messages(p_token uuid, p_with uuid, p_after bigint) returns jsonb
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token);
begin
  return (select coalesce(jsonb_agg(jsonb_build_object('id', m.id, 'from', m.from_kid, 'body', m.body, 'at', m.created_at) order by m.id), '[]'::jsonb)
    from messages m where ((m.from_kid = k.id and m.to_kid = p_with) or (m.from_kid = p_with and m.to_kid = k.id)) and m.id > coalesce(p_after, 0));
end $$;

create or replace function save_career_state(p_token uuid, p_level int, p_state jsonb) returns void
language plpgsql security definer set search_path=public as $$
declare k kids := kid_from_token(p_token);
begin update kids set career_state = p_state where id = k.id and career_level = p_level; end $$;

-- anon may call only the kid RPCs
revoke all on all functions in schema public from public, anon;
grant execute on function kid_login(text,text,text), kid_state(uuid), tick(uuid,int), start_trail(uuid,text,text,int,int), trail_progress(uuid,uuid,int),
  finish_trail(uuid,uuid,int,int,int,jsonb,int,jsonb), rename_dog(uuid,uuid,text), care_dog(uuid,uuid,text), buy_item(uuid,text,int),
  save_avatar(uuid,jsonb), save_career_state(uuid,int,jsonb), set_shelter(uuid,text), set_chat_mode(uuid,text), friends_board(uuid), send_message(uuid,uuid,text), get_messages(uuid,uuid,bigint)
  to anon, authenticated;
grant execute on function create_family(text,text), add_kid(text,text,int), set_kid_pin(uuid,text), request_friend(text), respond_friend(uuid,boolean), my_family() to authenticated;
