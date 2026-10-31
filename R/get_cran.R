# Find meta data for all packages on CRAN that match a given author and return as a tibble.
#
# author Character string to find in author names
# include_downloads Should total CRAN downloads since start be added to the tibble?
# start Start date for download statistics. Ignored if include_downloads is FALSE.
# Examples
# get_cran_packages(c("Lydeamore", "Di Cook", "Dianne Cook"))

get_cran_packages <- function(
  authors,
  include_downloads = FALSE,
  start = "2000-01-01",
  end = Sys.Date()
) {
  purrr::map_dfr(authors, get_meta_cran_author,
    include_downloads = include_downloads,
    start = start,
    end = end
  ) |>
    dplyr::distinct()
}

get_meta_cran_author <- function(author,
                                  include_downloads = FALSE,
                                  start = "2000-01-01",
                                  end = Sys.Date()) {
  key <- paste0("author_", author)
  if (include_downloads) {
    key <- paste0(key, "_", start, "_", end)
  }
  cached <- cache_read(key)
  if (!is.null(cached)) {
    return(cached)
  }
  packages <- pkgsearch::ps(author, size = 10000) |>
    dplyr::filter(purrr::map_lgl(
      package_data,
      ~ grepl(author, .x$Author, fixed = TRUE)
    )) |>
    dplyr::pull(package)
  if (length(packages) == 0) {
    warning(paste(author, "not on CRAN"))
    return(NULL)
  }
  results <- get_meta_cran(packages, include_downloads, start, end)
  cache_write(key, results)
  results
}

# Find meta data for a vector of CRAN packages and return as a tibble.
get_meta_cran <- function(
  packages,
  include_downloads = FALSE,
  start = "2000-01-01",
  end = Sys.Date()
) {
  meta <- par_lapply(packages, get_meta_cran_package) |>
    dplyr::bind_rows()
  missing <- setdiff(packages, meta$package)
  if (length(missing) > 0) {
    warning(paste(missing, "not on CRAN"))
  }
  if (include_downloads && NROW(meta) > 0) {
    downloads <- get_cran_downloads(meta$package, start, end)
    meta <- dplyr::left_join(meta, downloads, by = "package")
  }
  dplyr::arrange(meta, tolower(package))
}

# Total downloads and date of first download for a vector of CRAN packages.
# Uncached packages are requested in a few batched calls to cranlogs
# (much faster than one call per package).
get_cran_downloads <- function(packages, start, end, batch_size = 10) {
  key <- function(pkg) paste0("downloads_", pkg, "_", start, "_", end)
  cached <- lapply(packages, function(pkg) cache_read(key(pkg)))
  todo <- packages[vapply(cached, is.null, logical(1))]
  if (length(todo) > 0) {
    batches <- split(todo, ceiling(seq_along(todo) / batch_size))
    fetched <- par_lapply(batches, function(pkgs) {
      d <- cranlogs::cran_downloads(pkgs, from = start, to = end)
      if (is.null(d$package)) d$package <- pkgs
      lapply(pkgs, function(pkg) {
        x <- d[d$package == pkg, ]
        tibble::tibble(
          package = pkg,
          first_download = if (any(x$count > 0)) min(x$date[x$count > 0]) else as.Date(NA),
          downloads = sum(x$count, na.rm = TRUE)
        )
      })
    })
    for (res in unlist(fetched, recursive = FALSE)) {
      cache_write(key(res$package), res)
      cached[[match(res$package, packages)]] <- res
    }
  }
  dplyr::bind_rows(cached)
}

# Return meta data on one CRAN package
get_meta_cran_package <- function(
  package
) {
  key <- paste0("cran_", package)
  cached <- cache_read(key)
  if (!is.null(cached)) {
    return(cached)
  }
  meta <- try(pkgsearch::cran_package(package), silent = TRUE)
  if ("try-error" %in% class(meta)) {
    return(NULL)
  }
  # Authors
  # Replace new line unicodes with spaces
  authors <- gsub("<U\\+000a>", " ", meta$Author, perl = TRUE)
  # Trim final period
  authors <- gsub("\\.$", "", authors)

  # URLs
  url <- cran_url <- paste0("https://CRAN.R-project.org/package=", package)
  github_url <- NA_character_
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
      github_url <- (urls[isgithub])[1]
      urls <- urls[-isgithub]
    }
    # Store url. Either a non-cran and non-github url if it exists
    if (length(urls) > 0) {
      url <- urls[1]
    } else if (length(isgithub) > 0) { # otherwise a github url
      url <- github_url
    }
  }

  output <- tibble::tibble(
    package = package,
    date = as.Date(meta$date),
    title = meta$Title,
    description = meta$Description,
    version = meta$Version,
    authors = authors,
    url = url,
    cran_url = cran_url,
    github_url = github_url
  )
  cache_write(key, output)
  return(output)
}
