"""Verifica entrada pública, documentação indicada e health sem autenticação."""
from fastapi.testclient import TestClient
from app.main import app

def test_public_entrypoint_links_to_working_documentation_and_health():
    with TestClient(app) as client:
        root=client.get('/')
        assert root.status_code==200
        assert root.headers['content-type'].startswith('application/json')
        assert client.get(root.json()['docs']).status_code==200
        assert client.get('/health').status_code==200

# Exercise successful HTTP serialization/persistence as well as service tests.
import pytest
from tests.integration.conftest import engine,db,criar_usuario,storage  # noqa: F401,E402
from tests.integration.test_demandas_acoes_api import atores,auth,client,demanda_id,settings  # noqa: F401,E402

@pytest.mark.parametrize('perfil',['cliente','admin'])
def test_successful_http_edit_is_persisted_and_audited(client,auth,demanda_id,perfil):
    response=client.patch(f'/demandas/{demanda_id}',headers=auth[perfil],json={'titulo':'Editada pelo HTTP','descricao':'Descrição alterada pela API de teste.'})
    assert response.status_code==200,response.text
    persisted=client.get(f'/demandas/{demanda_id}',headers=auth['cliente'])
    assert persisted.json()['titulo']=='Editada pelo HTTP'
    history=client.get(f'/demandas/{demanda_id}/historico',headers=auth['admin'])
    assert history.status_code==200
    assert any(e['acao']=='EDICAO_DEMANDA' for e in history.json())

def test_successful_http_delete_hides_demand_and_requires_admin(client,auth,demanda_id):
    assert client.delete(f'/demandas/{demanda_id}',headers=auth['cliente']).status_code==403
    deleted=client.delete(f'/demandas/{demanda_id}',headers=auth['admin'])
    assert deleted.status_code==204,deleted.text
    assert not deleted.content
    assert client.get(f'/demandas/{demanda_id}',headers=auth['cliente']).status_code==404
