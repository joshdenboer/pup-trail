-- Login screen: show the kids in a family (name + avatar only) once a device knows the family code
create or replace function public.family_profiles(p_code text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare f families;
begin
  select * into f from families where invite_code = upper(trim(p_code));
  if f.id is null then raise exception 'No family with that code'; end if;
  return jsonb_build_object('family_name', f.name,
    'kids', (select coalesce(jsonb_agg(jsonb_build_object('name', k.name, 'avatar', k.avatar) order by k.created_at), '[]'::jsonb) from kids k where k.family_id = f.id));
end $$;
grant execute on function public.family_profiles(text) to anon, authenticated;
