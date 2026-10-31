# Find meta data for a vector of github repositories containing R packages and return as a tibble.
#
# repos Character string to find in author names
# Example:
# get_github_packages(c("robjhyndman/forecast", "earowang/hts"))

get_github_packages <- function(repos) {
  dplyr::bind_rows(par_lapply(repos, get_gh_package))
}


# Get meta data for a single github repo
get_gh_package <- function(repo) {
  key <- paste0("github_", sub("/", "_", repo))
  cached <- cache_read(key)
  if (!is.null(cached)) {
    return(cached)
  }
  date <- gh::gh(paste0("/repos/", repo))$pushed_at
  tmp <- tempfile()
  utils::download.file(
    gh::gh(paste0("/repos/", repo, "/contents/DESCRIPTION"))$download_url,
    tmp,
    quiet = TRUE
  )
  package <- desc::desc_get_field("Package", file = tmp)
  title <- desc::desc_get_field("Title", file = tmp)
  version <- as.character(desc::desc_get_version(tmp))
  auth <- desc::desc_get_author("aut", tmp)
  if (!is.null(auth))
    authors <- paste(as.character(auth), sep = "\n", collapse = "\n") else
    authors <- desc::desc_get_field("Author", file = tmp)
  url <- desc::desc_get_field(
    "URL",
    file = tmp,
    default = gh::gh(paste0("/repos/", repo))$html_url
  )
  url <- (stringr::str_split(url, ",") |> unlist())[1]
  output <- tibble::tibble(
    package = package,
    date = as.Date(date),
    title = title,
    version = version,
    authors = authors,
    url = url,
    github_url = paste0("https://github.com/", repo)
  )
  cache_write(key, output)
  return(output)
}
