# Supabase 변경 이력 연결

## 적용 순서
1. 수정된 전체 파일을 GitHub에 올리고 Netlify 재배포를 확인합니다.
2. Netlify 환경변수에 SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY를 등록합니다. Secret/service_role 키는 사용하지 않습니다.
3. Supabase SQL Editor에서 기존 001_schema.sql이 적용된 상태인지 확인하고 002_audit.sql만 한 번 실행합니다. 기존 001은 다시 실행하지 않습니다.
4. Supabase Authentication > Users에서 실제 사용할 사용자 이메일/비밀번호 계정을 생성합니다. 브라우저 시험 계정과 별도입니다.
5. 아래 SQL의 UUID를 해당 Auth 사용자의 실제 UUID로 바꾸고, 이름을 앱의 로그인 아이디와 일치시켜 실행합니다. role은 일반 사용자는 user, 관리자는 admin입니다. must_change_password=false는 실제 사용자 비밀번호 설정/변경을 완료한 계정에만 적용합니다.

```sql
insert into public.profiles(id,login_name,display_name,role,active,must_change_password)
values ('실제-Auth-사용자-UUID','관리자','관리자','admin',true,false);
```

6. 앱에 로그인하고 상단 '이력 서버 연결'에서 해당 Supabase 이메일/비밀번호로 인증합니다. 토큰은 메모리에만 보관하며 새로고침 시 다시 연결합니다.
7. 업무를 수정한 뒤 관리자 '변경 이력 → 서버 이력 조회'에서 확인합니다. SQL Editor에서도 `select * from public.audit_events order by at desc;`로 확인할 수 있습니다.

## 동작과 범위
- 연결 후 신규 이력 자동 전송. 연결 전 이번 버전에서 발생한 pending 이력도 동일 사용자 인증 후 전송.
- 이전 버전 이력은 자동 업로드하지 않음. 과거 작성자를 현재 로그인 사용자로 잘못 기록하지 않기 위함.
- 작업자는 서버의 auth.uid()와 프로필, 시각은 서버의 now() 사용.
- 관리자만 전체 이력 조회. 일반 계정은 RPC를 통해 자신의 이력 추가만 가능.
- 일반 API의 수정/삭제 차단. 서버 소유자의 SQL 관리 권한까지 차단하는 것은 아님.
- 재전송은 이벤트 UUID로 중복 방지. 인증 만료 시 이력 서버에 다시 로그인하고 재시도.
- 업무 본문은 여전히 localStorage. 이력 내용은 클라이언트가 보고하는 데이터이며 실제 DB 업무 변경을 입증하는 트리거 감사로그가 아님.
- 사용자 추가 기능은 아직 로컬 시험 계정만 생성. Supabase Auth 계정은 위 4~5단계로 별도 준비.
- 클라우드 이력과 로컬 업무 저장은 하나의 트랜잭션이 아님. 미전송 이력이 있으면 브라우저 데이터를 지우지 말 것.
- 실제 Supabase 프로젝트 적용, RLS 통합 검증, Netlify 함수 실행은 연결 정보가 없어 미검증. 자바스크립트 문법 검사 및 기존 도메인 테스트 9개 통과.
