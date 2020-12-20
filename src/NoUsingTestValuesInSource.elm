module NoUsingTestValuesInSource exposing
    ( rule
    , Configuration, endsWith, startsWith
    )

{-|

@docs rule

-}

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
import Review.Rule as Rule exposing (Error, Rule)


{-| Reports when functions or values meant to be used only in tests are used in production source code.

A recurring question around opaque types

    config =
        [ NoUsingTestValuesInSource.rule (NoUsingTestValuesInSource.endsWith "_TESTS_ONLY")

        -- or
        , NoUsingTestValuesInSource.rule (NoUsingTestValuesInSource.startsWith "test_")
        ]


## Fail

    a =
        "REPLACEME example to replace"


## Success

    a =
        "REPLACEME example to replace"


## When (not) to enable this rule

This rule is useful when REPLACEME.
This rule is not useful when REPLACEME.


## Try it out

You can try this rule out by running the following command:

```bash
elm-review --template jfmengels/elm-review-test-values/example --rules NoUsingTestValuesInSource
```

-}
rule : Configuration -> Rule
rule configuration =
    let
        isTestValue : String -> Bool
        isTestValue =
            buildTestValuePredicate configuration
    in
    Rule.newModuleRuleSchema "NoUsingTestValuesInSource" False
        |> Rule.withDeclarationEnterVisitor (declarationVisitor isTestValue)
        |> Rule.withExpressionEnterVisitor (expressionVisitor configuration isTestValue)
        |> Rule.fromModuleRuleSchema


type Configuration
    = EndsWith String
    | StartsWith String


endsWith : String -> Configuration
endsWith =
    EndsWith


startsWith : String -> Configuration
startsWith =
    StartsWith


type alias Context =
    Bool



-- CONFIGURATION


buildTestValuePredicate : Configuration -> String -> Bool
buildTestValuePredicate configuration =
    case configuration of
        EndsWith string ->
            String.endsWith string

        StartsWith string ->
            String.startsWith string



-- VISITORS


declarationVisitor : (String -> Bool) -> Node Declaration -> Context -> ( List (Error {}), Context )
declarationVisitor isTestValue node _ =
    case Node.value node of
        Declaration.FunctionDeclaration function ->
            let
                functionName : String
                functionName =
                    function.declaration
                        |> Node.value
                        |> .name
                        |> Node.value
            in
            ( [], not (isTestValue functionName) )

        _ ->
            ( [], False )


expressionVisitor : Configuration -> (String -> Bool) -> Node Expression -> Context -> ( List (Error {}), Context )
expressionVisitor configuration isTestValue node inDeclarationOfNonTestValue =
    if inDeclarationOfNonTestValue then
        case Node.value node of
            Expression.FunctionOrValue _ name ->
                if isTestValue name then
                    ( [ error configuration name (Node.range node) ]
                    , inDeclarationOfNonTestValue
                    )

                else
                    ( [], inDeclarationOfNonTestValue )

            _ ->
                ( [], inDeclarationOfNonTestValue )

    else
        ( [], inDeclarationOfNonTestValue )


error : Configuration -> String -> Range -> Error {}
error configuration name range =
    let
        ( configWord, matchText ) =
            case configuration of
                StartsWith str ->
                    ( "start", str )

                EndsWith str ->
                    ( "end", str )
    in
    Rule.error
        { message = "Forbidden use of test-only value `" ++ name ++ "` in production source code"
        , details =
            [ "This value was marked as being meant to only be used in test-related code, but I found it being used in code that will go to production."
            , "You should either stop using it or rename the it to not " ++ configWord ++ " with `" ++ matchText ++ "`."
            ]
        }
        range
