# Find meta data for all packages on CRAN that match a given author and return as a tibble.
#
# author Character string to find in author names
# include_downloads Should total CRAN downloads since start be added to the tibble?
# start Start date for download statistics. Ignored if include_downloads is FALSE.
# Examples
# get_cran_packages("Hyndman")

get_cran_packages <- function(
  author,
  include_downloads = FALSE,
  start = "2000-01-01",
  end = Sys.Date()
) {
  dest_folder <- tempdir()
  dest_file <- paste0(dest_folder, "/", author)
  if (include_downloads) {
    dest_file <- paste0(dest_file, "_", start, "_", end)
  }
  dest_file <- paste0(dest_file, ".rds")
  if (file.exists(dest_file)) {
    return(readRDS(dest_file))
  } else {
    packages <- pkgsearch::ps(author, size = 10000) |>
      dplyr::filter(purrr::map_lgl(
        package_data,
        ~ grepl(author, .x$Author, fixed = TRUE)
      )) |>
      dplyr::pull(package)
    results <- suppressWarnings(get_meta_cran(
      packages,
      include_downloads,
      start,
      end
    ))
    saveRDS(results, dest_file)
    return(results)
  }
}

# Find meta data for a vector of CRAN packages and return as a tibble.
get_meta_cran <- function(
  packages,
  include_downloads = FALSE,
  start = "2000-01-01",
  end = Sys.Date()
) {
  meta <- list()
  for (i in seq_along(packages)) {
    meta[[i]] <- get_meta_cran_package(
      packages[i],
      include_downloads = include_downloads,
      start = start,
      end = end
    )
  }
  meta <- dplyr::bind_rows(meta)
  dplyr::arrange(meta, tolower(package))
}

# Return meta data on one CRAN package
get_meta_cran_package <- function(
  package,
  include_downloads = FALSE,
  start = "2000-01-01",
  end = Sys.Date()
) {
  dest_folder <- tempdir()
  dest_file <- paste0(dest_folder, "/", package)
  if (include_downloads) {
    dest_file <- paste0(dest_file, "_", start, "_", end)
  }
  dest_file <- paste0(dest_file, ".rds")
  if (file.exists(dest_file)) {
    return(readRDS(dest_file))
  }
  meta <- try(pkgsearch::cran_package(package), silent = TRUE)
  if ("try-error" %in% class(meta)) {
    warning(paste(package, "not on CRAN"))
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
  # Compute monthly downloads
  if (include_downloads) {
    downloads <- cranlogs::cran_downloads(package, from = start, to = end)
    output$first_download = min(downloads$date[downloads$count > 0])
    output$downloads = sum(downloads$count, na.rm = TRUE)
  }
  # Save to file
  saveRDS(output, dest_file)
  return(output)
}
