
import os
from flask import Flask, jsonify, Response
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"]
)


@app.before_request
def count_request():
    from flask import request, g
    g.start_time = None


@app.after_request
def record_request(response):
    from flask import request

    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.path,
        status=response.status_code
    ).inc()

    return response


@app.route("/healthz")
def healthz():
    return jsonify(status="healthy"), 200


@app.route("/version")
def version():
    return jsonify(
        version=os.getenv("GIT_COMMIT", "unknown")
    ), 200


@app.route("/metrics")
def metrics():
    return Response(
        generate_latest(),
        mimetype=CONTENT_TYPE_LATEST
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
