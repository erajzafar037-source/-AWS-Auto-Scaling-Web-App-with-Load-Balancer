import os, socket, time
from fastapi import FastAPI

VERSION = os.getenv("APP_VERSION", "1.0.0")
START = time.time()
app = FastAPI(title="Autoscaling Demo App", version=VERSION)


@app.get("/")
def root():
    return {"message": "Hello from AWS ASG", "version": VERSION, "host": socket.gethostname()}


@app.get("/health")
def health():
    return {"status": "ok", "uptime_s": round(time.time() - START, 1)}


@app.get("/cpu")
def cpu(n: int = 2_000_000):
    """Burn CPU so you can trigger the scale-out policy during load tests."""
    n = min(n, 20_000_000)
    s = 0
    for i in range(n):
        s += i * i
    return {"iterations": n}
