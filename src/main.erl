-module(main).
-export([connect/2, main_loop/1]).

connect(Address, Port) ->
	%hardcoded for now, change later
	UserName = "BeardBot",
	UserMode = 0,%no modes
	UserDescription = "I am an erlang bot",
	{ok, Socket} = gen_tcp:connect(Address, Port, [{packet, line}]),
	gen_tcp:send(Socket, "NICK " ++ UserName ++ "\r\n"),
	%is of the form: USER username usermode * :Description
	UserInfo = "USER " ++ UserName ++ " " ++ integer_to_list(UserMode) ++ " * :" ++ UserDescription ++ "\r\n",
	gen_tcp:send(Socket, UserInfo),
	main_loop(Socket).

handle_message(Socket, [Name, "PRIVMSG", Channel], Message) ->
	%io:format("<<<PRIVMSG HANDLER>>>~n", []),
	Nick = hd(string:tokens(Name, "!")),
	io:format(Channel ++ " | <" ++ Nick ++ "> " ++ Message ++ "~n", []);

handle_message(Socket, ["PING"], Rest) ->
	gen_tcp:send(Socket, "PONG " ++ Rest ++ "\r\n");

handle_message(Socket, _, _) ->
	ignored.%io:format("?~n", []).

main_loop(Socket) ->
	receive
		{tcp, Socket, Data} ->
			io:format("Received:~n~s~n~n", [Data]),
			ByColon = string:tokens(Data, ":"),
			%io:format("length(ByColon) = ~p~n", [length(ByColon)]),
			BySpace = string:tokens(hd(ByColon), " "),
			%io:format("length(BySpace) = ~p~n", [length(BySpace)]),
			LaterArgs = if 
				length(ByColon) > 1 ->
					lists:nth(2, ByColon);
				true ->
					[]
			end,
			handle_message(Socket, BySpace, LaterArgs),
			main_loop(Socket);
		{error, timeout} ->
			io:format("TIMEOUT received~n"),
			gen_tcp:close(Socket);
		{error, OtherReason} ->
			io:format("ERROR occured: ~s", [OtherReason]),
			gen_tcp:close(Socket);
		{join, Channel} ->
			gen_tcp:send(Socket, "JOIN :" ++ Channel ++ "\r\n"),
			main_loop(Socket);
		{say, Channel, Message} ->
			io:format("privmsg received~n", []),
			gen_tcp:send(Socket, "PRIVMSG " ++ Channel ++ " :" ++ Message ++ "\r\n"),
			main_loop(Socket);
		quit ->
			gen_tcp:send("QUIT :Client closed"),
			gen_tcp:close(Socket),
			io:format("QUIT received~n", []),
			exit(stopped)
	end.