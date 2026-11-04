#!/usr/bin/env Rscript

# GGL downscalr merge: read each downscaled_<REGION>.rds[[2]] in one scenario
# directory and append it to the G4M land-cover CSV.

options(stringsAsFactors = FALSE)

REGION59 <- c(
  "ArgentinaReg", "AustraliaReg", "BrazilReg", "CanadaReg", "ChinaReg",
  "CongoBasin", "Former_USSR", "IndiaReg", "IndonesiaReg", "JapanReg",
  "MalaysiaReg", "MexicoReg", "MiddleEast", "NewZealandReg", "NorthernAf",
  "Pacific_Islands", "RCAM", "RCEU", "ROWE", "RSAM", "RSAS", "RSEA_OPA",
  "RSEA_PAC", "RussiaReg", "SouthAfrReg", "SouthKorea", "EasternAf",
  "SouthernAf", "WesternAf", "TurkeyReg", "UkraineReg", "USAReg",
  "LatviaReg", "EstoniaReg", "LithuaniaReg", "LuxembourgReg", "SlovakiaReg",
  "AustriaReg", "SloveniaReg", "FinlandReg", "FranceReg", "SpainReg",
  "MaltaReg", "BelgiumReg", "GermanyReg", "SwedenReg", "GreeceReg",
  "BulgariaReg", "NetherlandsReg", "HungaryReg", "IrelandReg", "ItalyReg",
  "PolandReg", "CroatiaReg", "PortugalReg", "CyprusReg", "CzechRepReg",
  "DenmarkReg", "RomaniaReg"
)

stopf <- function(fmt, ...) {
  stop(sprintf(fmt, ...), call. = FALSE)
}

read_env <- function(name) {
  value <- Sys.getenv(name, unset = "")
  if (!nzchar(value)) {
    stopf("missing required environment variable: %s", name)
  }
  value
}

parse_args <- function(args) {
  values <- list(input = "", output = "")
  index <- 1L
  while (index <= length(args)) {
    arg <- args[[index]]
    flag <- sub("=.*$", "", arg)
    if (!flag %in% c("--input", "--output")) {
      stopf("unknown argument: %s", arg)
    }
    name <- sub("^--", "", flag)
    if (grepl("=", arg, fixed = TRUE)) {
      values[[name]] <- sub("^[^=]*=", "", arg)
      index <- index + 1L
    } else if (index == length(args)) {
      stopf("missing value for %s", flag)
    } else {
      values[[name]] <- args[[index + 1L]]
      index <- index + 2L
    }
  }
  missing <- names(values)[!nzchar(unlist(values, use.names = FALSE))]
  if (length(missing) > 0L) {
    stopf("missing required argument: --%s", missing[[1L]])
  }
  values
}

list_region_files <- function(input_root) {
  list.files(
    input_root,
    pattern = "^downscaled_[A-Za-z0-9_]+\\.rds$",
    recursive = FALSE,
    full.names = FALSE
  )
}

# Do not merge a partial set. One missing region stops the merge.
# Late files get 3 waits of 10 seconds, then the 4th read fails.
wait_for_regions <- function(input_root) {
  max_reads <- 4L
  for (attempt in seq_len(max_reads)) {
    names <- list_region_files(input_root)
    regions <- sub("^downscaled_(.+)\\.rds$", "\\1", names)
    unknown <- regions[!regions %in% REGION59]
    if (length(unknown) > 0L) {
      stopf("unknown region in filename: %s", paste(unknown, collapse = ", "))
    }
    if (anyDuplicated(regions)) {
      stopf("duplicate regional result in %s", input_root)
    }

    missing <- REGION59[!REGION59 %in% regions]
    if (length(missing) == 0L) {
      return(names)
    }
    if (attempt == max_reads) {
      stopf(
        "missing %d of 59 regions in %s after %d reads: %s",
        length(missing),
        input_root,
        max_reads,
        paste(missing, collapse = ", ")
      )
    }
    message(sprintf(
      "missing %d of 59 regions (read %d/%d); waiting 10 seconds: %s",
      length(missing),
      attempt,
      max_reads,
      paste(missing, collapse = ", ")
    ))
    Sys.sleep(15)
  }
}

