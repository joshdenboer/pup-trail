-- 1. Reset today's play time for every kid right now (testing)
delete from public.play_days where day = current_date;

-- 2. Parent button: give one kid their 20 minutes back for today
create or replace function public.reset_kid_today(p_kid uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  delete from play_days p using kids k where p.kid_id = k.id and k.id = p_kid and k.family_id = my_family() and p.day = current_date;
end $$;
grant execute on function public.reset_kid_today(uuid) to authenticated;
