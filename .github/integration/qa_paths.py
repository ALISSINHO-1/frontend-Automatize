"""QA de jornadas em Chromium; API real isolada; demonstração identificada."""
import json, os, re, traceback, time
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from playwright.sync_api import sync_playwright
OUT=Path(os.environ['REPORT_DIR']); OUT.mkdir(parents=True,exist_ok=True)
VAR=os.environ['VARIANT']; BASE='http://127.0.0.1:8000'; WEB='http://127.0.0.1:8080'
results=[]; requests=[]; errors=[]

def check(name,fn):
    try:
        details=json.loads(json.dumps(fn(),default=lambda _:None))
        results.append(dict(name=name,status='PASS',details=details))
    except Exception as exc:
        results.append(dict(name=name,status='FAIL',error=str(exc),trace=traceback.format_exc()[-1800:]))
        try: page.screenshot(path=str(OUT/f'falha-{len(results):03}.png'))
        except Exception: pass
    print(json.dumps(results[-1],ensure_ascii=False),flush=True)

def req(method,path,token=None,data=None,expected=200):
    headers={'Content-Type':'application/json'}
    if token: headers['Authorization']='Bearer '+token
    request=Request(BASE+path,method=method,headers=headers,data=None if data is None else json.dumps(data).encode())
    try:
        with urlopen(request,timeout=20) as r: code=r.status; raw=r.read()
    except HTTPError as r: code=r.code; raw=r.read()
    assert code==expected,f'{method} {path}: HTTP {code}, esperado {expected}; {raw[:250]!r}'
    return json.loads(raw) if raw else None

def labels():
    return page.locator('[aria-label]').evaluate_all("els => els.map(e=>e.getAttribute('aria-label')).join('\\n')")+'\n'+page.locator('body').inner_text()

def has(text):
    assert text.lower() in labels().lower(),f'Texto não encontrado: {text}; semântica: {labels()[:1600]}'

def click(text,exact=True):
    for loc in (page.get_by_role('button',name=text,exact=exact),page.get_by_label(text,exact=exact),page.get_by_text(text,exact=exact)):
        if loc.count():
            loc.first.click(timeout=6000); page.wait_for_timeout(500); return
    raise AssertionError('Controle não encontrado: '+str(text))

def semantics():
    el=page.locator('flt-semantics-placeholder')
    if el.count(): el.first.evaluate('el=>el.click()')
    page.wait_for_timeout(1000)

def open_route(route='/',width=1440):
    page.set_viewport_size(dict(width=width,height=1000))
    page.goto(WEB+'/?qa='+str(time.time_ns())+'#'+route,wait_until='networkidle',timeout=90000)
    page.wait_for_selector('flutter-view',timeout=60000); semantics()

def type_field(index,value):
    boxes=[x.bounding_box() for x in page.get_by_role('textbox').all()]
    boxes=[b for b in boxes if b and b['width']>50 and b['height']>10]
    # Flutter can expose the native editor and semantics mirror at identical geometry.
    unique={ (round(b['x']),round(b['y'])): b for b in boxes }
    boxes=sorted(unique.values(),key=lambda b:(b['y'],b['x']))
    assert len(boxes)>index, f'Campo {index} ausente; campos={len(boxes)}'
    b=boxes[index];page.mouse.click(b['x']+b['width']*.4,b['y']+b['height']*.5)
    page.wait_for_timeout(250);page.keyboard.press('ControlOrMeta+A');page.wait_for_timeout(100)
    page.keyboard.type(value,delay=20);page.wait_for_timeout(500)

def shot(name): page.screenshot(path=str(OUT/(name+'.png')),full_page=True)

def select_filter(option):
    click('Todos os estados',False); click(option);page.wait_for_timeout(400)

TITLES=['Configuração de rede','Validação do sistema','Manutenção de notebook','Instalação de sistema']

def detail(title,origin='/demand-list'):
    open_route(origin);click(title,False);has(title);has('Abrir anexos')

