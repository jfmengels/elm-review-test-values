module NoTestValuesInProductionCode exposing
    ( rule
    , Configuration, startsWith, endsWith
    )

{-|

@docs rule
@docs Configuration, startsWith, endsWith

-}

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
import Review.Rule as Rule exposing (Error, Rule)


{-| Reports when functions or values meant to be used only in tests are used in production source code.

    config =
        [ NoTestValuesInProductionCodeTest.rule
            (NoTestValuesInProductionCodeTest.startsWith "test_")

        -- or
        , NoTestValuesInProductionCodeTest.rule
            (NoTestValuesInProductionCodeTest.endsWith "_TESTS_ONLY")
        ]

A recurring question around opaque types, is how do you restrict access to constructors so that you can't misuse a data
type, while also being able to use it in tests in order to do meaningful tests.


## Problematic example

In the following example, we have two user roles in an opaque `Role`. `Admin` is being protected so that the only way to create one is by
having the server return that the user has that role.

    -- module Role exposing (Role, requestRole)


    import Http
    import Json.Decode as Decode exposing (Decoder)

    type Role
        = User
        | Admin

    requestRole : (Role -> msg) -> String -> Cmd msg
    requestRole onResponse id =
        Http.get
            { url = "https://server.com/user/" ++ id
            , expect = Http.expectJson onResponse roleDecoder
            }

    roleDecoder : Decoder Role
    roleDecoder =
        Decode.field "role" Decode.string
            |> Decode.andThen
                (\role ->
                    case role of
                        "admin" ->
                            Decode.succeed Admin

                        "user" ->
                            Decode.succeed User

                        "admin" ->
                            Decode.fail "Not a valid role"
                )

With this approach, we have a good foundation to build on, in the sense that it won't be possible for someone to have an
`Admin` role without the server's consent (the approach could be improved, but for this example it is sufficient).

The problem is that we know won't be able to write tests that require a role, because it is not possible to construct
such a value in our tests, as we would need to make a HTTP request which `elm-test` doesn't support.

The common solution is therefore to either expose the `Role` (exposing `Role(..)`) or to expose functions to construct
`Role`.

    -- module Role exposing (Role, admin, requestRole, user)
    type Role
        = User
        | Admin

    user =
        User

    admin =
        Admin

Now the problem is that we lost the foundation we had, where a user could be `Admin` only if the server said they were.
Now such a case would only be caught during code review where the reviewer would have to make sure the role is never
abused.


## Proposed solution

The solution I would go for in the previous example would be to expose functions to construct `Role`, but tag them in a
way that we should only use them in test code. And using this `elm-review` rule, we'd get a guarantee that this is the
case.

Those functions are tagged as test-only by their name. You can choose to either have them prefixed or suffixed by a
set string of your choosing.


## Fail

    -- NoTestValuesInProductionCodeTest.startsWith "test_"
    grantAdminRights user =
        { user | role = Role.test_admin }

    -- NoTestValuesInProductionCodeTest.endsWith "_TESTS_ONLY"
    grantAdminRights user =
        { user | role = Role.admin_TESTS_ONLY }


## Success

    -- module RoleTest exposing (roleTest)
    roleTest =
        Test.describe "Role"
            [ Test.test "admins should be able to delete database " <|
                \() -> Expect.true (canDeleteDatabase Role.test_admin)
            , Test.test "users should not be able to delete database " <|
                \() -> Expect.false (canDeleteDatabase Role.test_user)
            ]

Values marked as test-only can be used in the declaration of other test values.

    -- module User exposing (test_admin_user)
    test_admin_user =
        { id = "001"
        , role = Role.test_admin
        }


## Critique

Is this a perfect solution? No. Tagging values is a brittle solution, and it's easy to misname a function (`testadmin`
instead of `test_admin` for instance) and lose the guarantees this rule was given you.

It's not perfect, but I think this brittleness will not be a problem in practice, because even if the rule doesn't
enforce anything, having something called `testXyz` will likely be good enough to prevent misuse in practice (otherwise
I don't understand why there so many frameworks would prone "convention over configuration" in other ecosystems).


## When (not) to enable this rule

This rule is useful only if you have instances where you wish to add guarantees to the usage of your data types, but
need to access internals in the context of your tests.
Also, for this rule to work well, the naming convention for test-only values needs to be communicated to the rest of the
team or project.


## Try it out

You can try this rule out by running the following command:

```bash
elm-review --template jfmengels/elm-review-test-values/example --rules NoTestValuesInProductionCodeTest
```

The example this rule uses are the two configurations linked to at the top of the page.

-}
rule : Configuration -> Rule
rule configuration =
    let
        isTestValue : String -> Bool
        isTestValue =
            buildTestValuePredicate configuration
    in
    Rule.newModuleRuleSchemaUsingContextCreator "NoTestValuesInProductionCodeTest" initialContext
        |> Rule.withDeclarationEnterVisitor (declarationVisitor isTestValue)
        |> Rule.withExpressionEnterVisitor (expressionVisitor configuration isTestValue)
        |> Rule.fromModuleRuleSchema


{-| Configure how values should be tagged.
-}
type Configuration
    = StartsWith String
    | EndsWith String


{-| A test-only value's name starts with the given string.
-}
startsWith : String -> Configuration
startsWith =
    StartsWith


{-| A test-only value's name ends with the given string.
-}
endsWith : String -> Configuration
endsWith =
    EndsWith


type alias Context =
    { inDeclarationOfNonTestValue : Bool
    , isInSourceDirectories : Bool
    }


initialContext : Rule.ContextCreator () Context
initialContext =
    Rule.initContextCreator
        (\metadata () ->
            { inDeclarationOfNonTestValue = False
            , isInSourceDirectories = Rule.isInSourceDirectories metadata
            }
        )
        |> Rule.withMetadata



-- CONFIGURATION


buildTestValuePredicate : Configuration -> String -> Bool
buildTestValuePredicate configuration =
    case configuration of
        StartsWith string ->
            String.startsWith string

        EndsWith string ->
            String.endsWith string



-- VISITORS


declarationVisitor : (String -> Bool) -> Node Declaration -> Context -> ( List (Error {}), Context )
declarationVisitor isTestValue node context =
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
            ( [], { context | inDeclarationOfNonTestValue = not (isTestValue functionName) } )

        _ ->
            ( [], { context | inDeclarationOfNonTestValue = False } )


expressionVisitor : Configuration -> (String -> Bool) -> Node Expression -> Context -> ( List (Error {}), Context )
expressionVisitor configuration isTestValue node context =
    if context.inDeclarationOfNonTestValue && context.isInSourceDirectories then
        case Node.value node of
            Expression.FunctionOrValue _ name ->
                if isTestValue name then
                    ( [ error configuration name (Node.range node) ]
                    , context
                    )

                else
                    ( [], context )

            _ ->
                ( [], context )

    else
        ( [], context )


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
