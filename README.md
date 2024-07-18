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