discover_results <- function(input_root) {
  input_root <- normalizePath(input_root, mustWork = TRUE)
  names <- wait_for_regions(input_root)
  regions <- sub("^downscaled_(.+)\\.rds$", "\\1", names)

  # Malta has no GLOBIOM forest on the G4M crosswalk, so [[2]] is empty.
  # G4M itself has forest there. Do not merge this region.
  # The file must still be present before the merge starts.
  skipped <- regions == "MaltaReg"
  message("Skipping MaltaReg: no GLOBIOM forest cells on the G4M crosswalk")
  names <- names[!skipped]
  regions <- regions[!skipped]

  nested <- list.files(
    input_root,
    pattern = "^downscaled.*\\.rds$",
    recursive = TRUE,
    full.names = TRUE
  )
  nestmergered <- nested[dirname(normalizePath(nested)) != input_root]
  if (length(nestmergered) > 0L) {
    stopf("regional result is not in the scenario directory: %s", nestmergered[[1L]])
  }

  unnamed <- list.files(
    input_root,
    pattern = "^downscaled\\.rds$",
    recursive = FALSE,
    full.names = FALSE
  )
  if (length(unnamed) > 0L) {
    stopf("unnamed downscaled.rds is not a regional result: %s", input_root)
  }

  file.path(input_root, names[order(regions)])
}

load_g4m_table <- function(path) {
  result <- readRDS(path)
  if (!is.list(result) || length(result) < 2L || !is.data.frame(result[[2L]])) {
    stopf("downscaled result does not contain G4M table at [[2]]: %s", path)
  }
  table <- result[[2L]]
  table$LC_TYPES_EPIC <- NULL
  required <- c("SCEN1", "SCEN2", "SCEN3")
  missing <- required[!required %in% names(table)]
  if (length(missing) > 0L) {
    stopf("G4M table in %s lacks %s", path, paste(missing, collapse = ", "))
  }
  scenario <- vapply(required, function(column) {
    values <- unique(as.character(table[[column]]))
    if (length(values) != 1L || !nzchar(values[[1L]])) {
      stopf("scenario column %s is not unique in %s", column, path)
    }
    values[[1L]]
  }, character(1))
  names(scenario) <- required
  list(path = path, scenario = scenario, g4m = table)
}

main <- function() {
  args <- parse_args(commandArgs(trailingOnly = TRUE))
  input_root <- args$input
  output_root <- args$output
  label <- read_env("ROOT_JOB_ID")
  if (!grepl("^[A-Za-z0-9_.-]+$", label)) {
    stopf("ROOT_JOB_ID must be a safe label")
  }

  if (!grepl("^/", output_root) || identical(output_root, "/")) {
    stopf("--output must be an absolute path other than /")
  }
  if (!dir.exists(output_root) && !dir.create(output_root, recursive = TRUE)) {
    stopf("cannot create output root: %s", output_root)
  }

  suppressPackageStartupMessages(library(readr))

  jobs <- lapply(discover_results(input_root), load_g4m_table)

  scenario_keys <- vapply(jobs, function(job) {
    paste(job$scenario, collapse = "\t")
  }, character(1))
  if (length(unique(scenario_keys)) != 1L) {
    stopf("input directory contains more than one scenario")
  }

  scenario <- jobs[[1L]]$scenario
  out_name <- sprintf("GLOBIOM2G4M_output_LC_abs_%s.csv", label)
  out_path <- file.path(output_root, out_name)
  if (file.exists(out_path)) {
    unlink(out_path)
  }
  for (job_index in seq_along(jobs)) {
    readr::write_csv(jobs[[job_index]]$g4m, out_path, append = job_index != 1L)
  }
  message(sprintf(
    "Wrote %s for %s / %s / %s (%d regions)",
    out_name,
    scenario[["SCEN1"]],
    scenario[["SCEN2"]],
    scenario[["SCEN3"]],
    length(jobs)
  ))
  message(sprintf(
    "Downscaling merge complete: %d regions -> %s",
    length(jobs),
    output_root
  ))
}

main()