def back_detail(title,origin):
    detail(title,origin);click('Minhas demandas')
    has('Histórico de demandas' if origin=='/demand-history' else 'Acompanhe suas demandas.')

def attachments(title,origin):
    open_route(origin);click(title,False)
    if origin!='/demand-attachments': click('Abrir anexos')
    has('Selecionar arquivos');has('Nenhum arquivo selecionado.')
    click('Voltar aos detalhes');has(title)

def choose_file(name,buffer):
    with page.expect_file_chooser(timeout=10000) as f: click('Selecionar arquivos')
    f.value.set_files(dict(name=name,mimeType='application/pdf',buffer=buffer));page.wait_for_timeout(800)

def upload_cases():
    detail(TITLES[0]);click('Abrir anexos')
    check('anexo: seleção local PDF',lambda:(choose_file('qa.pdf',b'%PDF-1.4\n%%EOF'),has('qa.pdf')))
    check('anexo: duplicado por nome recusado',lambda:(choose_file('qa.pdf',b'%PDF-1.4\n%%EOF'),has('já selecionado')))
    check('anexo: acima de 10 MiB recusado',lambda:(choose_file('grande.pdf',b'x'*(10*1024*1024+1)),has('excede 10 MB')))
    check('anexo: formato não permitido recusado',lambda:(choose_file('invalido.exe',b'MZbad'),has('formato não permitido')))
    check('anexo: remover seleção local',lambda:(click('Remover arquivo'),has('Nenhum arquivo selecionado.')))
    check('anexo: exatamente 10 MiB aceito localmente',lambda:(choose_file('limite.pdf',b'x'*(10*1024*1024)),has('limite.pdf')))
    check('anexo: remover arquivo no limite',lambda:(click('Remover arquivo'),has('Nenhum arquivo selecionado.')))

def homologation():
    detail(TITLES[0]);click('Abrir homologação');has('Li e concordo com a entrega')
    check('homologação: aprovação bloqueada antes da declaração',lambda:assert_disabled('Aprovar'))
    check('homologação: rejeição abre formulário',lambda:(click('Reprovar'),has('Solicitar ajustes')))
    check('homologação: ajuste vazio bloqueia envio',lambda:assert_disabled('Enviar solicitação'))
    check('homologação: ajuste com 9 caracteres bloqueia envio',lambda:(type_field(0,'123456789'),assert_disabled('Enviar solicitação')))
    check('homologação: cancelar solicitação',lambda:(click('Cancelar'),has('Li e concordo com a entrega')))
    def rejection():
        click('Reprovar');type_field(0,'Correção de teste com mais de dez caracteres');click('Enviar solicitação');has('Solicitação demonstrativa')
    check('homologação: solicitação válida demonstrativa',rejection)
    check('homologação: aceite demonstrativo',lambda:(click('Li e concordo com a entrega',False),click('Aprovar'),has('Aceite registrado (demonstração)')))
    check('homologação: retorno aos detalhes',lambda:(click('Voltar aos detalhes'),has('Abrir anexos')))

def assert_disabled(name):
    loc=page.get_by_role('button',name=name,exact=True)
    assert loc.count(),'Botão não exposto: '+name
    assert loc.first.is_disabled(),'Botão deveria estar desabilitado: '+name

