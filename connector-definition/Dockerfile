FROM ghcr.io/hasura/ndc-python-lambda:v{{VERSION}}

COPY requirements.txt /functions/

WORKDIR /functions

# create the group and user
RUN adduser -u 1000 python

RUN chown -R python:python /functions

# Switch to python user before activating venv - the alternative is to run chown on installed
# dependencies afterward, which takes a long time.
USER python

RUN python3 -m venv venv && \
  . venv/bin/activate && \
  pip install --upgrade pip>=25.3 && \
  pip install -r requirements.txt

COPY --chown=python:python ./ /functions
