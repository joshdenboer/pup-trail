-- Parents can remove a dog from a kid's shelter, and built-in starters make way for drawn family pets with the same name
create or replace function public.remove_kid_dog(p_dog uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from dogs d using kids k where d.id = p_dog and k.id = d.kid_id and k.family_id = my_family();
end $$;
grant execute on function public.remove_kid_dog(uuid) to authenticated;

create or replace function public.give_family_pets(p_family uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  -- built-in Bear/Lip step aside when the family draws a pet with the same name
  delete from dogs d using kids k, family_pets p
   where d.kid_id = k.id and k.family_id = p_family and p.family_id = p_family
     and d.breed in ('bear','lip') and lower(d.name) = lower(p.name);
  insert into dogs(kid_id, breed, name, persona, image_url)
  select k.id, 'pet_' || p.kind, p.name, coalesce(p.persona, 'your very own ' || p.kind), p.image_url
    from kids k join family_pets p on p.family_id = k.family_id
   where k.family_id = p_family
     and not exists (select 1 from dogs d where d.kid_id = k.id and d.image_url = p.image_url);
end $$;

-- apply once now for existing kids
select public.give_family_pets(f.id) from public.families f;
