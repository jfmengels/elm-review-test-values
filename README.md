# elm-review-test-values

Provides [`elm-review`](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/) rules to find misuses of test-only values.


## Provided rules

- [`NoTestValuesInProductionCode`](https://package.elm-lang.org/packages/jfmengels/elm-review-test-values/1.0.0/NoTestValuesInProductionCode) - Reports when functions or values meant to be used only in tests are used in production source code.


## Configuration

```elm
module ReviewConfig exposing (config)

import NoTestValuesInProductionCode
import Review.Rule exposing (Rule)

config : List Rule
config =
    [ NoTestValuesInProductionCode.rule
        (NoTestValuesInProductionCode.startsWith "test_")
    ]
```


## Try it out

You can try the example configuration above out by running the following command:

```bash
elm-review --template jfmengels/elm-review-test-values/example
```
