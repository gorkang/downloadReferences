#' get_dois_from_paper
#'
#' Get all references with a DOI or a PubmedID from a paper
#'
#' @param HTML Use the website of the paper
#' @param DOI Use the DOI number of the paper
#'
#' @return
#' @export
#'
#' @examples
#'
#' DF_new = get_dois_from_paper(DOI = "10.1001/jamainternmed.2021.0269")
get_dois_from_paper <- function(HTML, DOI = "") {

  suppressPackageStartupMessages(library(dplyr))
  library(retractcheck)
  library(stringr)
  library(rvest)
  library(tidyr)
  library(crayon)
  library(cli)


  if (DOI != "") HTML = paste0("http://dx.doi.org/", DOI)

  # cat(crayon::green("\nGetting references from:", HTML, "\n"))
  cli::cli_h1("\nGetting references from: {HTML}")

  # Method 1 ----------------------------------------------------------------

    cat(crayon::yellow("  Reading raw html...\n"))

    RAW_html = readLines(HTML)
    RAW_html_tibble = RAW_html %>% as_tibble()

    list_DOIs_from_links =
      RAW_html_tibble %>%
      filter(grepl("dx.doi.org", value)) %>%
      mutate(DOI_web = gsub('.*(http://dx.doi.org/.*?)\\".*', "\\1", value),
             DOI = gsub('http://dx.doi.org/', "", DOI_web)) %>%
      pull(DOI)

    list_DOIs = retractcheck::find_doi(RAW_html_tibble$value)
    list_Pubmeds = stringr::str_extract_all(RAW_html_tibble$value, stringr::regex("PubMed: \\d+", ignore_case = TRUE)) %>% unlist()
    if (length(list_Pubmeds) > 0) {
      dois_from_pubmed = rcrossref::id_converter(x = list_Pubmeds, type = "auto") %>% .$records %>% tidyr::drop_na(doi) %>% pull(doi)
    } else {
      dois_from_pubmed = NULL
    }

  # rcrossref::id_converter(x = list_Pubmeds, type = "pubmed")



  # Method 2 ----------------------------------------------------------------

    cat(crayon::yellow("  Reading rvest html...\n"))

    rvest_html = rvest::read_html(HTML)
    rvest_href = rvest_html %>% html_nodes("a") %>% html_attr("href")
    rvest_dois = retractcheck::find_doi(paste(rvest_href, collapse = " ")) %>% unique(.)

    rvest_pubmeds = stringr::str_extract_all(paste(rvest_href, collapse = " "), stringr::regex("pubmed/\\d+", ignore_case = TRUE)) %>% unlist() %>% gsub("pubmed/", "", ., ignore.case = TRUE) %>% unique(.)
    if (length(rvest_pubmeds) > 0) {
      rvest_pubmed_dois = rcrossref::id_converter(x = rvest_pubmeds, type = "auto") %>% .$records %>% tidyr::drop_na(doi) %>% pull(doi)
    } else {
      rvest_pubmed_dois = NULL
    }



  # Join --------------------------------------------------------------------

    DOIs = c(list_DOIs_from_links, list_DOIs, dois_from_pubmed, rvest_dois, rvest_pubmed_dois) %>% unique(.) %>% gsub("\\.$", "", .)
    PUBMEDs = c(list_Pubmeds, rvest_pubmeds) %>% unique(.) %>% gsub("\\.$", "", .)

    cat(crayon::silver("  Found", length(DOIs), "DOIS and", length(PUBMEDs), "PubMed ID's\n"))

    DOIs = list(dois = DOIs,
                pubmed = PUBMEDs)

    return(DOIs)
}



