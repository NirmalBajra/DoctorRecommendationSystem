"""
Optional Flask API for PHP integration via HTTP instead of shell_exec.
Exposes POST /predict endpoint.

Plan: docs/implementation-plan/python/01-ml-pipeline.md — Task 5

Usage:
    python ml/app.py
    # Runs on http://127.0.0.1:5000

Endpoints:
    GET  /health  — returns {"status": "ok"}
    POST /predict — body: {"symptoms": "fever,cough"} — returns prediction JSON
"""

# TODO: Implement — see implementation plan above
