### Hasura Python Lambda Connector

This connector allows you to write Python code and call it using Hasura!

With Hasura, you can integrate -- and even host -- this business logic directly with Hasura DDN and your API.

You can handle custom business logic using the Python Lambda data connector. Using this connector, you can transform or enrich data before it reaches your customers, or perform any other business logic you may need.

You can then integrate these functions as individual commands in your metadata and reulsting API.
This process enables you to simplify client applications and speed up your backend development!

## Setting up the Python Lambda connector

### Prerequisites:
In order to follow along with this guide, you will need:
* [The DDN CLI, VS Code extension, and Docker installed](https://hasura.io/docs/3.0/getting-started/build/prerequisites/)
* Python version `>= 3.11`

In this guide we will setup a new Hasura DDN project from scratch.

### Step-by-step guide

Create a new directory that will contain your Hasura project and change directories into it.

```mkdir ddn && cd ddn```

Create a new supergraph:

```ddn supergraph init --dir .```

Start a watch session, additionally split of a new terminal to continue running commands from.

```HASURA_DDN_PAT=$(ddn auth print-pat) docker compose up --build --watch```

In the new terminal, perform a local build:

```ddn supergraph build local --output-dir engine```

Initialize a subgraph:

```
ddn subgraph init python \
  --dir python \
  --target-supergraph supergraph.local.yaml \
  --target-supergraph supergraph.cloud.yaml
```

Initialize a Python connector:

```
ddn connector init python \
  --subgraph python/subgraph.yaml \
  --hub-connector hasura/python \
  --configure-port 8085 \
  --add-to-compose-file compose.yaml
```

In the `.env.local` you will need to remove the `HASURA_CONNECTOR_PORT` variable which is set to `8085`. This is because the connector will run on that port but the docker-mapping is set to map 8085 -> 8080.

Before:
```
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://local.hasura.dev:4317
OTEL_SERVICE_NAME=python_python
HASURA_CONNECTOR_PORT=8085
```

After:
```
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://local.hasura.dev:4317
OTEL_SERVICE_NAME=python_python
```

Add the connector link:

```
ddn connector-link add python \
  --subgraph python/subgraph.yaml \
  --configure-host http://local.hasura.dev:8085 \
  --target-env-file python/.env.python.local
```

Stop the watch session using Ctrl-C and restart it.

```
HASURA_DDN_PAT=$(ddn auth print-pat) docker compose up --build --watch
```

Once the connector is running, you can update the connector-link.

```
ddn connector-link update python \
  --subgraph python/subgraph.yaml \
  --env-file python/.env.python.local \
  --add-all-resources
```

Push the build to the locally running engine:

```
ddn supergraph build local \
  --output-dir engine \
  --subgraph-env-file python:python/.env.python.local
```

Now you should be able to write your code in the `functions.py` file, and each time you make changes and save the connector should automatically restart inside the watch session, you'll then need to track those changes and push them to engine.

You can do that by re-running the above commands:

To track the changes:

```
ddn connector-link update python \
  --subgraph python/subgraph.yaml \
  --env-file python/.env.python.local \
  --add-all-resources
```

To push these changes to engine:

```
ddn supergraph build local \
  --output-dir engine \
  --subgraph-env-file python:python/.env.python.local
```