#' download_DOIs
#'
#' Download papers using DOI
#'
#' @param DOIs string of DOIs
#' @param wait_pubmed in seconds
#' @param wait_scihub in seconds
#' @param download_folder specify the folder where downloaded papers should go
#'
#' @return
#' @export
#'
#' @examples
#'
#' download_papers(DOIs = c("10.1056/NEJMp1608282", "10.1136/bmjopen-2015-008155"), wait_scihub = 5)
download_papers <- function(DOIs, wait_pubmed = 2, wait_scihub = 10, download_folder = "downloads") {

  # DOIs could be identifiers.
  # rcrossref::id_converter(x = rvest_pubmeds, type = "auto") %>% .$records
  # If you pass a PMID, should be able to try to download from pubmed, and if not, try with scihub.py
  # https://www.ncbi.nlm.nih.gov/pubmed/
  # https://dx.doi.org/

  suppressPackageStartupMessages(library(dplyr))

  cli::cli_alert_info("\nTrying to download {length(DOIs)} papers to {download_folder}/\n")


  # Checks ------------------------------------------------------------------

  # If folder downloads does not exist, create it
  if (dir.exists(download_folder) == FALSE) {
    cli::cli_alert_info("'{download_folder}/' folder does not exist, creating...")
    dir.create(download_folder, recursive = TRUE)
  }
  # if (file.exists("scihub.py-master/scihub/scihub.py") == FALSE) stop("'scihub.py' does not exist in the folder 'scihub.py-master/scihub/'. Get the last version from https://github.com/zaytoun/scihub.py")


  # Download single_DOI using PUBMED ------------------------------------------
  download_pubmed <- function(single_DOI, wait_pubmed = 2) {

    # Get PMID from the DOI
    IDs = rcrossref::id_converter(x = single_DOI, type = "doi")

    # If PMID exists, download
    if ("pmcid" %in% names(IDs$records)) {
      Sys.sleep(wait_pubmed) # Be kind to the internet overlords
      suppressWarnings(download.file(url = paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/", IDs$records$pmcid , "/pdf/"), destfile = paste0(normalizePath(download_folder), "/", gsub("[/\\(\\)]", "_", single_DOI), ".pdf"), quiet = TRUE))
    }

  }

  download_pubmed_safely = purrr::safely(download_pubmed)

  # Try with PUBMED and if fails, try with scihub -----------------------------
  download_pubmed_or_sci <- function(single_DOI, wait_pubmed = 2, wait_scihub = 10) {

    cat(crayon::green("\nGetting", single_DOI, "\n"))

    # Try to download using PubMed
    RESULT = download_pubmed_safely(single_DOI = single_DOI)


    # If it does not work, use Sci-Hub
    if (!is.null(RESULT$error) | is.null(RESULT$result)) {
      # Using: https://github.com/zaytoun/scihub.py
      OUTPUT = tibble(DOI = single_DOI, PubMed = "ERROR", SciHub = NA_character_, STATUS = "ERROR")
      cli::cli_alert_danger("Failed to download {single_DOI} using PubMed. Will try Sci-Hub after {wait_scihub}s...\n")
      Sys.sleep(wait_scihub) # Be kind to the internet overlords
      # system(paste0("python3 scihub.py-master/scihub/scihub.py -d '", single_DOI ,"' -o 'downloads/'")) # The script also accepts PMID or URL
      RESULT_scihub = processx::run(command = "python3", args = c(paste0(system.file(package = "downloadReferences"), "/scihub.py-master/scihub/scihub.py"), "-d", single_DOI, "-o",  normalizePath(download_folder)))

      if (grepl("INFO:Sci-Hub:Failed to fetch pdf with identifier", RESULT_scihub$stderr)) {
        OUTPUT = tibble(DOI = single_DOI, PubMed = "ERROR", SciHub = "ERROR", STATUS = "ERROR")
        cli::cli_alert_danger("ERROR retrieving {single_DOI} || {crayon::silver('Maybe try #ICanHazPDF (see: https://en.wikipedia.org/wiki/ICanHazPDF)')}")
      } else {
        OUTPUT = tibble(DOI = single_DOI, PubMed = "ERROR", SciHub = "OK", STATUS = "OK")
        cli::cli_alert_success(crayon::silver("Downloaded", single_DOI, "using Sci-Hub"))
      }


    } else {
      cli::cli_alert_success(crayon::silver("Downloaded", single_DOI, "using PubMed"))
      OUTPUT = tibble(DOI = single_DOI, PubMed = "OK", SciHub = NA_character_, STATUS = "OK")
    }

    return(OUTPUT)
  }

  # Try to download ALL the DOIs
  OUT_MAP = DOIs %>% purrr::map_df(~ download_pubmed_or_sci(single_DOI = .x, wait_pubmed = wait_pubmed, wait_scihub = wait_scihub))
  return(OUT_MAP)

}
