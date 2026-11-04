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
