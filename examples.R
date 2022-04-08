# remotes::install_github("gorkang/downloadReferences")
library(downloadReferences)

# Using DOI
list_identifiers = get_dois_from_paper(DOI = "10.1001/jamainternmed.2021.0269")
download_papers(DOIs = list_identifiers$dois[10])

# Using doi web
list_identifiers_3 = get_dois_from_paper(HTML = "http://dx.doi.org/10.1001/jamainternmed.2021.0269")
download_papers(DOIs = list_identifiers_3$dois)

# Using web
list_identifiers_2 = get_dois_from_paper(HTML = "https://www.frontiersin.org/articles/10.3389/fpsyg.2015.01327/full")
download_papers(DOIs = list_identifiers_2$dois[1:3])
