export const uid=()=>crypto.randomUUID();
export function confirmMeeting(db,m){if(m.confirmed)return;for(const a of m.actions){if(!db.tasks.some(t=>t.source===a.id))db.tasks.push({id:uid(),source:a.id,title:a.title,owner:a.owner,start:m.date,due:a.due,month:a.due.slice(0,7),goal:a.goal||'후속 조치 완료',result:'',issue:'',status:'진행 전',milestone:m.milestone});}m.confirmed=true;}
export function carryTask(t,due){return {...t,id:uid(),parent:t.id,originalDue:t.originalDue||t.due,start:due,due,month:due.slice(0,7),result:'',status:'진행 전'};}
export function report(db,from,to){const ts=db.tasks.filter(t=>t.due>=from&&t.due<=to);return [`업무 보고서 | ${from} ~ ${to}`,...ts.map(t=>`\n[${t.id}] ${t.title}\n담당: ${t.owner}\n계획: ${t.goal}\n실적: ${t.result||'미입력'}\n이슈: ${t.issue||'등록 없음'}\n상태: ${t.status}`)].join('\n');}
export function milestoneProgress(db,m){const ds=db.deliverables.filter(d=>d.milestone===m);return ds.length?Math.round(ds.filter(d=>d.versions.at(-1)?.status==='제출 완료').length/ds.length*100):0;}
export function createUser(users,displayName,role='user'){
 const display=displayName.trim().normalize('NFC');
 if(!display)throw Error('사용자 이름을 입력하세요.');
 if(!['user','admin'].includes(role))throw Error('역할을 확인하세요.');
 let name=display,n=2;
 while(users.some(u=>u.name===name))name=display+String(n++).padStart(2,'0');
 return {name,displayName:display,role,password:'1111',reset:true,active:true,budget:false};
}
export function auditSnapshot(db){return JSON.parse(JSON.stringify(db,(k,v)=>['logs','password','data'].includes(k)?undefined:v));}
export function auditDiff(before,after,path=''){
 const changes=[];
 for(const key of new Set([...Object.keys(before||{}),...Object.keys(after||{})])){
 const a=before?.[key],b=after?.[key],p=path?path+'.'+key:key;
 if(JSON.stringify(a)===JSON.stringify(b))continue;
 if(a&&b&&typeof a==='object'&&typeof b==='object')changes.push(...auditDiff(a,b,p));
 else changes.push({field:p,before:a??null,after:b??null});
 }return changes;
}
