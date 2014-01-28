-module(etsExample).

-include_lib("stdlib/include/ms_transform.hrl").

-export([ex1/0, ex2/0, ex3/0, ex4/0, ex5/0, etsTest/1, detsTest/1, listTest/2, makeTests/2]).

-record(food, {name, calories, price, group}).

ex1() ->
	ets:new(table, [ordered_set, named_table]),
	ets:insert(table, {ex2, 1, 3, 2}),
	ets:insert(table, {ex1, 1, 3, 2}),
	X1 = ets:lookup(table, ex1),
	X2 = ets:first(table),
	X3 = ets:next(table, ets:last(table)),
	io:fwrite("~w~n~w~n~w~n", [X1, X2, X3]),
	ets:delete(table),
	ok.

ex2() ->
	ets:new(table, [bag, named_table]),
	ets:insert(table, [	{items, a, b, c, d},
						{items, a, b, c, a},
						{cat, brown, soft, loveable, selfish},
						{friends, [jenn,jeff,etc]},
						{items, 1, 2, 3, 1}]),
	X1 = ets:match(table, {items, '$1', '$2', '_', '$1'}),
	X2 = ets:match(table, {items, '$114', '$212', '_', '$6'}),
	X3 = ets:match_object(table, {items, '$1', '$2', '_', '$1'}),
	io:fwrite("~w~n~w~n~w~n", [X1, X2, X3]),
	ets:delete(table),
	ok.

ex3() ->
	io:fwrite("~w~n", [ets:fun2ms(fun({Food, Type, <<1>>, Price, Calories}) when Calories > 150 andalso Calories < 500, Type == meat orelse Type == dairy; Price < 4.00, is_float(Price) -> Food end)]),
	ok.

ex4() ->
	ets:new(food, [ordered_set, {keypos,#food.name}, named_table]),
	ets:insert(food, [	#food{name=salmon, calories=88, price=4.00, group=meat},
						#food{name=cereals, calories=178, price=2.79, group=bread},
						#food{name=milk, calories=150, price=3.23, group=dairy},
						#food{name=cake, calories=650, price=7.21, group=delicious},
						#food{name=bacon, calories=800, price=6.32, group=meat},
						#food{name=sandwich, calories=550, price=5.78, group=whatever}]),
	io:fwrite("~w~n", [ets:select_reverse(food, ets:fun2ms(fun(N = #food{calories=C}) when C < 600 -> N end))]),
	ets:delete(food),
	ok.

ex5() ->
	ets:new(food, [bag, {keypos,#food.name}, named_table]),
	ets:insert(food, [	#food{name=salmon, calories=88, price=4.00, group=meat},
						#food{name=cereals, calories=178, price=2.79, group=bread},
						#food{name=milk, calories=150, price=3.23, group=dairy},
						#food{name=cake, calories=650, price=7.21, group=delicious},
						#food{name=bacon, calories=800, price=6.32, group=meat},
						#food{name=sandwich, calories=550, price=5.78, group=whatever}]),
	dets:open_file(menu, [{type, set}]),
	dets:from_ets(menu, food),
	io:fwrite("~w~n", [dets:select(menu, ets:fun2ms(fun(N = #food{calories=C}) when C < 600 -> N end))]),
	dets:close(menu),
	ets:delete(food),
	ok.


makeTests(N, Number) ->
	MilisPerS = 1000000,
	Data = generateData(N),
	
	{TimeList, _} = timer:tc(?MODULE, listTest, [Data, Number]),
	io:fwrite("Wyszukiwanie przy uzyciu list: ~ws~n", [TimeList/MilisPerS]),
	
	ets:new(table, [duplicate_bag, named_table, {keypos, 1}]),
	ets:insert(table, Data),
	{TimeEts, _} = timer:tc(?MODULE, etsTest, [Number]),
	ets:delete(table),
	io:fwrite("Wyszukiwanie przy uzyciu ets: ~ws~n", [TimeEts/MilisPerS]),
	
	dets:open_file(table2, [{type, duplicate_bag}]),
	dets:insert(table2, Data),
	{TimeDets, _} = timer:tc(?MODULE, detsTest, [Number]),
	dets:delete_all_objects(table2),
	io:fwrite("Wyszukiwanie przy uzyciu dets: ~ws~n", [TimeDets/MilisPerS]).


detsTest(0) ->
	ok;
detsTest(N) ->
	dets:lookup(table2, random:uniform(1000000)),
	detsTest(N - 1).

etsTest(0) ->
	ok;
etsTest(N) ->
	ets:lookup(table, random:uniform(1000000)),
	etsTest(N - 1).

listTest(_, 0) ->
	ok;
listTest(Data, N) ->
	select(Data, [], random:uniform(1000000)),
	listTest(Data, N - 1).

select([], Acc, _) ->
	Acc;
select([H = {X} | T], Acc, X) ->
	select(T, [H | Acc], X);
select([_ | T], Acc, X) ->
	select(T, Acc, X).

generateData(N) ->
	random:seed(now()),
	generateData(N, []).

generateData(0, Acc) ->
	Acc;
generateData(N, Acc) ->
	generateData(N - 1, [{random:uniform(1000000)} | Acc]).


	