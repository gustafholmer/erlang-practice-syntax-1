%%%-------------------------------------------------------------------
%%% gustafholmer guho0000
%%%-------------------------------------------------------------------
-module(task1).
-export([eval/1, eval/2, map/2, filter/2]).

%%%-------------------------------------------------------------------
%%% eval/1
%%%-------------------------------------------------------------------
eval_real([add, E1, E2]) -> {ok, E1 + E2};
eval_real([sub, E1, E2]) -> {ok, E1 - E2};
eval_real(['div', E1, E2]) -> {ok, E1 / E2};
eval_real([mul, E1, E2]) -> {ok, E1 * E2}.

% checks if E1 is a tuple, if tuple -> evaluate it
eval({Op, E1, E2}) when is_tuple(E1) -> eval({Op, eval(E1), E2});
eval({Op, {ok, Val}, E2}) -> eval({Op, Val, E2});

% checks if E2 is a tuple, if tuple -> evaluate it
eval({Op, E1, E2}) when is_tuple(E2) -> eval({Op, E1, eval(E2)});
eval({Op, E1, {ok, Val}}) -> eval({Op, E1, Val});

% checks if both E1 and E2 are tuples, if tuples -> evaluate them
eval({Op, E1, E2}) when is_tuple(E1), is_tuple(E2) -> eval({Op, eval(E1), eval(E2)});
eval({Op, {ok, Val}, {ok, Val1}}) -> eval({Op, Val, Val1});

% checks if list which makes input eligible for evaluation
eval({Op,E1,E2}) -> eval(tuple_to_list({Op,E1,E2}));

% return last evaluation
eval({ok, Val}) -> Val;

% evaluates the transformed tuple, return error if something is wrong
eval([Op,E1,E2]) -> try eval_real([Op,E1,E2])
                    catch
                      _:_ -> error
                    end.

%%%-------------------------------------------------------------------
%%% eval/2
%%%-------------------------------------------------------------------

% This part uses eval/1 to calculate the tuple which have been unpacked before by 
% checking if there are any variables which have been unpacked => empty list.
eval({Op, E1, E2}, M1) when M1 =:= #{} -> try eval_real(tuple_to_list({Op, E1, E2})) % eval({Op, E1, E2});
                                  catch _:_ -> {error, unknown_error}
                                          end;
eval({Op, E1, E2}, M1) -> compare_elements_with_keys(Op, E1, E2, maps:keys(M1), M1).

% checks the results of tuples.
take_elements(Op, {ok, Val}, {ok, Val1}, M1) -> eval({Op, Val, Val1}, M1);
take_elements(Op, {ok, Val}, E2, M1) -> eval({Op, Val, E2}, M1);
take_elements(Op, E1, {ok, Val}, M1) -> eval({Op, E1, Val}, M1);
take_elements(_, _, {error, unknown_error}, _) -> {error, unknown_error};
take_elements(_, {error, unknown_error}, _, _) -> {error, unknown_error};
take_elements(_, _, {error, variable_not_found}, _) -> {error, variable_not_found};
take_elements(_, {error, variable_not_found}, _, _) -> {error, variable_not_found}.

% following function is for unpacking the tuples and checking for variables
compare_elements_with_keys(Op, E1, E2, [_H|_T], M1) when is_tuple(E1), is_tuple(E2) -> 
take_elements(Op, eval(E1, M1), eval(E2, M1), M1);
compare_elements_with_keys(Op, E1, E2, [_H|_T], M1) when is_tuple(E1) -> 
take_elements(Op, eval(E1, M1), E2, M1);
compare_elements_with_keys(Op, E1, E2, [_H|_T], M1) when is_tuple(E2) -> 
take_elements(Op, E1, eval(E2, M1), M1);

compare_elements_with_keys(Op, E1, E2, [H|_T], M1) when E1 =:= H, E2 =:= H ->
  case element_buffer(H,  maps:keys(M1)) of
    true -> eval({Op, maps:get(H, M1), maps:get(H, M1)}, maps:remove(H, M1));
    false -> {error, variable_not_found}
    end;

compare_elements_with_keys(Op, E1, E2, [H|_T], M1) when E1 =:= H ->
  case element_buffer(H,  maps:keys(M1)) of
    true -> eval({Op, maps:get(H, M1), E2}, maps:remove(H, M1));
    false -> {error, variable_not_found}
  end;

compare_elements_with_keys(Op, E1, E2, [H|_T], M1) when E2 =:= H ->
  case element_buffer(H,  maps:keys(M1)) of
    true -> eval({Op, E1, maps:get(H, M1)}, maps:remove(H, M1));
    false -> {error, variable_not_found}
  end;

compare_elements_with_keys(Op, E1, E2, [_H|T], M1) when not is_integer(E1); not is_integer(E2);
  not is_float(E1); not is_float(E2) -> compare_elements_with_keys(Op, E1, E2, T, M1);

compare_elements_with_keys(_Op, E1, E2, [], _M1) when is_atom(E1); is_atom(E2) ->
  {error, variable_not_found};

compare_elements_with_keys(_Op, E1, E2, [_], _M1) when is_atom(E1); is_atom(E2) ->
  {error, variable_not_found};

compare_elements_with_keys(Op, E1, E2, [], _) when is_integer(E1), is_integer(E2);
  is_float(E1), is_float(E2); is_integer(E1), is_float(E2); is_float(E1), is_integer(E2) -> 
  eval({Op, E1, E2}, #{}).

% holds variables and checks them
element_buffer(_, []) -> false;
element_buffer(Original_list_input_element, [H|_]) when Original_list_input_element =:= H -> true;
element_buffer(Original_list_input_element, [_|T]) -> element_buffer(Original_list_input_element, T).


%%%-------------------------------------------------------------------
%%% map(F, L)
%%%-------------------------------------------------------------------

map(F, L) -> map1(F, L, []).

map1(_F, [], AccList) -> lists:reverse(AccList);
map1(F, [H|T], AccList) -> map1(F, T, [F(H)|AccList]).


%%%-------------------------------------------------------------------
%%% filter(P, L)
%%%-------------------------------------------------------------------

filter(P, L) -> filter1(P, L, []).

filter1(_P, [], AccList) -> lists:reverse(AccList);
filter1(P, [H|T], AccList) -> case P(H) of
                                true -> filter1(P, T, [H|AccList]);
                                false -> filter1(P, T, AccList)
                              end.