def demo():
    check('dashboard: botão Ver demandas',lambda:(open_route('/'),click('Ver demandas'),has('Acompanhe suas demandas.')))
    for menu,title in [('Visão geral','Visão geral das demandas'),('Demandas','Acompanhe suas demandas.'),('Histórico','Histórico de demandas'),('Anexos','Central de anexos')]:
        check('menu lateral '+menu,lambda m=menu,t=title:(open_route('/'),click(m),has(t)))
    for route,title in [('/','Visão geral das demandas'),('/demand-list','Minhas demandas'),('/demand-history','Histórico de demandas'),('/demand-attachments','Central de anexos')]:
        check('rota direta desktop '+route,lambda r=route,t=title:(open_route(r),has(t)))
        for width in (390,800):
            def mobile(r=route,t=title,w=width):
                open_route(r,w);has(t);shot(f'mobile-{w}-{r.replace("/","") or "home"}')
                if r!='/':
                    nav=page.get_by_label('Visão geral',exact=True).count()+page.get_by_role('button',name=re.compile('menu|voltar',re.I)).count()
                    assert nav>0,'Sem menu/retorno interno nesta largura'
            check(f'navegação {width}px '+route,mobile)
    for title in TITLES:
        for origin in ('/demand-list','/demand-history'):
            check('detalhes '+origin+' '+title,lambda t=title,o=origin:detail(t,o))
            check('retorno detalhes '+origin+' '+title,lambda t=title,o=origin:back_detail(t,o))
        for origin in ('/demand-list','/demand-attachments'):
            check('anexos e retorno '+origin+' '+title,lambda t=title,o=origin:attachments(t,o))
    def search(query,expected):
        open_route('/demand-list');type_field(0,query);has(expected)
    for query,expected in [('notebook','Manutenção de notebook'),('AUT-002','Configuração de rede'),('CONECTIVIDADE','Configuração de rede'),('zzzinexistente','Nenhuma demanda encontrada')]:
        check('busca '+query,lambda q=query,e=expected:search(q,e))
    for option,expected in [('Planejamento','Nenhuma demanda encontrada para este estado'),('Execução','Manutenção de notebook'),('Homologação','Configuração de rede'),('Concluído','Instalação de sistema'),('Todos os estados','Configuração de rede')]:
        check('filtro '+option,lambda o=option,e=expected:(open_route('/demand-list'),select_filter(o),has(e)))
    check('atualizar demandas',lambda:(open_route('/demand-list'),click('Atualizar demandas'),has(TITLES[0])))
    check('anexos: controles e validações',upload_cases)
    check('homologação: percurso completo',homologation)
    def resize():
        open_route('/demand-list',1440);page.set_viewport_size(dict(width=800,height=900));page.wait_for_timeout(800);shot('redimensionamento-1440-800')
        assert page.get_by_label('Visão geral',exact=True).count()==0,'Sidebar desktop permaneceu após reduzir largura abaixo de 900'
    check('redimensionamento desktop para tablet',resize)
    check('demonstração: não faz chamadas à API',lambda: no_api())

def no_api():
    assert not requests,'Demonstração fez chamadas inesperadas';return 'Nenhuma API chamada; ações locais não demonstram persistência.'

def login(profile='cliente',password=None):
    open_route();type_field(0,f'{profile}.demo@automatize.local');type_field(1,password or os.environ['DEMO_CLIENTE_PASSWORD'])
    with page.expect_response(lambda r:r.url.endswith('/auth/login') and r.request.method=='POST',timeout=20000) as response: click('Entrar na plataforma')
    expected=401 if password else 200
    assert response.value.status==expected,f'Login HTTP {response.value.status}, esperado {expected}'
    page.wait_for_timeout(1200)

