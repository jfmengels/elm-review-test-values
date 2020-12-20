# elm-review-test-values

Provides [`elm-review`](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/) rules to REPLACEME.


## Provided rules

- [`NoUsingTestValuesInSource`](https://package.elm-lang.org/packages/jfmengels/elm-review-test-values/1.0.0/NoUsingTestValuesInSource) - Reports REPLACEME.


## Configuration

```elm
module ReviewConfig exposing (config)

import NoUsingTestValuesInSource
import Review.Rule exposing (Rule)

config : List Rule
config =
    [ NoUsingTestValuesInSource.rule (NoUsingTestValuesInSource.startsWith "tests_")
    ]
```


## Try it out

You can try the example configuration above out by running the following command:

```bash
elm-review --template jfmengels/elm-review-test-values/example
```
