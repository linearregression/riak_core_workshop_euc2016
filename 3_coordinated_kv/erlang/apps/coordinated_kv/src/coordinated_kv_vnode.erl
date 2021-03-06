-module(coordinated_kv_vnode).
-behaviour(riak_core_vnode).

-export([start_vnode/1,
         init/1,
         terminate/2,
         handle_command/3,
         is_empty/1,
         delete/1,
         handle_handoff_command/3,
         handoff_starting/2,
         handoff_cancelled/1,
         handoff_finished/2,
         handle_handoff_data/2,
         encode_handoff_item/2,
         handle_coverage/4,
         handle_exit/3]).

-ignore_xref([
             start_vnode/1
             ]).

-record(state, {partition, db}).

%% API
start_vnode(I) ->
    riak_core_vnode_master:get_vnode_pid(I, ?MODULE).

init([Partition]) ->
    EtsHandle = ets:new(nil, []),
    {ok, #state { partition=Partition, db=EtsHandle }}.

handle_command({ReqID, ping}, _Sender, State) ->
    {reply, {ReqID, {pong, State#state.partition}}, State};

%% Store some data
handle_command({ReqID, {store, Key, Data}}, _Sender, State) ->
    Res = ets:insert(State#state.db, {Key, Data}),
    {reply, {ReqID, {Res}}, State};

%% Fetch some data
handle_command({ReqID, {fetch, Key}}, _Sender, State) ->
    case ets:lookup(State#state.db, Key) of
      [] -> {reply, {ReqID, {not_found}}, State};
      [{Key, Data}] -> {reply, {ReqID, {Key, Data}}, State}
    end.

handle_handoff_command(_Message, _Sender, State) ->
    {noreply, State}.

handoff_starting(_TargetNode, State) ->
    {true, State}.

handoff_cancelled(State) ->
    {ok, State}.

handoff_finished(_TargetNode, State) ->
    {ok, State}.

handle_handoff_data(_Data, State) ->
    {reply, ok, State}.

encode_handoff_item(_ObjectName, _ObjectValue) ->
    <<>>.

is_empty(State) ->
    {true, State}.

delete(State) ->
    {ok, State}.

handle_coverage(_Req, _KeySpaces, _Sender, State) ->
    {stop, not_implemented, State}.

handle_exit(_Pid, _Reason, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.