def official():
    check('login: credencial inválida recusada',lambda:login(password='senha-incorreta-qa'))
    for profile in ('cliente','tecnico','admin'):
        check(profile+': login real',lambda p=profile:login(p))
        check(profile+': listar demandas reais',lambda:(click('Ver lista de demandas'),has('demanda')))
        shot(profile+'-lista')
        check(profile+': atualizar lista',lambda:click('Atualizar demandas'))
        if VAR=='admin-pr15' and profile=='admin':
            check('admin: abrir painel',lambda:(click('Painel administrativo'),has('Nova demanda')))
            check('admin: abrir e cancelar nova demanda',lambda:(click('Nova demanda'),has('Cliente'),click('Cancelar')))
            check('admin: abrir usuários',lambda:(click('Usuários'),has('Usuários e perfis')))
            check('admin: formulário de novo usuário',lambda:(click('Novo usuário'),has('Senha inicial')))
            check('admin: validação formulário vazio',lambda:(click('Cadastrar'),has('Informe')))
            check('admin: cancelar novo usuário',lambda:click('Cancelar'))
            shot('admin-usuarios')
        elif VAR=='admin-pr15':
            check(profile+': não expor painel administrativo',lambda:assert_no_admin())
        check(profile+': recarregar exige nova autenticação',lambda:(page.reload(wait_until='networkidle'),semantics(),has('Entrar na plataforma')))
    def offline():
        login();click('Ver lista de demandas');context.set_offline(True)
        try: click('Atualizar demandas');page.wait_for_timeout(1500);has('Não foi possível')
        finally: context.set_offline(False)
    check('cliente: API indisponível tem mensagem de erro',offline)
    check('cliente: jornadas de escrita e sessão',client_operations)
    if VAR=='admin-pr15': check('admin: jornadas de escrita reais',admin_operations)



def client_operations():
    login();click('Ver lista de demandas')
    def creation():
        click('Nova demanda');click('Salvar Demanda');has('O título é obrigatório.')
        type_field(0,'QA Cliente Navegador');type_field(1,'Cadastro validado pelo navegador com API e PostgreSQL reais.');click('Salvar Demanda');page.wait_for_timeout(1000)
        token=req('POST','/auth/login',data={'email':'cliente.demo@automatize.local','senha':os.environ['DEMO_CLIENTE_PASSWORD']})['access_token']
        rows=req('GET','/demandas?busca=QA%20Cliente',token);assert any(x['titulo']=='QA Cliente Navegador' for x in rows)
    check('cliente: validação vazia e criação persistida',creation)
    def search():
        type_field(0,'QA Cliente Navegador');has('QA Cliente Navegador');type_field(0,'zzzinexistente');has('Nenhuma demanda encontrada');click('Limpar busca');has('QA Cliente Navegador')
    check('cliente: busca, estado vazio e limpar',search)
    check('cliente: abrir e fechar detalhes',lambda:(click('Ver detalhes'),has('Detalhes da demanda'),click('Entendi')))
    def logout():
        click('Sair da conta');click('Continuar aqui');has('Nova demanda');click('Sair da conta');click('Sair');has('Entrar na plataforma');page.go_back();page.wait_for_timeout(600);assert 'Nova demanda' not in labels(),'Voltar recuperou tela autenticada após logout'
    check('cliente: cancelar saída, sair e bloquear retorno',logout)
    for route in ('/home','/demand-list','/demand-details','/admin'):
        if route=='/admin' and VAR!='admin-pr15':continue
        check('rota protegida sem sessão '+route,lambda r=route:(open_route(r),has('Entrar na plataforma')))


def user_menu(name,action):
    target=page.get_by_text(name,exact=True)
    if not target.count(): target=page.get_by_label(name,exact=False)
    assert target.count(),'Usuário não encontrado na interface: '+name
    box=target.first.bounding_box();assert box
    menus=[]
    for loc in page.get_by_role('button',name=re.compile('Ações do usuário|Mostrar menu|Show menu',re.I)).all():
        b=loc.bounding_box()
        if b: menus.append((abs(b['y']+b['height']/2-box['y']-box['height']/2),loc))
    if menus:
        distance,loc=min(menus,key=lambda x:x[0]);assert distance<90,'Menu não corresponde à linha alvo'
        loc.click()
    else:
        # The rendered Flutter popup icon has no label in this build. Coordinates
        # are grounded in falha-037.png (1440 px): icon x=1155, row title +12 px.
        assert page.viewport_size['width']==1440,'Fallback exige viewport validado'
        page.mouse.click(1155,box['y']+box['height']/2+12)
    page.wait_for_timeout(650)
    has('Alterar perfil');click(action)

