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
  
  # DEBUG 
  # DOI = "10.1001/jamainternmed.2021.0269"
  # HTML = "http://dx.doi.org/10.1056/NEJMp1608282"
  # HTML = "https://www.frontiersin.org/articles/10.3389/fpsyg.2015.01327/full"
  # DOI = ""
  # DOI = "10.1056/NEJMp1608282"
  
  
  suppressPackageStartupMessages(library(dplyr))
  library(retractcheck)
  library(stringr)
  library(rvest)
  library(tidyr)
  library(crayon)
  
  
  if (DOI != "") HTML = paste0("http://dx.doi.org/", DOI)
  
  cat(crayon::green("\nGetting references from:", HTML, "\n"))  
  
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
    list_Pubmeds = stringr::str_extract_all(RAW_html_tibble$value, stringr::regex("PubMed: \\d+")) %>% unlist()
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
    
    rvest_pubmeds = stringr::str_extract_all(paste(rvest_href, collapse = " "), stringr::regex("pubmed/\\d+")) %>% unlist() %>% gsub("pubmed/", "", .) %>% unique(.)
    if (length(rvest_pubmeds) > 0) {
      rvest_pubmed_dois = rcrossref::id_converter(x = rvest_pubmeds, type = "auto") %>% .$records %>% tidyr::drop_na(doi) %>% pull(doi)
    } else {
      rvest_pubmed_dois = NULL
    }
    
    

  # Join --------------------------------------------------------------------

    DOIs = c(list_DOIs_from_links, list_DOIs, dois_from_pubmed, rvest_dois, rvest_pubmed_dois) %>% unique(.) %>% gsub("\\.$", "", .)
    PUBMEDs = c(list_Pubmeds, rvest_pubmeds) %>% unique(.) %>% gsub("\\.$", "", .)
    
    cat(crayon::silver("  Found", length(DOIs), "DOIS and", length(PUBMEDs), "PUBMEDs\n"))  
    
    final_list = list(dois = DOIs,
                      pubmed = PUBMEDs)

    return(final_list)
}



#' download_DOIs
#' 
#' Download papers using DOI
#'
#' @param DOIs string of DOIs
#'
#' @return
#' @export
#'
#' @examples
#' 
#' download_DOIs(DOIs = c("10.1056/NEJMp1608282", "10.1136/bmjopen-2015-008155"), wait_scihub = 5)
download_papers <- function(DOIs, wait_pubmed = 2, wait_scihub = 10) {
  
  # DOIs could be identifiers. 
  # rcrossref::id_converter(x = rvest_pubmeds, type = "auto") %>% .$records
  # If you pass a PMID, should be able to try to download from pubmed, and if not, try with scihub.py
  # https://www.ncbi.nlm.nih.gov/pubmed/
  # https://dx.doi.org/

  cat(crayon::bgWhite("\nTrying to download", length(DOIs), "papers\n"))  
  

  # Checks ------------------------------------------------------------------

  # If folder downloads does not exist, create it
  if (dir.exists("downloads") == FALSE) dir.create("downloads")
  if (file.exists("scihub.py-master/scihub/scihub.py") == FALSE) stop("'scihub.py' does not exist in the folder 'scihub.py-master/scihub/'. Get the last version from https://github.com/zaytoun/scihub.py")
  
  
  # Download single_DOI using PUBMED ------------------------------------------
  download_pubmed <- function(single_DOI, wait_pubmed = 2) {
    
    IDs = rcrossref::id_converter(x = single_DOI, type = "doi")  
    
    if ("pmcid" %in% names(IDs$records)) {
      Sys.sleep(wait_pubmed) # Be kind to the internet overlords
      download.file(url = paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/", IDs$records$pmcid , "/pdf/"), destfile = paste0("downloads/", gsub("[/\\(\\)]", "_", single_DOI), ".pdf"), quiet = TRUE)
      # } else {
      #   message("PUBMED page not found")
    }
    
  }
  
  # Try with PUBMED and if fails, try with scihub -----------------------------
  download_pubmed_or_sci <- function(single_DOI, wait_pubmed = 2, wait_scihub = 10) {

    cat(crayon::green("\nGetting", single_DOI, "\n"))  

    # Try to download using Pubmed
    RESULT = download_pubmed(single_DOI = single_DOI)
    
    # If it does not work, use sci-hub
    if (is.null(RESULT)) {
      # Using: https://github.com/zaytoun/scihub.py
      cat(crayon::yellow(paste0("Failed to download ", single_DOI, " using Pubmed. Will use sci-hub after ", wait_scihub, "s...\n")))
      Sys.sleep(wait_scihub) # Be kind to the internet overlords
      system(paste0("python3 scihub.py-master/scihub/scihub.py -d '", single_DOI ,"' -o 'downloads/'")) # The script also accepts PMID or URL
    } else {
      cat(crayon::silver("Downloaded", single_DOI, "using Pubmed\n"))
    }
    
  }
  
  # Try to download ALL the DOIs
  DOIs %>% purrr::walk(~ download_pubmed_or_sci(single_DOI = .x, wait_pubmed = wait_pubmed, wait_scihub = wait_scihub))
  
  
}
