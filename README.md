### Proof of concept NDC lambda connector for Python.

This is a work in progress.

To see a more in-depth example that implements the Python SDK please see: https://github.com/hasura/ndc-turso-python

Currently, the proposed functionality will look something like this:

```python
from hasura_ndc_lambda import FunctionConnector, start

connector = FunctionConnector()


@connector.register_query
def do_the_thing(x: int) -> str:
    print(x)
    return "Hello World"


@connector.register_mutation
def some_mutation_function(arg1: str, arg2: int) -> str:
    # Mutation function implementation
    return f"Hey {arg1} {arg2}"


if __name__ == "__main__":
    start(connector)
```

There will be support for built-in scalar types (int, float, str, bool) and also planned support for Pydantic types.


## TODO: Allow adding of async queries/mutations?

## TODO: Add Pydantic type introspections