def admin_operations():
    token=req('POST','/auth/login',data={'email':'admin.demo@automatize.local','senha':os.environ['DEMO_ADMIN_PASSWORD']})['access_token']
    alternate=req('POST','/usuarios',token,data={'nome':'QA Tecnico Alternativo','email':'qa.tecnico@example.com','senha':'Qa-Senha-Sintetica-2026','perfil':'TECNICO'},expected=201)
    login('admin');click('Ver lista de demandas');click('Painel administrativo')
    def create_demand():
        click('Nova demanda');type_field(0,'QA Jornada completa');type_field(1,'Demanda criada no navegador e confirmada na API real.');click('Cliente');click('Cliente DEMO',False);click('Cadastrar');page.wait_for_timeout(1200)
        rows=req('GET','/demandas?busca=QA%20Jornada',token)
        assert any(d['titulo']=='QA Jornada completa' for d in rows),'Cadastro não persistiu na API'
        return 'POST real confirmado por GET independente'
    check('admin: cadastrar demanda pela UI e confirmar persistência',create_demand)
    def edit_demand():
        click('QA Jornada completa',False);click('Editar');type_field(0,'QA Jornada editada');click('Salvar');page.wait_for_timeout(800)
        rows=req('GET','/demandas?busca=QA%20Jornada',token);assert any(d['titulo']=='QA Jornada editada' for d in rows)
    check('admin: editar demanda pela UI e confirmar persistência',edit_demand)
    def assign():
        click('Atribuir técnico');click('Técnico');click('Tecnico DEMO',False);click('Atribuir');page.wait_for_timeout(800)
        rows=req('GET','/demandas?busca=QA%20Jornada',token);assert rows[0]['responsavel_id']
        history=req('GET','/demandas/'+rows[0]['id']+'/historico',token);assert any(x['acao']=='ATRIBUICAO_RESPONSAVEL' for x in history)
    check('admin: atribuir técnico pela UI e confirmar auditoria',assign)
    def reassign():
        click('Trocar técnico');click('Técnico');click('QA Tecnico Alternativo',False);click('Trocar');has('Descreva o motivo')
        type_field(0,'Troca de responsável validada pelo navegador');click('Trocar');page.wait_for_timeout(800)
        demand=req('GET','/demandas?busca=QA%20Jornada',token)[0];assert demand['responsavel_id']==alternate['id']
        history=req('GET','/demandas/'+demand['id']+'/historico',token)
        assert any((e.get('detalhes') or {}).get('motivo')=='Troca de responsável validada pelo navegador' for e in history)
        previous=req('POST','/auth/login',data={'email':'tecnico.demo@automatize.local','senha':os.environ['DEMO_TECNICO_PASSWORD']})['access_token']
        req('GET','/demandas/'+demand['id'],previous,expected=404)
        new=req('POST','/auth/login',data={'email':'qa.tecnico@example.com','senha':'Qa-Senha-Sintetica-2026'})['access_token']
        req('GET','/demandas/'+demand['id'],new)
    check('admin: trocar técnico exige motivo, audita e altera o acesso',reassign)
    def delete():
        click('Excluir');click('Cancelar');has('QA Jornada editada');click('Excluir');click('Excluir');page.wait_for_timeout(800)
        rows=req('GET','/demandas?busca=QA%20Jornada',token);assert not rows,'Exclusão não persistiu'
    check('admin: cancelar e confirmar exclusão de demanda',delete)
    login('admin');click('Ver lista de demandas');click('Painel administrativo');click('Usuários')
    def create_user():
        click('Novo usuário');type_field(0,'QA Usuario Navegador');type_field(1,'qa.navegador@example.com');type_field(2,'Qa-Senha-Sintetica-2026');click('Perfil');click('Cliente');click('Cadastrar');page.wait_for_timeout(1000)
        users=req('GET','/usuarios',token);assert any(u['email']=='qa.navegador@example.com' for u in users)
        req('POST','/auth/login',data={'email':'qa.navegador@example.com','senha':'Qa-Senha-Sintetica-2026'})
        return 'Usuário criado pela UI consegue autenticar na API'
    check('admin: cadastro real de usuário e login independente',create_user)
    def toggle_user():
        users=req('GET','/usuarios',token);user=next(u for u in users if u['email']=='qa.navegador@example.com')
        user_menu('QA Usuario Navegador','Inativar');click('Inativar')
        assert next(u for u in req('GET','/usuarios',token) if u['id']==user['id'])['ativo'] is False
        req('POST','/auth/login',data={'email':user['email'],'senha':'Qa-Senha-Sintetica-2026'},expected=401)
        user_menu('QA Usuario Navegador','Reativar');click('Reativar')
        req('POST','/auth/login',data={'email':user['email'],'senha':'Qa-Senha-Sintetica-2026'})
    check('admin: inativar e reativar usuário pela UI com login confirmado',toggle_user)
    def change_profile():
        user_menu('QA Usuario Navegador','Alterar perfil');click('Tornar Técnico');page.wait_for_timeout(800)
        user=next(u for u in req('GET','/usuarios',token) if u['email']=='qa.navegador@example.com')
        assert user['perfil']=='TECNICO'
    check('admin: alterar perfil pela UI e confirmar API',change_profile)
    check('admin: filtros de todos os perfis e limpar',filter_admin_users)
    shot('admin-final')


