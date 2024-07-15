from hasura_ndc import start
from hasura_ndc.instrumentation import with_active_span
from opentelemetry.trace import get_tracer
from hasura_ndc.function_connector import FunctionConnector
from pydantic import BaseModel

connector = FunctionConnector()
tracer = get_tracer("ndc-sdk-python.server")

@connector.register_query
def do_the_thing(x: int):
    return f"Hello World {x}"


@connector.register_mutation
def some_mutation_function(arg1: str,
                           arg2: int):
    return f"Hey {arg1} {arg2}"

@connector.register_query
async def my_query(x: str) -> str:
    return await with_active_span(
        tracer,
        "My Span",
        lambda span: f"My string is {x}",
        {"attr": "value"}
    )

@connector.register_query
async def my_query2(x: str):
    async def f(span):
        # return f"My string is {x}"
        return {
            "hey": "x",
            "var": x,
            10.1: 10.1,
            "dict": {
                1.0: 10
            },
            "floatables": [1.234, 10, "yep"]
        }

    return await with_active_span(
        tracer,
        "My Span",
        f,
        {"attr": "value"}
    )


if __name__ == "__main__":
    start(connector)
