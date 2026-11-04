"""Inventário de rotas realmente chamadas na suíte, sem corpos/tokens."""
import json,os,re
from collections import Counter
from pathlib import Path
import httpx
calls=Counter()
original=httpx.Client.send

def instrumented(self,request,*args,**kwargs):
    response=original(self,request,*args,**kwargs)
    calls[(request.method,request.url.path,response.status_code)]+=1
    return response

def pytest_sessionstart(session):
    httpx.Client.send=instrumented

def pytest_sessionfinish(session,exitstatus):
    httpx.Client.send=original
    from app.main import app
    paths=app.openapi()['paths']; inventory=[]; matched=set()
    for path,ops in paths.items():
        pattern='^'+re.sub(r'\{[^}]+\}',r'[^/]+',path)+'$'
        for method in ops:
            if method not in ('get','post','put','patch','delete'):continue
            hits=[]
            for (verb,url,status),count in calls.items():
                if verb==method.upper() and re.match(pattern,url):
                    hits.append(dict(status=status,count=count));matched.add((verb,url,status))
            inventory.append(dict(method=method.upper(),path=path,hits=hits,called=bool(hits),success=any(h['status']<300 for h in hits)))
    out=Path(os.environ['REPORT_DIR']);out.mkdir(exist_ok=True,parents=True)
    report=dict(routes=inventory,total_routes=len(inventory),called=sum(r['called'] for r in inventory),successful=sum(r['success'] for r in inventory),notes='Chamadas da suíte via httpx; upload e URLs assinadas usam Storage simulado. Não equivale a teste Supabase real.')
    (out/'cobertura-rotas.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
    print('\nCobertura de rotas: '+str(report['called'])+'/'+str(report['total_routes'])+' chamadas; '+str(report['successful'])+' com resposta 2xx')
