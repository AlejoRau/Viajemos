-- avg_rating en profiles nunca se actualizaba. Este trigger lo recalcula
-- automáticamente después de cada insert/update/delete en reviews.
-- SECURITY DEFINER: necesario para que el trigger pueda escribir en profiles
-- desde el contexto de un usuario que solo tiene permiso de insertar reviews.
-- Solo actualiza el campo avg_rating del usuario evaluado, nunca expone otras filas.
create or replace function public.update_profile_avg_rating()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user_id uuid;
begin
  -- en DELETE usamos old, en INSERT/UPDATE usamos new
  target_user_id := coalesce(new.reviewed_id, old.reviewed_id);

  update public.profiles
  set avg_rating = (
    select coalesce(round(avg(rating)::numeric, 2), 0)
    from public.reviews
    where reviewed_id = target_user_id
  )
  where id = target_user_id;

  return null;
end;
$$;

create trigger update_avg_rating_on_review
  after insert or update or delete on public.reviews
  for each row execute function public.update_profile_avg_rating();
