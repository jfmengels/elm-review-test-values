module NoUsingTestValuesInSourceTest exposing (all)

import NoUsingTestValuesInSource exposing (rule)
import Review.Test
import Test exposing (Test, describe, test)


all : Test
all =
    describe "NoUsingTestValuesInSource"
        [ endsWithTest
        , startsWithTest
        ]


endsWithTest : Test
endsWithTest =
    describe "endsWith"
        [ test "should report an error when using a function or value that ends with the specified suffix" <|
            \() ->
                """module A exposing (..)
listTESTS_ONLY = []
value = List.map foo listTESTS_ONLY
"""
                    |> Review.Test.run (rule (NoUsingTestValuesInSource.endsWith "TESTS_ONLY"))
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "REPLACEME"
                            , details = [ "REPLACEME" ]
                            , under = "listTESTS_ONLY"
                            }
                            |> Review.Test.atExactly { start = { row = 3, column = 22 }, end = { row = 3, column = 36 } }
                        ]
        , test "should not report an error when using a function or value that does not end with the specified suffix" <|
            \() ->
                """module A exposing (..)
list = []
value = List.map foo list
"""
                    |> Review.Test.run (rule (NoUsingTestValuesInSource.endsWith "TESTS_ONLY"))
                    |> Review.Test.expectNoErrors
        , test "should not report an error when using a test value inside another test value" <|
            \() ->
                """module A exposing (..)
listTESTS_ONLY = []
valueTESTS_ONLY = List.map foo listTESTS_ONLY
"""
                    |> Review.Test.run (rule (NoUsingTestValuesInSource.endsWith "TESTS_ONLY"))
                    |> Review.Test.expectNoErrors
        ]


startsWithTest : Test
startsWithTest =
    describe "startsWith"
        [ test "should report an error when using a function or value that starts with the specified suffix" <|
            \() ->
                """module A exposing (..)
TESTS_ONLYlist = []
value = List.map foo TESTS_ONLYlist
"""
                    |> Review.Test.run (rule (NoUsingTestValuesInSource.startsWith "TESTS_ONLY"))
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "REPLACEME"
                            , details = [ "REPLACEME" ]
                            , under = "TESTS_ONLYlist"
                            }
                            |> Review.Test.atExactly { start = { row = 3, column = 22 }, end = { row = 3, column = 36 } }
                        ]
        , test "should not report an error when using a function or value that does not start with the specified suffix" <|
            \() ->
                """module A exposing (..)
list = []
value = List.map foo list
"""
                    |> Review.Test.run (rule (NoUsingTestValuesInSource.startsWith "TESTS_ONLY"))
                    |> Review.Test.expectNoErrors
        , test "should not report an error when using a test value inside another test value" <|
            \() ->
                """module A exposing (..)
TESTS_ONLYlist = []
TESTS_ONLYvalue = List.map foo TESTS_ONLYlist
"""
                    |> Review.Test.run (rule (NoUsingTestValuesInSource.startsWith "TESTS_ONLY"))
                    |> Review.Test.expectNoErrors
        ]