def filter_admin_users():
    for profile,expected,hidden in [('Administrador','Admin DEMO','Cliente DEMO'),('Cliente','Cliente DEMO','QA Usuario Navegador'),('Técnico','QA Usuario Navegador','Cliente DEMO')]:
        click(re.compile('^'+profile+r' \('));has(expected)
        assert page.get_by_text(hidden,exact=True).count()==0,'Filtro de perfil mantém pessoa de outro perfil na lista'
    click(re.compile(r'^Todos \('));has('Cliente DEMO');has('QA Usuario Navegador')

def admin_filter_only():
    token=req('POST','/auth/login',data={'email':'admin.demo@automatize.local','senha':os.environ['DEMO_ADMIN_PASSWORD']})['access_token']
    req('POST','/usuarios',token,data={'nome':'QA Usuario Navegador','email':'qa.filtro@example.com','senha':'Qa-Senha-Sintetica-2026','perfil':'TECNICO'},expected=201)
    login('admin');click('Ver lista de demandas');click('Painel administrativo');click('Usuários')
    check('admin: filtros de todos os perfis e limpar',filter_admin_users)

def assert_no_admin():
    assert page.get_by_label('Painel administrativo',exact=True).count()==0,'Perfil não administrador recebeu controle administrativo'

with sync_playwright() as p:
    browser=p.chromium.launch();context=browser.new_context(viewport=dict(width=1440,height=1000));page=context.new_page();page.set_default_timeout(7000)
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.on('response',lambda r:requests.append(dict(method=r.request.method,path=r.url.replace(BASE,''),status=r.status)) if r.url.startswith(BASE) else None)
    try:
        if os.environ.get('QA_MODE')=='admin-filters':
            admin_filter_only()
        elif os.environ.get('QA_MODE')=='admin-write':
            check('admin: jornadas de escrita reais',admin_operations)
        else:
            demo() if VAR=='tecnico-pr16' else official()
    except Exception as exc: results.append(dict(name='harness',status='FAIL',error=str(exc),trace=traceback.format_exc()))
    if errors: results.append(dict(name='erros JavaScript',status='FAIL',errors=errors))
    context.close();browser.close()
report=dict(variant=VAR,cases=results,network=requests,runtime_errors=errors,limits=['Sem Supabase Storage real no runner','Demonstração sem persistência/API','Combinações não exercitadas não são consideradas aprovadas'])
(OUT/'jornadas.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
print(json.dumps(dict(variant=VAR,passed=sum(x['status']=='PASS' for x in results),failed=sum(x['status']=='FAIL' for x in results)),ensure_ascii=False))

raise SystemExit(1 if any(c['status']=='FAIL' for c in results) else 0)
