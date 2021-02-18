-module(grpc_plugin).

-export([init/1]).

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    {ok, State1} = grpc_plugin_prv:init(State),
    {ok, State2} = grpc_plugin_clean_prv:init(State1),
    {ok, State2}.
