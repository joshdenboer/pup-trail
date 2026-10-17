-- Family pets: parents describe + draw their real pets; every kid in the family starts with them

create table if not exists public.family_pets (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  name text not null,
  kind text not null check (kind in ('dog','cat','other')),
  breed_text text,
  persona text,
  image_url text not null,
  created_at timestamptz default now()
);
alter table public.family_pets enable row level security;
drop policy if exists "parent reads own pets" on public.family_pets;
create policy "parent reads own pets" on public.family_pets for select using (family_id = my_family());

alter table public.dogs add column if not exists image_url text;

-- storage bucket for pet pictures (public read, parents write inside their own family folder)
insert into storage.buckets (id, name, public) values ('pets', 'pets', true) on conflict (id) do nothing;
drop policy if exists "pets public read" on storage.objects;
create policy "pets public read" on storage.objects for select using (bucket_id = 'pets');
drop policy if exists "parents upload own family pets" on storage.objects;
create policy "parents upload own family pets" on storage.objects for insert to authenticated
  with check (bucket_id = 'pets' and (storage.foldername(name))[1] = my_family()::text);
drop policy if exists "parents replace own family pets" on storage.objects;
create policy "parents replace own family pets" on storage.objects for update to authenticated
  using (bucket_id = 'pets' and (storage.foldername(name))[1] = my_family()::text);

-- give every kid in the family any family pet they do not have yet
create or replace function public.give_family_pets(p_family uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into dogs(kid_id, breed, name, persona, image_url)
  select k.id, 'pet_' || p.kind, p.name, coalesce(p.persona, 'your very own ' || p.kind), p.image_url
    from kids k join family_pets p on p.family_id = k.family_id
   where k.family_id = p_family
     and not exists (select 1 from dogs d where d.kid_id = k.id and d.image_url = p.image_url);
end $$;

create or replace function public.add_family_pet(p_name text, p_kind text, p_breed_text text, p_persona text, p_image_url text) returns public.family_pets
language plpgsql security definer set search_path = public as $$
declare fid uuid := my_family(); r family_pets;
begin
  if fid is null then raise exception 'no family'; end if;
  if p_kind not in ('dog','cat','other') then raise exception 'bad kind'; end if;
  if p_image_url not like '%/storage/v1/object/public/pets/' || fid::text || '/%' then raise exception 'bad image url'; end if;
  insert into family_pets(family_id, name, kind, breed_text, persona, image_url)
    values (fid, left(trim(p_name), 14), p_kind, left(p_breed_text, 200), left(p_persona, 120), p_image_url) returning * into r;
  perform give_family_pets(fid);
  return r;
end $$;

create or replace function public.remove_family_pet(p_pet uuid) returns void
language plpgsql security definer set search_path = public as $$
begin delete from family_pets where id = p_pet and family_id = my_family(); end $$;

-- new kids start with the family pets when there are any, otherwise Bear and Lip
create or replace function public.add_kid(p_name text, p_pin text, p_grade int) returns public.kids
language plpgsql security definer set search_path = public, extensions as $$
declare k kids; fid uuid := my_family();
begin
  if fid is null then raise exception 'no family'; end if;
  if p_pin !~ '^[0-9]{4}$' then raise exception 'PIN must be 4 digits'; end if;
  insert into kids(family_id, name, pin_hash, grade) values (fid, trim(p_name), crypt(p_pin, gen_salt('bf')), p_grade) returning * into k;
  if exists (select 1 from family_pets where family_id = fid) then
    perform give_family_pets(fid);
  else
    insert into dogs(kid_id, breed, name, persona) values
      (k.id, 'bear', 'Bear', 'has a white spot on his chest and loves everybody'),
      (k.id, 'lip', 'Lip', 'black with a white chest spot, nose always on a scent');
  end if;
  return k;
end $$;

-- kid_state now includes image_url on each dog
create or replace function public.kid_state(p_token uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare k kids := kid_from_token(p_token); f families;
begin
  select * into f from families where id = k.family_id;
  update dogs set happiness = greatest(0, happiness - 15), cared_on = current_date
    where kid_id = k.id and cared_on < current_date
      and exists (select 1 from play_days where kid_id = k.id and day = current_date and seconds > 0);
  return jsonb_build_object(
    'id', k.id, 'name', k.name, 'grade', k.grade, 'chat_mode', k.chat_mode, 'chat_locked', k.chat_locked,
    'avatar', k.avatar, 'shelter_style', k.shelter_style, 'coins', k.coins,
    'career_level', k.career_level, 'career_state', k.career_state,
    'season_prize', f.season_prize, 'family_name', f.name,
    'season_length', k.season_length, 'days_played', days_played(k.id), 'seconds_left', seconds_left(k.id),
    'dogs', (select coalesce(jsonb_agg(jsonb_build_object('id',d.id,'breed',d.breed,'name',d.name,'persona',d.persona,'happiness',d.happiness,'image_url',d.image_url) order by d.found_at), '[]'::jsonb) from dogs d where d.kid_id = k.id),
    'inventory', (select coalesce(jsonb_object_agg(item_id, qty), '{}'::jsonb) from inventory where kid_id = k.id)
  );
end $$;

grant execute on function public.add_family_pet(text,text,text,text,text), public.remove_family_pet(uuid) to authenticated;
