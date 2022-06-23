# Find meta data for all packages on CRAN that match a given author and return as a tibble.
#
# author Character string to find in author names
# include_downloads Should total CRAN downloads since start be added to the tibble?
# start Start date for download statistics. Ignored if include_downloads is FALSE.
# Examples
# get_cran_packages("Hyndman")

get_cran_packages <- function(author,
                              include_downloads = FALSE,
                              start = "2000-01-01") {
  packages <- pkgsearch::ps(author, size = 100) |>
    dplyr::filter(purrr::map_lgl(
      package_data, ~ grepl(author, .x$Author, fixed = TRUE)
    )) |>
    dplyr::pull(package)
  get_meta_cran(packages, include_downloads, start)
}

#' Return meta data on CRAN packages
#'
#' Find meta data for a vector of CRAN packages and return as a tibble.
#'
#' @param packages Character vector of CRAN package names
#' @param include_downloads Should total CRAN downloads since \code{start} be added to the tibble?
#' @param start Start date for download statistics. Ignored if \code{include_downloads} is \code{FALSE}.
#' @param github_repos Character string of github repos
#' @param prefer_cran When a package is both on CRAN and github, which information should be preferenced?
#' @examples
#' get_meta(cran_author = "Hyndman")
#' get_meta(github_repos = c("robjhyndman/forecast", "earowang/hts"))
#' get_meta(cran_author = "Emi Tanaka", github_repos = c("numbats/yowie", "numbats/monash"))
#' @export

# Get meta data for vector of packages on CRAN
get_meta_cran <- function(packages,
                          include_downloads = FALSE,
                          start = "2000-01-01") {
  title <- version <- date <- desc <- authors <- github_url <- rep(NA_character_, length(packages))
  url <- cran_url <- paste0("https://CRAN.R-project.org/package=", packages)
  for (i in seq_along(packages)) {
    meta <- try(pkgsearch::cran_package(packages[i]), silent = TRUE)
    if ("try-error" %in% class(meta)) {
      warning(paste(packages[i], "not on CRAN"))
    } else {
      date[i] <- meta$date
      title[i] <- meta$Title
      desc[i] <- meta$Description
      version[i] <- meta$Version
      # Replace new line unicodes with spaces
      authors[i] <- gsub("<U\\+000a>", " ", meta$Author, perl = TRUE)
      # Trim final period
      authors[i] <- gsub("\\.$", "", authors[i])
      if (!is.null(meta$URL)) {
        urls <- gsub("\\n", "", meta$URL)
        urls <- stringr::str_split(urls, ",") |> unlist()
        # Remove CRAN urls as we already have them
        iscran <- grep("cran", urls, ignore.case = TRUE)
        if (length(iscran) > 0) {
          urls <- urls[-iscran]
        }
        # Identify github urls
        isgithub <- grep("github.com", urls, ignore.case = TRUE)
        if (length(isgithub) > 0) {
          github_url[i] <- (urls[isgithub])[1]
          urls <- urls[-isgithub]
        }
        # Store url. Either a non-cran and non-github url if it exists
        if (length(urls) > 0) {
          url[i] <- urls[1]
        } # otherwise a github url
        else if (length(isgithub) > 0) {
          url[i] <- github_url[i]
        }
        # otherwise just keep the cran url
      }
    }
  }
  meta <- tibble::tibble(
    package = packages, date = date, title = title,
    description = desc, version = version, authors = authors,
    url = url, cran_url = cran_url,
    github_url = github_url
  )
  # Remove missing packages
  meta <- meta[!is.na(title), ]
  # Compute monthly downloads
  if (include_downloads) {
    downloads <- cranlogs::cran_downloads(packages, from = start) |>
      dplyr::group_by(package) |>
      dplyr::mutate(cumsum = cumsum(count)) |>
      dplyr::filter(cumsum > 0) |>
      dplyr::summarise(
        first_download = min(date),
        downloads = max(cumsum),
        .groups = "drop"
      )
    # combine information
    meta <- dplyr::left_join(meta, downloads, by = "package")
  }

  # Fix some variable types
  meta$date <- as.Date(meta$date)

  return(meta)
}
