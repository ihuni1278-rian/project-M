let config=null,token=null;export let identity=null;
async function request(path,body,method='POST'){
 const r=await fetch(config.url+path,{method,headers:{apikey:config.key,Authorization:'Bearer '+(token||config.key),'Content-Type':'application/json'},...(body?{body:JSON.stringify(body)}:{})});
 const data=await r.json();if(!r.ok)throw Error(data.message||data.msg||'Supabase 요청 실패');return data;
}
export async function connect(email,password,expectedName){
 const r=await fetch('/.netlify/functions/config');if(!r.ok)throw Error('Netlify 연결 설정을 확인하세요.');config=await r.json();
 if(!config.url||!config.key)throw Error('SUPABASE_URL과 SUPABASE_PUBLISHABLE_KEY를 등록하세요.');
 const auth=await request('/auth/v1/token?grant_type=password',{email,password});token=auth.access_token;
 try{const rows=await request('/rest/v1/profiles?id=eq.'+auth.user.id+'&select=id,login_name,role,active,must_change_password',null,'GET');const p=rows[0];if(!p||!p.active||p.must_change_password||p.login_name!==expectedName)throw Error('활성 프로필의 로그인 이름과 현재 계정 이름이 일치해야 하며 최초 비밀번호 변경이 완료되어야 합니다.');identity=p;return p;}catch(e){disconnect();throw e;}
}
export function disconnect(){token=null;identity=null;}
export async function push(entry){if(!identity)throw Error('Supabase 이력 계정에 로그인하세요.');return request('/rest/v1/rpc/append_audit',{p_event:entry.id,p_action:entry.action,p_changes:entry.changes});}
export async function list(){if(!identity)throw Error('Supabase 이력 계정에 로그인하세요.');let all=[],offset=0;for(;;){const rows=await request('/rest/v1/audit_events?select=*&order=at.desc,id.desc&limit=500&offset='+offset,null,'GET');all.push(...rows);if(rows.length<500)break;offset+=rows.length;}return all;}
