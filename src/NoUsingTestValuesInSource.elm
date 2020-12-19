module NoUsingTestValuesInSource exposing
    ( rule
    , Configuration, endsWith
    )

{-|

@docs rule

-}

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Node as Node exposing (Node)
import Review.Rule as Rule exposing (Error, Rule)


{-| Reports... REPLACEME

    config =
        [ NoUsingTestValuesInSource.rule
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
        |> Rule.withExpressionEnterVisitor (expressionVisitor isTestValue)
        |> Rule.fromModuleRuleSchema


type Configuration
    = EndsWith String


endsWith : String -> Configuration
endsWith =
    EndsWith


type alias Context =
    Bool



-- CONFIGURATION


buildTestValuePredicate : Configuration -> String -> Bool
buildTestValuePredicate configuration =
    case configuration of
        EndsWith string ->
            String.endsWith string



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


expressionVisitor : (String -> Bool) -> Node Expression -> Context -> ( List (Error {}), Context )
expressionVisitor isTestValue node inDeclarationOfNonTestValue =
    if inDeclarationOfNonTestValue then
        case Node.value node of
            Expression.FunctionOrValue _ name ->
                if isTestValue name then
                    ( [ Rule.error
                            { message = "REPLACEME"
                            , details = [ "REPLACEME" ]
                            }
                            (Node.range node)
                      ]
                    , inDeclarationOfNonTestValue
                    )

                else
                    ( [], inDeclarationOfNonTestValue )

            _ ->
                ( [], inDeclarationOfNonTestValue )

    else
        ( [], inDeclarationOfNonTestValue )
