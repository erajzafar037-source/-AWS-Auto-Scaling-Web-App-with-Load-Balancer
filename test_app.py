from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_root_has_version():
    r = client.get("/")
    assert r.status_code == 200
    assert "version" in r.json()
