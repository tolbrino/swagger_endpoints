-module(swagger_endpoints_prv).

-export([init/1, do/1, format_error/1]).

-define(PROVIDER, swagger_endpoints).
-define(DEPS, [app_discovery]).

%% ===================================================================
%% Public API
%% ===================================================================
-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([
            {name, ?PROVIDER},            % The 'user friendly' name of the task
            {module, ?MODULE},            % The module implementation of the task
            {bare, true},                 % The task can be run by the user, always true
            {deps, ?DEPS},                % The list of dependencies
            {example, "rebar3 swagger_endpoints swagger.yaml"}, 
                                          % How to use the plugin
            {opts, [{swaggerfile, $f, "file", string, "filename of swagger.yaml file"},
                    {outfile, $o, "out", string, "filename for generated code (e.g. endpoints.erl)"}
                   ]},                    % list of options understood by the plugin
            {short_desc, "Generate endpoints code from swagger"},
            {desc, "A rebar plugin to generate code to access swagger defined endpoints"}
    ]),
    {ok, rebar_state:add_provider(State, Provider)}.


-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    {KVs, _} = rebar_state:command_parsed_args(State),
    Source = proplists:get_value(swaggerfile, KVs, get_from_state(src, State, undefined)),
    DefaultDest = 
       case Source of
           undefined -> undefined;
           _ -> filename:basename(Source, [".yaml"]) ++ "_endpoints"
      end,
    Dest =  filename:rootname(
              proplists:get_value(outfile, KVs, get_from_state(dst, State, DefaultDest)), 
              ".erl") ++ ".erl",
    case Source of
        undefined ->
            {error, "Provide swagger file using option --file Filename"};
        Path ->
            try YamlDocs = yamerl_constr:file(Path),
                rebar_api:info("Generating code from ~p writing to ~p\n", [Path, Dest]),
                {ok, State}
            catch
                _:_ ->
                    {error, io_lib:format("Failed to parse ~p", [Path])}
            end
    end.

-spec format_error(any()) ->  iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

get_from_state(Key, State, Default) ->
    KVs = rebar_state:get(State, swagger_endpoints, []),
    proplists:get_value(Key, KVs, Default).