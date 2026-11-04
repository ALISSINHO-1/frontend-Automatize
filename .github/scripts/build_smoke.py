"""Smoke de builds Flutter com API real e dados exclusivos do runner."""
import json
import os
import re
import time
from pathlib import Path
from urllib.request import Request, urlopen

from playwright.sync_api import sync_playwright

OUT = Path(os.environ["REPORT_DIR"])
OUT.mkdir(parents=True, exist_ok=True)
BASE = "http://127.0.0.1:8000"
report = {"variant": os.environ["VARIANT"], "api": [], "browser": [], "errors": []}


def api(path, data=None, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    request = Request(BASE + path, data=json.dumps(data).encode() if data is not None else None, headers=headers)
    with urlopen(request, timeout=15) as response:
        payload = json.load(response)
        report["api"].append({"path": path, "status": response.status})
        return payload


def enable_semantics(page):
    placeholder = page.locator("flt-semantics-placeholder")
    if placeholder.count():
        placeholder.first.evaluate("el => el.click()")
    page.wait_for_timeout(1500)


def click_label(page, text):
    # O Flutter CanvasKit expoe os textos pelo aria-label da arvore semantica.
    candidate = page.get_by_role("button", name=text, exact=True)
    if candidate.count():
        candidate.first.click()
        return
    candidate = page.get_by_label(text, exact=True)
    if candidate.count():
        candidate.first.click()
        return
    raise AssertionError("Controle nao encontrado: " + text)


try:
    password = os.environ["DEMO_CLIENTE_PASSWORD"]
    for profile in ("admin", "tecnico", "cliente"):
        token = api("/auth/login", {"email": f"{profile}.demo@automatize.local", "senha": password})["access_token"]
        identity = api("/auth/me", token=token)
        assert identity["perfil"] == profile.upper()
        api("/demandas", token=token)
    token = api("/auth/login", {"email": "cliente.demo@automatize.local", "senha": password})["access_token"]
    created = api("/demandas", {"titulo": "Smoke do build Flutter", "descricao": "Criado somente no PostgreSQL descartavel do runner."}, token)
    api("/demandas/" + created["id"], token=token)

    with sync_playwright() as p:
        browser = p.chromium.launch()
        variant = os.environ["VARIANT"]
        profiles = ("cliente", "admin") if variant == "admin-pr15" else ("cliente",)
        if variant == "tecnico-pr16":
            profiles = ("demo",)
        for profile in profiles:
            context = browser.new_context(viewport={"width": 1440, "height": 1000})
            page = context.new_page()
            network = []
            runtime_errors = []
            page.on("pageerror", lambda error: runtime_errors.append(str(error)))
            page.on("response", lambda response: network.append({"url": response.url.split("?")[0], "status": response.status}) if response.url.startswith(BASE) else None)
            entry = {"profile": profile, "api_requests": network, "runtime_errors": runtime_errors}
            report["browser"].append(entry)
            try:
                page.goto("http://127.0.0.1:8080", wait_until="networkidle", timeout=90000)
                page.wait_for_selector("flutter-view", timeout=90000)
                enable_semantics(page)
                page.screenshot(path=str(OUT / f"{profile}-inicial.png"), full_page=True)
                if profile == "demo":
                    entry["integration"] = "Dados demonstrativos; nao usa API nem login."
                    click_label(page, "Demandas")
                    page.wait_for_timeout(1000)
                    page.screenshot(path=str(OUT / "tecnico-demandas-desktop.png"), full_page=True)
                    page.set_viewport_size({"width": 800, "height": 900})
                    page.wait_for_timeout(1000)
                    page.screenshot(path=str(OUT / "tecnico-demandas-redimensionado.png"), full_page=True)
                    entry["sidebar_apos_reduzir"] = page.get_by_label("Demandas", exact=True).count() > 0
                    page.goto("http://127.0.0.1:8080/#/demand-list", wait_until="networkidle")
                    enable_semantics(page)
                    page.screenshot(path=str(OUT / "tecnico-demandas-mobile-inicial.png"), full_page=True)
                    entry["status"] = "demo_loaded"
                else:
                    fields = page.get_by_role("textbox")
                    assert fields.count() >= 2, "Campos de login nao expostos pela semantica Flutter"
                    # Flutter mantem um espelho semantico e um editor nativo.
                    # fill() no espelho pode nao atualizar o TextEditingController.
                    # Clicar na geometria do campo e digitar testa o fluxo real.
                    boxes = [field.bounding_box() for field in fields.all()]
                    boxes = [box for box in boxes if box and box['width'] > 50 and box['height'] > 10]
                    boxes.sort(key=lambda box: box['y'])
                    assert len(boxes) >= 2, "Geometria dos campos de login indisponivel"
                    entry['input_geometry'] = boxes
                    for box, value in ((boxes[0], f"{profile}.demo@automatize.local"), (boxes[-1], password)):
                        page.mouse.click(box['x'] + box['width'] * 0.4, box['y'] + box['height'] * 0.5)
                        page.wait_for_timeout(300)
                        page.keyboard.press('ControlOrMeta+A')
                        page.wait_for_timeout(100)
                        page.keyboard.type(value, delay=25)
                    with page.expect_response(lambda r: r.url.endswith("/auth/login") and r.request.method == 'POST', timeout=30000) as login:
                        click_label(page, "Entrar na plataforma")
                    sent = login.value.request.post_data_json
                    entry['credentials_match_fixture'] = {
                        'email': sent.get('email') == f'{profile}.demo@automatize.local',
                        'password': sent.get('senha') == password,
                        'password_length': len(sent.get('senha','')),
                    }
                    assert sent.get('email') == f'{profile}.demo@automatize.local', 'Automacao digitou email diferente da fixture'
                    assert sent.get('senha') == password, 'Automacao digitou senha diferente da fixture'
                    assert login.value.status == 200, f'Login retornou HTTP {login.value.status} com credenciais conferidas'
                    page.wait_for_timeout(1500)
                    page.screenshot(path=str(OUT / f"{profile}-home.png"), full_page=True)
                    with page.expect_response(lambda r: "/demandas" in r.url and r.request.method == "GET", timeout=30000) as demands:
                        click_label(page, "Ver lista de demandas")
                    assert demands.value.status == 200
                    page.wait_for_timeout(1500)
                    page.screenshot(path=str(OUT / f"{profile}-demandas.png"), full_page=True)
                    entry["login_and_demands"] = "passed"
                    if profile == "admin":
                        click_label(page, "Painel administrativo")
                        page.wait_for_timeout(2000)
                        page.screenshot(path=str(OUT / "admin-painel.png"), full_page=True)
                        assert any("/auth/me" in r["url"] and r["status"] == 200 for r in network)
                        assert any("/usuarios" in r["url"] and r["status"] == 200 for r in network)
                    entry["status"] = "passed"
                assert not runtime_errors, "Erros JavaScript no navegador"
            except Exception as error:
                entry["status"] = "failed"
                entry["error"] = str(error)
                page.screenshot(path=str(OUT / f"{profile}-falha.png"), full_page=True)
                report["errors"].append(f"{profile}: {error}")
            finally:
                context.close()
        browser.close()
except Exception as error:
    report["errors"].append(str(error))
finally:
    (OUT / "smoke.json").write_text(json.dumps(report, indent=2, ensure_ascii=False))
    print(json.dumps(report, indent=2, ensure_ascii=False))
raise SystemExit(1 if report["errors"] else 0)
