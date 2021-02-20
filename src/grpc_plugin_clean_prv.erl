-module(grpc_plugin_clean_prv).

-export([init/1, do/1, format_error/1]).

-include_lib("providers/include/providers.hrl").

-define(PROVIDER, clean).
-define(NAMESPACE, grpc).
-define(DEPS, [{default, app_discovery}]).

%%--------------------------------------------------------------------
%% Public API
%%--------------------------------------------------------------------

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create(
                 [{name, ?PROVIDER},
                  {namespace, ?NAMESPACE},
                  {module, ?MODULE},
                  {bare, true},
                  {deps, ?DEPS},
                  {example, "rebar3 grpc clean"},
                  {short_desc, "Clean all generated .erl files"},
                  {desc, "Clean all generated .erl files"}]),
    {ok, rebar_state:add_provider(State, Provider)}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    Apps = rebar_state:project_apps(State),
    {Options, _} = rebar_state:command_parsed_args(State),
    lists:foreach(fun(AppInfo) ->
        clean_app_pb_and_services(AppInfo, Options, State)
    end, Apps),
    {ok, State}.

-spec format_error(any()) ->  iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

clean_app_pb_and_services(AppInfo, _Options, _State) ->
    Opts = rebar_app_info:opts(AppInfo),
    BeamOutDir = rebar_app_info:ebin_dir(AppInfo),
    GrpcOpts = rebar_opts:get(Opts, grpc, []),
    GpbOpts = proplists:get_value(gpb_opts, GrpcOpts, []),
    BaseDir = rebar_app_info:dir(AppInfo),
    GrpcOptOutDir = proplists:get_value(out_dir, GrpcOpts,
                                        filename:join(BaseDir, "src")),
    GrpcOutDir = filename:join(BaseDir, GrpcOptOutDir),
    GpbOutDir = filename:join(BaseDir, proplists:get_value(o,
                                                           GpbOpts,
                                                           GrpcOptOutDir)),

    ProtosDirs =
        case proplists:get_value(protos, GrpcOpts,
                                 [filename:join("priv", "protos")]
                                ) of
            [H | _] = Ds when is_list(H) ->
                Ds;
            D ->
                [D]
        end,
    ProtoFiles = lists:append(
                   [filelib:wildcard(filename:join([BaseDir, D, "*.proto"]))
                    || D <- ProtosDirs]),
    CompiledPBs = lists:map(fun(Pf) ->
                      beam_filename(Pf, GpbOutDir, BeamOutDir, GpbOpts)
                  end, ProtoFiles),
    %% delete all generated files
    lists:foreach(fun({GeneratedPB, CompledPB}) ->
        case code:load_abs(CompledPB) of
            {module, ModName} ->
                Files = [GeneratedPB |
                         service_output_files(ModName, GrpcOutDir, GrpcOpts)],
                lists:foreach(fun file:delete/1, Files);
            _ ->
                ok
        end
    end, CompiledPBs).

beam_filename(Filename, OutDir, BeamOutDir, GpbOpts) ->
    ModuleName = lists:flatten(
                   [proplists:get_value(module_name_prefix, GpbOpts, ""),
                    filename:basename(Filename, ".proto"),
                    proplists:get_value(module_name_suffix, GpbOpts, "")]),
    {filename:join(OutDir, ModuleName ++ ".erl"),
     filename:join(BeamOutDir, ModuleName)}.

service_output_files(ProtoMod, OutDir, GrpcOpts) ->
    ServicePrefix = proplists:get_value(prefix, GrpcOpts, ""),
    ServiceSuffix = proplists:get_value(suffix, GrpcOpts, ""),
    ServiceModules = proplists:get_value(service_modules, GrpcOpts, []),
    Names = ProtoMod:get_service_names(),
    lists:append(
      lists:map(
        fun(ServiceName) ->
            {{_, Name}, _} = ProtoMod:get_service_def(ServiceName),
            ServiceMod = proplists:get_value(
                           Name,
                           ServiceModules,
                           list_snake_case(atom_to_list(Name))
                          ),
            Prefix =
                filename:join([OutDir,
                               ServicePrefix ++ ServiceMod ++ ServiceSuffix
                              ]),
            [Prefix ++ "_" ++ Suffix ++ ".erl"
             || Suffix <- templates_suffixs()]
        end, Names)).

templates_suffixs() ->
    ["client", "bhvr"].

list_snake_case(NameString) ->
    Snaked = lists:foldl(
               fun(RE, Snaking) ->
                   re:replace(Snaking, RE,
                              "\\1_\\2", [{return, list}, global])
               end,
               NameString,
               [%% uppercase followed by lowercase
                "(.)([A-Z][a-z]+)",
                %% any consecutive digits
                "(.)([0-9]+)",
                %% uppercase with lowercase
                %% or digit before it
                "([a-z0-9])([A-Z])"]),
    Snaked1 = string:replace(Snaked, ".", "_", all),
    Snaked2 = string:replace(Snaked1, "__", "_", all),
    string:to_lower(unicode:characters_to_list(Snaked2)).


