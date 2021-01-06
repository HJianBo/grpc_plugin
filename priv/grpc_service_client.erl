%%%-------------------------------------------------------------------
%% @doc Client module for grpc service {{unmodified_service_name}}.
%% @end
%%%-------------------------------------------------------------------

%% this module was generated and should not be modified manually

-module({{module_name}}_client).

-compile(export_all).
-compile(nowarn_export_all).

-include_lib("grpc/include/grpc.hrl").

-define(SERVICE, '{{unmodified_service_name}}').
-define(PROTO_MODULE, '{{pb_module}}').
-define(MARSHAL(T), fun(I) -> ?PROTO_MODULE:encode_msg(I, T) end).
-define(UNMARSHAL(T), fun(I) -> ?PROTO_MODULE:decode_msg(I, T) end).
-define(DEF(Path, Req, Resp, MessageType),
        #{path => Path,
          service =>?SERVICE,
          message_type => MessageType,
          marshal => ?MARSHAL(Req),
          unmarshal => ?UNMARSHAL(Resp)}).

{{#methods}}
{{^input_stream}}{{^output_stream}}
-spec {{method}}({{pb_module}}:{{input}}())
    -> {ok, {{pb_module}}:{{output}}(), grpc:metadata()}
     | {error, term()}.
{{method}}(Req) ->
    {{method}}(Req, #{}, #{}).

-spec {{method}}({{pb_module}}:{{input}}(), grpc:options())
    -> {ok, {{pb_module}}:{{output}}(), grpc:metadata()}
     | {error, term()}.
{{method}}(Req, Options) ->
    {{method}}(Req, #{}, Options).

-spec {{method}}({{pb_module}}:{{input}}(), grpc:metadata(), grpc_client:options())
    -> {ok, {{pb_module}}:{{output}}(), grpc:metadata()}
     | {error, term()}.
{{method}}(Req, Metadata, Options) ->
    grpc_client:unary(?DEF(<<"/{{unmodified_service_name}}/{{unmodified_method}}">>,
                           {{input}}, {{output}}, <<"{{message_type}}">>),
                      Req, Metadata, Options).
{{/output_stream}}{{/input_stream}}
{{^input_stream}}{{#output_stream}}
-spec {{method}}(grpc_client:options())
    -> {ok, grpc_client:grpcstream()}
     | {error, term()}.

{{method}}(Options) ->
    {{method}}(#{}, Options).

-spec {{method}}(grpc:metadata(), grpc_client:options())
    -> {ok, grpc_client:grpcstream()}
     | {error, term()}.

{{method}}(Metadata, Options) ->
    grpc_client:open_stream(?DEF(<<"/{{unmodified_service_name}}/{{unmodified_method}}">>,
                                 {{input}}, {{output}}, <<"{{message_type}}">>),
                            Metadata, Options).
{{/output_stream}}{{/input_stream}}
{{#input_stream}}
-spec {{method}}(grpc_client:options())
    -> {ok, grpc_client:grpcstream()}
     | {error, term()}.

{{method}}(Options) ->
    {{method}}(#{}, Options).

-spec {{method}}(grpc:metadata(), grpc_client:options())
    -> {ok, grpc_client:grpcstream()}
     | {error, term()}.
{{method}}(Metadata, Options) ->
    grpc_client:open_stream(?DEF(<<"/{{unmodified_service_name}}/{{unmodified_method}}">>,
                                 {{input}}, {{output}}, <<"{{message_type}}">>),
                            Metadata, Options).
{{/input_stream}}
{{/methods}}
