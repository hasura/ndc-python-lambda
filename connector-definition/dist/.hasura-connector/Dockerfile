FROM ghcr.io/hasura/ndc-python-lambda:v0.0.0

COPY requirements.txt /functions/

WORKDIR /functions
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

COPY ./ /functions