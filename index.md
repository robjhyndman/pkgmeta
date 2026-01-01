# pkgmeta ![](reference/figures/pkgmeta-hex.png)

This package has just one function: `get_meta` which retrieves metadata
for R packages from CRAN and GitHub. It can optionally return download
data for packages on CRAN.

## Installation

You can install the development version of pkgmeta from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("robjhyndman/pkgmeta")
```

## Example

``` r
library(pkgmeta)
```

Fetch meta data on all packages by a given list of authors on CRAN:

``` r
get_meta(
  cran_authors = c("Hyndman", "O'Hara-Wild"),
  include_downloads = TRUE, start = "2024-01-01"
)
#> # A tibble: 73 × 11
#>    package        date       title    description version authors url   cran_url
#>    <chr>          <date>     <chr>    <chr>       <chr>   <chr>   <chr> <chr>   
#>  1 bayesforecast  2021-06-17 "Bayesi… "Fit Bayes… 1.0.1   "Asael… http… https:/…
#>  2 bfast          2024-10-22 "Breaks… "Decomposi… 1.7.0   "Jan V… http… https:/…
#>  3 binb           2024-07-06 "'binb'… "A collect… 0.0.7   "Dirk … http… https:/…
#>  4 cricketdata    2025-03-25 "Intern… "Data on i… 0.3.0   "Rob H… http… https:/…
#>  5 demography     2023-02-08 "Foreca… "Functions… 2.0     "Rob H… http… https:/…
#>  6 DescTools      2025-03-28 "Tools … "A collect… 0.99.60 "Andri… http… https:/…
#>  7 distributional 2024-09-17 "Vector… "Vectorise… 0.5.0   "Mitch… http… https:/…
#>  8 eechidna       2021-02-25 "Explor… "Data from… 1.4.1   "Jerem… http… https:/…
#>  9 expsmooth      2015-04-09 "Data S… "Data sets… 2.3     "Rob J… http… https:/…
#> 10 fable          2024-11-05 "Foreca… "Provides … 0.4.1   "Mitch… http… https:/…
#> # ℹ 63 more rows
#> # ℹ 3 more variables: github_url <chr>, first_download <date>, downloads <dbl>
```

Fetch meta data on a list of packages on CRAN:

``` r
get_meta(
  cran_packages = c("vital", "nullabor"),
  include_downloads = TRUE, start = "2024-01-01"
)
#> # A tibble: 2 × 11
#>   package date       title description version authors url   cran_url github_url
#>   <chr>   <date>     <chr> <chr>       <chr>   <chr>   <chr> <chr>    <chr>     
#> 1 nullab… 2025-02-10 "Too… "Tools for… 0.3.15  "Hadle… http… https:/… https://g…
#> 2 vital   2024-06-21 "Tid… "Analysing… 1.1.0   "Rob H… http… https:/… https://g…
#> # ℹ 2 more variables: first_download <date>, downloads <dbl>
```

Fetch meta data on a list of packages on GitHub:

``` r
get_meta(github_repos = c("robjhyndman/vital", "dicook/nullabor"))
#> # A tibble: 2 × 7
#>   package  date       title                     version authors url   github_url
#>   <chr>    <date>     <chr>                     <chr>   <chr>   <chr> <chr>     
#> 1 vital    2025-03-27 Tidy Analysis Tools for … 1.1.0.… "Rob H… http… https://g…
#> 2 nullabor 2025-02-10 Tools for Graphical Infe… 0.3.15  "Hadle… http… https://g…
```

Combine meta data from CRAN and GitHub:

``` r
get_meta(
  cran_packages = c("vital", "nullabor"),
  github_repos = c("robjhyndman/vital", "dicook/nullabor"),
  include_downloads = TRUE, start = "2024-01-01"
)
#> # A tibble: 2 × 11
#>   package date       title description version authors url   cran_url github_url
#>   <chr>   <date>     <chr> <chr>       <chr>   <chr>   <chr> <chr>    <chr>     
#> 1 vital   2024-06-21 "Tid… "Analysing… 1.1.0   "Rob H… http… https:/… https://g…
#> 2 nullab… 2025-02-10 "Too… "Tools for… 0.3.15  "Hadle… http… https:/… https://g…
#> # ℹ 2 more variables: first_download <date>, downloads <dbl>
```
