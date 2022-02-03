# Find meta data for a vector of github repositories containing R packages and return as a tibble.
#
# repos Character string to find in author names
# Example:
# get_github_packages(c("robjhyndman/forecast", "earowang/hts"))

get_github_packages <- function(repos) {
  title <- version <- date <- authors <- url <- package <- character(length(repos))
  tmp <- tempfile()
  for (i in seq_along(repos)) {
    date[i] <- gh::gh(paste0("/repos/", repos[i]))$pushed_at
    utils::download.file(gh::gh(paste0("/repos/", repos[i], "/contents/DESCRIPTION"))$download_url, tmp)
    package[i] <- desc::desc_get_field("Package", file=tmp)
    title[i] <- desc::desc_get_field("Title", file = tmp)
    version[i] <- as.character(desc::desc_get_version(tmp))
    auth <- desc::desc_get_author("aut", tmp)
    if(!is.null(auth))
      authors[i] <- paste(as.character(auth), sep = "\n", collapse = "\n")
    else
      authors[i] <- desc::desc_get_field("Author",file=tmp)
    url[i] <- desc::desc_get_field("URL", file = tmp,
      default = gh::gh(paste0("/repos/", repos[i]))$html_url
    )
    url[i] <- (stringr::str_split(url[i], ",") |> unlist())[1]
  }
  tibble::tibble(package = package, date = as.Date(date),
                 title = title, version = version, authors = authors,
                 url = url, github_url = paste0("https://github.com/", repos))
}
