%%%-------------------------------------------------------------------
%%% File    : eb_server.erl
%%% Author  : Mitchell Hashimoto <mitchell.hashimoto@gmail.com>
%%% Modified: Ben LaRoque (yeah I'm just figuring out how this works
%%% Description : The ErlyBank account server.
%%%
%%% Created :  5 Sep 2008 by Mitchell Hashimoto <not gunna put someone else's email>
%%%-------------------------------------------------------------------
-module(eb_server).

-behaviour(gen_server).

%% API
-export([start_link/0,
        create_account/1,
        deposit/2,
        withdrawal/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the server
%%--------------------------------------------------------------------
start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%--------------------------------------------------------------------
%% Function: create_account(Name) -> ok
%% Description: Creates a bank account for the person with name Name
%%--------------------------------------------------------------------
create_account(Name) ->
  gen_server:cast(?SERVER, {create, Name}).

%%--------------------------------------------------------------------
%% Function: deposit(Name, Amount) -> {ok, Balance} | {error, Reason}
%% Description: Deposits Amount into Name's account. Returns the
%% balance if successful, otherwise returns and error and reason.
%%--------------------------------------------------------------------
deposit(Name, Amount) ->
  gen_server:call(?SERVER, {deposit, Name, Amount}).

%%--------------------------------------------------------------------
%% Function: withdrawal(Name, Amount) -> {ok, Balance} | {error, Reason}
%% Description: Withdrawal Amount from Name's account. Returns the
%% balance if successful, otherwise returns and error and reason.
%%--------------------------------------------------------------------
withdrawal(Name, Amount) ->
  gen_server:call(?SERVER, {withdrawal, Name, Amount}).

%%====================================================================
%% gen_server callbacks
%%====================================================================

%%--------------------------------------------------------------------
%% Function: init(Args) -> {ok, State} |
%%                         {ok, State, Timeout} |
%%                         ignore               |
%%                         {stop, Reason}
%% Description: Initiates the server
%%--------------------------------------------------------------------
init(_Args) ->
  {ok, dict:new()}.

%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------
handle_call({deposit, Name, Amount}, _From, State) ->
  case dict:find(Name, State) of
    {ok, Value} ->
      NewBalance = Value + Amount,
      Response = {ok, NewBalance},
      NewState = dict:store(Name, NewBalance, State),
      {reply, Response, NewState};
    error ->
      {reply, {error, account_does_not_exist}, State}
  end;
handle_call({withdrawal, Name, Amount}, _From, State) ->
  case dict:find(Name, State) of
    {ok, Value} when Value >= Amount ->
      NewBalance = Value - Amount,
      Response = {ok, NewBalance},
      NewState = dict:store(Name, NewBalance, State),
      {reply, Response, NewState};
    {ok, Value} when Value < Amount ->
      {reply, {error, insufficient_funds}, State};
    error ->
      {reply, {error, account_does_not_exist}, State}
  end;
handle_call(_Request, _From, State) ->
  Reply = ok,
  {reply, Reply, State}.

%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% Description: Handling cast messages
%%--------------------------------------------------------------------
handle_cast({create, Name}, State) ->
  {noreply, dict:store(Name, 0, State)};
handle_cast(_Msg, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
  ok.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------
