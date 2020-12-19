module NoUsingTestValuesInSource exposing (rule)

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
rule : Rule
rule =
    Rule.newModuleRuleSchema "NoUsingTestValuesInSource" False
        |> Rule.withDeclarationEnterVisitor declarationVisitor
        |> Rule.withExpressionEnterVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


type alias Context =
    Bool


declarationVisitor : Node Declaration -> Context -> ( List (Error {}), Context )
declarationVisitor node _ =
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
            ( [], not (String.endsWith "_TESTS_ONLY" functionName) )

        _ ->
            ( [], False )


expressionVisitor : Node Expression -> Context -> ( List (Error {}), Context )
expressionVisitor node inDeclarationOfNonTestValue =
    if inDeclarationOfNonTestValue then
        case Node.value node of
            Expression.FunctionOrValue _ name ->
                if String.endsWith "_TESTS_ONLY" name then
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
