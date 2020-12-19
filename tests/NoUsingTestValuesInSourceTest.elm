module NoUsingTestValuesInSourceTest exposing (all)

import NoUsingTestValuesInSource exposing (rule)
import Review.Test
import Test exposing (Test, describe, test)


all : Test
all =
    describe "NoUsingTestValuesInSource"
        [ test "should report an error when using a function or value that ends with the specified suffix" <|
            \() ->
                """module A exposing (..)
list_TESTS_ONLY = []
value = List.map foo list_TESTS_ONLY
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "REPLACEME"
                            , details = [ "REPLACEME" ]
                            , under = "list_TESTS_ONLY"
                            }
                            |> Review.Test.atExactly { start = { row = 3, column = 22 }, end = { row = 3, column = 37 } }
                        ]
        , test "should not report an error when using a function or value that does not end with the specified suffix" <|
            \() ->
                """module A exposing (..)
list = []
value = List.map foo list
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "should not report an error when using a test value inside another test value" <|
            \() ->
                """module A exposing (..)
list_TESTS_ONLY = []
value_TESTS_ONLY = List.map foo list_TESTS_ONLY
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        ]
