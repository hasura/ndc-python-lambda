FROM ghcr.io/hasura/ndc-python-lambda:v{{VERSION}}

COPY requirements.txt /functions/

WORKDIR /functions
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

COPY ./ /functions