# Return meta data on CRAN and github packages

Find meta data for all packages on CRAN that match a given author and
all packages contained in a vector of github repositories and return as
a tibble. Meta data on packages that are both on CRAN and github will be
combined into a single row. Where meta data clash, the CRAN version is
preferred when `prefer_cran` is `TRUE`, otherwise the github version is
preferred.

## Usage

``` r
get_meta(
  cran_authors = NULL,
  include_downloads = FALSE,
  start = "2000-01-01",
  end = Sys.Date(),
  cran_packages = NULL,
  github_repos = NULL,
  prefer_cran = TRUE
)
```

## Arguments

- cran_authors:

  Character vector to find in CRAN author names

- include_downloads:

  Should total CRAN downloads since `start` be added to the tibble?

- start:

  Start date for download statistics. Ignored if `include_downloads` is
  `FALSE`.

- end:

  End date for download statistics. Ignored if `include_downloads` is
  `FALSE`.

- cran_packages:

  Character vector of CRAN packages. Ignored if `cran_authors` is
  provided.

- github_repos:

  Character vector of github repos

- prefer_cran:

  When a package is both on CRAN and github, which information should be
  preferenced?

## Examples

``` r
get_meta(cran_authors = "Hyndman")
#> # A tibble: 51 × 9
#>    package           date       title description version authors url   cran_url
#>    <chr>             <date>     <chr> <chr>       <chr>   <chr>   <chr> <chr>   
#>  1 bayesforecast     2025-06-05 "Bay… "Fit Bayes… 1.0.5   "Asael… http… https:/…
#>  2 bfast             2025-08-18 "Bre… "Decomposi… 1.7.1   "Jan V… http… https:/…
#>  3 binb              2024-07-06 "'bi… "A collect… 0.0.7   "Dirk … http… https:/…
#>  4 calcal            2025-07-22 "Cal… "An R impl… 1.0.0   "Rob H… http… https:/…
#>  5 conformalForecast 2025-10-06 "Con… "Methods a… 0.1.0   "Xiaoq… http… https:/…
#>  6 cricketdata       2025-03-25 "Int… "Data on i… 0.3.0   "Rob H… http… https:/…
#>  7 demography        2025-10-06 "For… "Functions… 2.0.1   "Rob H… http… https:/…
#>  8 DescTools         2025-03-28 "Too… "A collect… 0.99.60 "Andri… http… https:/…
#>  9 distributional    2024-09-17 "Vec… "Vectorise… 0.5.0   "Mitch… http… https:/…
#> 10 eechidna          2021-02-25 "Exp… "Data from… 1.4.1   "Jerem… http… https:/…
#> # ℹ 41 more rows
#> # ℹ 1 more variable: github_url <chr>
get_meta(github_repos = c("robjhyndman/forecast", "earowang/hts"))
#> # A tibble: 2 × 7
#>   package  date       title                     version authors url   github_url
#>   <chr>    <date>     <chr>                     <chr>   <chr>   <chr> <chr>     
#> 1 forecast 2025-12-16 Forecasting Functions fo… 8.24.0… "Rob H… http… https://g…
#> 2 hts      2024-12-24 Hierarchical and Grouped… 6.0.3   "Rob H… http… https://g…
get_meta(cran_authors = "Emi Tanaka", github_repos = c("numbats/yowie", "numbats/monash"))
#> # A tibble: 15 × 9
#>    package           date       title description version authors url   cran_url
#>    <chr>             <date>     <chr> <chr>       <chr>   <chr>   <chr> <chr>   
#>  1 edibble           2024-05-06 "Enc… "A system … 1.1.1   "Emi T… http… https:/…
#>  2 emend             2025-04-01 "Cle… "Provides … 0.1.0   "Emi T… http… https:/…
#>  3 flipbookr         2021-05-31 "Par… "Flipbooks… 0.1.0   "Evang… http… https:/…
#>  4 gghdr             2022-10-27 "Vis… "Provides … 0.2.0   "Mitch… http… https:/…
#>  5 ggincerta         2025-11-11 "Ext… "Provide s… 0.1.0   "Xueqi… http… https:/…
#>  6 ggmatplot         2022-05-17 "Plo… "A quick a… 0.1.2   "Xuan … http… https:/…
#>  7 lme4              2025-12-02 "Lin… "Fit linea… 1.1-38  "Dougl… http… https:/…
#>  8 moodlequiz        2025-12-06 "R M… "Enables t… 0.2.0   "Mitch… http… https:/…
#>  9 nestr             2022-02-01 "Bui… "Facilitat… 0.1.2   "Emi T… http… https:/…
#> 10 predictNMB        2023-06-03 "Eva… "Estimates… 0.2.1   "Rex P… http… https:/…
#> 11 QuadratiK         2025-02-04 "Col… "It includ… 1.1.3   "Giova… http… https:/…
#> 12 shinycustomloader 2018-03-27 "Cus… "A custom … 0.9.0   "Emi T… http… https:/…
#> 13 xaringan          2025-08-18 "Pre… "Create HT… 0.31    "Yihui… http… https:/…
#> 14 monash            2025-09-25 "Con…  NA         0.0.0.… "Emi T… http… NA      
#> 15 yowie             2021-09-06 "Lon… "Longitudi… 0.1.0   "Dewi … http… https:/…
#> # ℹ 1 more variable: github_url <chr>
```
