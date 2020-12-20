# elm-review-test-values

Provides [`elm-review`](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/) rules to REPLACEME.


## Provided rules

- [`NoTestValuesInProductionCode`](https://package.elm-lang.org/packages/jfmengels/elm-review-test-values/1.0.0/NoTestValuesInProductionCode) - Reports REPLACEME.


## Configuration

```elm
module ReviewConfig exposing (config)

import NoTestValuesInProductionCode
import Review.Rule exposing (Rule)

config : List Rule
config =
    [ NoTestValuesInProductionCode.rule (NoTestValuesInProductionCode.startsWith "tests_")
    ]
```


## Try it out

You can try the example configuration above out by running the following command:

```bash
elm-review --template jfmengels/elm-review-test-values/example
```
