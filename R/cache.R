# Cache and parallel helpers.
#
# Results are cached on disk, one .rds file per query. File names contain
# today's date, so the cache persists across R sessions (and targets builds)
# but data is refreshed at most once per day. Files from earlier days for the
# same query are removed when a new one is written.
#
# Options:
#   pkgmeta.cache_dir  Directory for the cache. Default: tools::R_user_dir("pkgmeta", "cache").
#                      Set to tempdir() for a per-session cache.
#   pkgmeta.cores      Number of parallel workers for web requests.
#                      Default: min(8, number of cores). Set to 1 to disable.
#                      (Parallel workers are separate R processes with pkgmeta installed.)

cache_dir <- function() {
  dir <- getOption("pkgmeta.cache_dir", tools::R_user_dir("pkgmeta", "cache"))
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  dir
}

cache_key <- function(key) gsub("[^A-Za-z0-9._-]", "_", key)

cache_file <- function(key) {
  file.path(cache_dir(), paste0(cache_key(key), "__", Sys.Date(), ".rds"))
}

cache_read <- function(key) {
  file <- cache_file(key)
  if (file.exists(file)) readRDS(file) else NULL
}

cache_write <- function(key, value) {
  file <- cache_file(key)
  # Remove stale (earlier-dated) versions of this query
  files <- list.files(dirname(file), full.names = TRUE)
  stale <- startsWith(basename(files), paste0(cache_key(key), "__"))
  unlink(setdiff(files[stale], file))
  saveRDS(value, file)
  invisible(value)
}

# Parallel lapply for web requests.
#
# Uses separate worker processes (not forking): forked workers share the
# parent's open HTTP connections, which corrupts replies whenever the parent
# session has already made requests. Workers are started on first use and
# shut down by stop_workers() (called via on.exit() in get_meta()).
workers <- new.env(parent = emptyenv())

n_cores <- function() {
  cores <- getOption("pkgmeta.cores", min(8L, parallel::detectCores()))
  cores <- if (is.na(cores)) 1L else as.integer(cores)
  # R CMD check (and CRAN) allow at most 2 simultaneous processes
  if (nzchar(Sys.getenv("_R_CHECK_LIMIT_CORES_", ""))) cores <- min(cores, 2L)
  cores
}

par_lapply <- function(x, f, ...) {
  n <- min(n_cores(), length(x))
  if (n < 2) {
    return(lapply(x, f, ...))
  }
  if (is.null(workers$cl)) {
    cl <- parallel::makePSOCKcluster(n)
    dir <- cache_dir()
    parallel::clusterCall(cl, function(dir) {
      options(pkgmeta.cache_dir = dir)
      NULL
    }, dir)
    workers$cl <- cl
  }
  parallel::parLapplyLB(workers$cl, x, f, ...)
}

stop_workers <- function() {
  if (!is.null(workers$cl)) {
    parallel::stopCluster(workers$cl)
    workers$cl <- NULL
  }
  invisible()
}
