-- Real-world size for dogs: family pets carry a size the parent picks (0.6 small … 1.15 giant)
alter table public.family_pets add column if not exists size numeric not null default 1;
alter table public.dogs add column if not exists size numeric;

create or replace function public.add_family_pet(p_name text, p_kind text, p_breed_text text, p_persona text, p_image_url text, p_size numeric default 1) returns public.family_pets
language plpgsql security definer set search_path = public as $$
declare fid uuid := my_family(); r family_pets;
begin
  if fid is null then raise exception 'no family'; end if;
  if p_kind not in ('dog','cat','other') then raise exception 'bad kind'; end if;
  if p_image_url not like '%/storage/v1/object/public/pets/' || fid::text || '/%' then raise exception 'bad image url'; end if;
  insert into family_pets(family_id, name, kind, breed_text, persona, image_url, size)
    values (fid, left(trim(p_name), 14), p_kind, left(p_breed_text, 200), left(p_persona, 120), p_image_url, greatest(0.4, least(1.4, coalesce(p_size, 1)))) returning * into r;
  perform give_family_pets(fid);
  return r;
end $$;
drop function if exists public.add_family_pet(text,text,text,text,text);

create or replace function public.give_family_pets(p_family uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from dogs d using kids k, family_pets p
   where d.kid_id = k.id and k.family_id = p_family and p.family_id = p_family
     and d.breed in ('bear','lip') and lower(d.name) = lower(p.name);
  insert into dogs(kid_id, breed, name, persona, image_url, size)
  select k.id, 'pet_' || p.kind, p.name, coalesce(p.persona, 'your very own ' || p.kind), p.image_url, p.size
    from kids k join family_pets p on p.family_id = k.family_id
   where k.family_id = p_family
     and not exists (select 1 from dogs d where d.kid_id = k.id and d.image_url = p.image_url);
end $$;

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
    'dogs', (select coalesce(jsonb_agg(jsonb_build_object('id',d.id,'breed',d.breed,'name',d.name,'persona',d.persona,'happiness',d.happiness,'image_url',d.image_url,'size',d.size) order by d.found_at), '[]'::jsonb) from dogs d where d.kid_id = k.id),
    'inventory', (select coalesce(jsonb_object_agg(item_id, qty), '{}'::jsonb) from inventory where kid_id = k.id)
  );
end $$;
grant execute on function public.add_family_pet(text,text,text,text,text,numeric) to authenticated;
