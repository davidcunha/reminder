-module(event).
-compile(export_all).
-record(state, {server,
                name="",
                to_go=0}).

start(EventName, DateTime) ->
    spawn(?MODULE, init, [self(), EventName, DateTime]).

init(Server, EventName, DateTime) ->
    loop(#state{server=Server,
                name=EventName,
                to_go=time_to_go(DateTime)}).

loop(S = #state{server=Server}) ->
    receive
        {Server, Ref, cancel} ->
          Server ! {Ref, ok}
    after S#state.to_go*1000 ->
        Server ! {done, S#state.name}
    end.

cancel(Pid) ->
    %% Monitor in case the process is already dead.
    Ref = erlang:monitor(process, Pid),
    Pid ! {self(), Ref, cancel},
    receive
        {Ref, ok} ->
            erlang:demonitor(Ref, [flush]),
            ok;
        {'DOWN', Ref, process, Pid, _Reason} ->
            ok
    end.

time_to_go(TimeOut={{_,_,_}, {_,_,_}}) ->
    Now = calendar:local_time(),
    ToGo = calendar:datetime_to_gregorian_seconds(TimeOut) -
           calendar:datetime_to_gregorian_seconds(Now),
    Secs = if ToGo > 0  -> ToGo;
￼             ToGo =< 0 -> 0
    end,
    normalize(Secs).
