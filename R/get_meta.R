#' Return meta data on CRAN and github packages
#'
#' Find meta data for all packages on CRAN that match a given author and all packages contained in
#' a vector of github repositories and return as a tibble. Meta data on packages that are
#' both on CRAN and github will be combined into a single row. Where meta data clash, the
#' CRAN version is preferred when \code{prefer_cran} is \code{TRUE}, otherwise the github
#' version is preferred.
#'
#' @param cran_author Character string to find in CRAN author names
#' @param include_downloads Should total CRAN downloads since \code{start} be added to the tibble?
#' @param start Start date for download statistics. Ignored if \code{include_downloads} is \code{FALSE}.
#' @param end End date for download statistics. Ignored if \code{include_downloads} is \code{FALSE}.
#' @param github_repos Character vector of github repos
#' @param prefer_cran When a package is both on CRAN and github, which information should be preferenced?
#' @examples
#' get_meta(cran_author = "Hyndman")
#' get_meta(github_repos = c("robjhyndman/forecast", "earowang/hts"))
#' get_meta(cran_author = "Emi Tanaka", github_repos = c("numbats/yowie", "numbats/monash"))
#' @export

get_meta <- function(cran_author = NULL,
                     include_downloads = FALSE,
                     start = "2000-01-01",
                     end = Sys.Date(),
                     github_repos = NULL,
                     prefer_cran = TRUE) {
  if(is.null(cran_author) & is.null(github_repos)) {
    stop("At least one of cran_author and github_repos must be specified.")
  } else if(!is.null(cran_author)) {
    # Get CRAN packages that match the author
    #cran_author <- stringr::str_replace_all(cran_author, " ", "%20")
    cran_packages <- get_cran_packages(cran_author, include_downloads = include_downloads, start = start, end = end)
  }
  # Get github packages listed in repos
  if (!is.null(github_repos)) {
    github_packages <- get_github_packages(github_repos)
  }

  # Return results if only one of CRAN or github available
  if(is.null(cran_author)) {
    return(github_packages)
  } else if(is.null(github_repos)) {
    return(cran_packages)
  }

  # Otherwise both available
  # Combine the two sets of packages, favouring CRAN info when both available
  github_only <- dplyr::anti_join(github_packages, cran_packages, by = "package")
  cran_only <- dplyr::anti_join(cran_packages, github_packages, by = "package")
  if (prefer_cran) {
    suffix <- c(".zzzz", "")
  }
  else {
    suffix <- c("", ".zzzz")
  }
  both <- dplyr::inner_join(
      github_packages,
      cran_packages |> dplyr::select(-github_url),
      by = "package", suffix = suffix
    ) |>
    dplyr::select(-dplyr::ends_with(".zzzz"))
  all_packages <- dplyr::bind_rows(
    cran_only |> dplyr::mutate(on_cran = TRUE, on_github = FALSE),
    github_only |> dplyr::mutate(on_cran = FALSE, on_github = TRUE),
    both |> dplyr::mutate(on_cran = TRUE, on_github = TRUE)
  )
  all_packages$on_github <- all_packages$on_github | !is.na(all_packages$github_url)

  # Add url if it is missing. Use CRAN as first choice, then github.
  all_packages <- all_packages |>
    dplyr::mutate(
      url = dplyr::if_else(!is.na(url), url,
        dplyr::if_else(on_cran, cran_url, github_url))
    )
  all_packages$on_cran <- all_packages$on_github <- NULL

  return(all_packages)
}
