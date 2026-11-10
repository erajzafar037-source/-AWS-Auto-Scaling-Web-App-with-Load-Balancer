"""Integration test against the load-balanced URL.
APP_URL=https://<alb-dns> [EXPECT_VERSION=abc1234] pytest tests/
"""
import os
import httpx
import pytest

APP_URL = os.getenv("APP_URL")
pytestmark = pytest.mark.skipif(not APP_URL, reason="APP_URL not set")


def client():
    return httpx.Client(base_url=APP_URL, verify=False, timeout=10)  # lab cert is self-signed


def test_health():
    assert client().get("/health").json()["status"] == "ok"


def test_https_redirect():
    http_url = APP_URL.replace("https://", "http://")
    r = httpx.get(http_url, follow_redirects=False, timeout=10)
    assert r.status_code == 301


def test_load_balanced_across_instances():
    with client() as c:
        hosts = {c.get("/").json()["host"] for _ in range(60)}
    assert len(hosts) >= 2, f"expected >=2 instances behind ALB, saw {hosts}"


def test_expected_version_deployed():
    expected = os.getenv("EXPECT_VERSION")
    if not expected:
        pytest.skip("EXPECT_VERSION not set")
    with client() as c:
        versions = {c.get("/").json()["version"] for _ in range(40)}
    assert versions == {expected}
