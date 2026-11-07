-- 운영 연결 준비용. 실제 프로젝트에서 아직 실행/검증하지 않았습니다.
create table public.profiles (
 id uuid primary key references auth.users(id),
 login_name text unique not null,
 display_name text not null,
 role text not null default 'user' check(role in ('user','admin')),
 active boolean not null default true,
 must_change_password boolean not null default true
);
create table public.projects(id uuid primary key default gen_random_uuid(), name text not null, budget numeric not null default 0);
create table public.memberships(project_id uuid references public.projects(id), user_id uuid references public.profiles(id), can_budget boolean not null default false, primary key(project_id,user_id));
create function public.ready() returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from profiles where id=auth.uid() and active and not must_change_password)$$;
create function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from profiles where id=auth.uid() and role='admin' and active and not must_change_password)$$;
create function public.is_member(p uuid) returns boolean language sql stable security definer set search_path=public as $$select public.ready() and (public.is_admin() or exists(select 1 from memberships where project_id=p and user_id=auth.uid()))$$;
alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.memberships enable row level security;
create policy profile_read on public.profiles for select to authenticated using(id=auth.uid() or public.is_admin());
-- クライアントからプロフィール/権限を書き換えるポリシーは設けない。
create policy project_read on public.projects for select to authenticated using(public.is_member(id));
create policy project_admin on public.projects for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy membership_read on public.memberships for select to authenticated using(user_id=auth.uid() or public.is_admin());
create policy membership_admin on public.memberships for all to authenticated using(public.is_admin()) with check(public.is_admin());
create table public.tasks(id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id), owner uuid not null references public.profiles(id), title text not null, start_date date not null, due_date date not null, goal text not null, result text, issue text, status text not null default '진행 전', original_due date, parent_id uuid references public.tasks(id), source_action_id uuid unique, check(due_date>=start_date));
alter table public.tasks enable row level security;
create policy tasks_read on public.tasks for select to authenticated using(public.is_member(project_id));
create policy tasks_insert on public.tasks for insert to authenticated with check(public.is_member(project_id) and (owner=auth.uid() or public.is_admin()));
create policy tasks_update on public.tasks for update to authenticated using(public.is_member(project_id) and (owner=auth.uid() or public.is_admin())) with check(public.is_member(project_id) and (owner=auth.uid() or public.is_admin()));
-- 회의, 산출물, 보고서 등 운영 테이블과 트랜잭션은 후속 연결 단계에서 완성해야 합니다.
