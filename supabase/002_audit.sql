-- 001_schema.sql 적용 후 한 번 실행. 기존 테이블/자료는 삭제하지 않음.
create table public.audit_events (
 id uuid primary key,
 actor_id uuid not null references auth.users(id),
 actor text not null,
 at timestamptz not null default now(),
 action text not null,
 changes jsonb not null default '[]'::jsonb,
 source text not null default 'browser_reported'
);
create index audit_events_at on public.audit_events(at desc);
alter table public.audit_events enable row level security;
revoke all on public.audit_events from anon, authenticated;
grant select on public.audit_events to authenticated;
create policy audit_admin_read on public.audit_events for select to authenticated using(public.is_admin());
create function public.append_audit(p_event uuid,p_action text,p_changes jsonb) returns uuid
language plpgsql security definer set search_path=public as $$
declare actor_name text;
begin
 if not public.ready() then raise exception 'Active authenticated profile required'; end if;
 if p_action is null or length(p_action)>2000 or jsonb_typeof(p_changes) is distinct from 'array' or octet_length(p_changes::text)>500000 then raise exception 'Invalid audit payload'; end if;
 select login_name into actor_name from public.profiles where id=auth.uid();
 if exists(select 1 from audit_events where id=p_event and actor_id<>auth.uid()) then raise exception 'Event conflict'; end if;
 insert into audit_events(id,actor_id,actor,action,changes) values(p_event,auth.uid(),actor_name,p_action,p_changes) on conflict(id) do nothing;
 return p_event;
end;$$;
revoke all on function public.append_audit(uuid,text,jsonb) from public,anon;
grant execute on function public.append_audit(uuid,text,jsonb) to authenticated;
-- 일반 사용자/관리자 브라우저에 UPDATE/DELETE 권한을 부여하지 않음.
-- 업무 자체가 아직 브라우저에 있으므로 source=browser_reported. DB 변경을 증명하는 감사로그와 구분.
