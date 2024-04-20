from hasura_ndc.connector import Connector
from hasura_ndc.main import start
from hasura_ndc.models import *
from pydantic import BaseModel
import inspect


class Configuration(BaseModel):
    pass


class State(BaseModel):
    pass


class FunctionConnector(Connector[Configuration, State]):

    def __init__(self):
        super().__init__(Configuration, State)
        self.query_functions = {}
        self.mutation_functions = {}

    async def parse_configuration(self, configuration_dir: str) -> Configuration:
        config = Configuration()
        return config

    async def try_init_state(self, configuration: Configuration, metrics: Any) -> State:
        return State()

    async def get_capabilities(self, configuration: Configuration) -> CapabilitiesResponse:
        return CapabilitiesResponse(
            version="^0.1.0",
            capabilities=Capabilities(
                query=QueryCapabilities(
                    aggregates=LeafCapability(),
                    variables=LeafCapability(),
                    explain=LeafCapability()
                ),
                mutation=MutationCapabilities(
                    transactional=LeafCapability(),
                    explain=None
                ),
                relationships=RelationshipCapabilities(
                    relation_comparisons=LeafCapability(),
                    order_by_aggregate=LeafCapability()
                )
            )
        )

    async def query_explain(self,
                            configuration: Configuration,
                            state: State,
                            request: QueryRequest) -> ExplainResponse:
        pass

    async def mutation_explain(self,
                               configuration: Configuration,
                               state: State,
                               request: MutationRequest) -> ExplainResponse:
        pass

    async def fetch_metrics(self,
                            configuration: Configuration,
                            state: State) -> Optional[None]:
        pass

    async def health_check(self,
                           configuration: Configuration,
                           state: State) -> Optional[None]:
        pass

    async def get_schema(self, configuration: Configuration) -> SchemaResponse:
        functions = []
        procedures = []

        for name, func in self.query_functions.items():
            function_info = self.generate_function_info(name, func)
            functions.append(function_info)

        for name, func in self.mutation_functions.items():
            procedure_info = self.generate_procedure_info(name, func)
            procedures.append(procedure_info)

        schema_response = SchemaResponse(
            scalar_types={},
            functions=functions,
            procedures=procedures,
            object_types={},
            collections=[]
        )

        return schema_response

    def generate_function_info(self, name, func):
        signature = inspect.signature(func)
        arguments = {
            arg_name: {
                "type": self.get_type_info(arg_type)
            }
            for arg_name, arg_type in signature.parameters.items()
        }
        return FunctionInfo(
            name=name,
            arguments=arguments,
            result_type=self.get_type_info(signature.return_annotation)
        )

    def generate_procedure_info(self, name, func):
        signature = inspect.signature(func)
        arguments = {
            arg_name: {
                "type": self.get_type_info(arg_type)
            }
            for arg_name, arg_type in signature.parameters.items()
        }
        return ProcedureInfo(
            name=name,
            arguments=arguments,
            result_type=self.get_type_info(signature.return_annotation)
        )

    @staticmethod
    def get_type_info(typ):
        if isinstance(typ, inspect.Parameter):
            typ = typ.annotation
        if typ == int:
            return Type(type="named", name="Int")
        elif typ == float:
            return Type(type="named", name="Float")
        elif typ == str:
            return Type(type="named", name="String")
        elif typ == bool:
            return Type(type="named", name="Boolean")
        else:
            return Type(type="named", name=typ.__name__)

    async def query(self, configuration: Configuration, state: State, request: QueryRequest) -> QueryResponse:
        print("QUERY")
        print(request)
        print(self.query_functions)
        return [
            RowSet(
                aggregates=None,
                rows=None
            )
        ]

    async def mutation(self, configuration: Configuration,
                       state: State,
                       request: MutationRequest) -> MutationResponse:
        responses = []
        for operation in request.operations:
            operation_name = operation.name
            func = self.mutation_functions[operation_name]
            args = operation.arguments if operation.arguments else {}
            response = func(**args)
            responses.append(response)
        return MutationResponse(
            operation_results=[
                MutationOperationResults(
                    type="procedure",
                    result=response
                ) for response in responses
            ]
        )

    def register_query(self, func):
        self.query_functions[func.__name__] = func
        return func

    def register_mutation(self, func):
        self.mutation_functions[func.__name__] = func
        return func


# # TODO: Handle Pydantic types in the introspection
# class Tmp(BaseModel):
#     x: str
#     y: int
#     z: float

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
