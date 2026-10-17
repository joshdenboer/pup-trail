-- Change a family pet's size any time; applies to every kid who has that pet
create or replace function public.set_family_pet_size(p_pet uuid, p_size numeric) returns void
language plpgsql security definer set search_path = public as $$
declare p family_pets;
begin
  select * into p from family_pets where id = p_pet and family_id = my_family();
  if p.id is null then raise exception 'not your pet'; end if;
  update family_pets set size = greatest(0.4, least(1.4, p_size)) where id = p.id;
  update dogs d set size = greatest(0.4, least(1.4, p_size)) from kids k
   where d.kid_id = k.id and k.family_id = p.family_id and d.image_url = p.image_url;
end $$;
grant execute on function public.set_family_pet_size(uuid, numeric) to authenticated;
