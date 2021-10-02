# downloadReferences

After finding an important scientific paper, downloading all its references is both very useful and arduous. Although scientific knowledge should be easily accessible and [free](https://www.theguardian.com/commentisfree/2018/sep/13/scientific-publishing-rip-off-taxpayers-fund-research), not many tools help scientists with these types of time-wasting tasks. 

Here you can find a couple R functions to help download references from scientific papers. Of course, this is just a coding exercise, not meant to be used unlawfully.  


## How to install

You can install downloadReferences with `remotes::install_github("gorkang/downloadReferences")`

Depending on you system configuration, you may need to install [scihub.py](https://github.com/zaytoun/scihub.py)'s dependencies. Given a copy of the scihub.py script [downloaded: 2020-06-20] is included in the downloadReferences package, if you have [pip](https://pypi.org/project/pip/) (e.g. [Ubuntu]: `sudo apt install python-pip`), you can do:

```
system(paste0("pip install -r ", system.file(package = "downloadReferences"), "/scihub.py-master/requirements.txt"))
```

Alternatively, on Ubuntu 18.04 it may be enough with:

```
sudo apt-get install python3-bs4
sudo apt-get install python3-retrying
```


## How to use

Imagine you want to download the references in the paper `10.1001/jamainternmed.2021.0269`.

You can simply do:  

```
library(downloadReferences)
list_identifiers = get_dois_from_paper(DOI = "10.1001/jamainternmed.2021.0269")
download_papers(DOIs = list_identifiers$dois)
```

The function `get_dois_from_paper()` can be used with the DOI number `get_dois_from_paper(DOI = "10.1001/jamainternmed.2021.0269")`, the DOI website `get_dois_from_paper(HTML = "http://dx.doi.org/10.1001/jamainternmed.2021.0269")` or, sometimes, directly with the paper's website `get_dois_from_paper(HTML = "https://www.frontiersin.org/articles/10.3389/fpsyg.2015.01327/full")`.



## How it works  

With `get_dois_from_paper()` we get DOIs and/or PUBMED ids from a paper. Right now the functions needs a link to the html version of the paper, or a DOI (we get to the html version with `http://dx.doi.org/`).    

With `download_papers()` we try to download the papers:  

  - First, from `https://www.ncbi.nlm.nih.gov/pmc/`  
  
  - If that does not work, we use [scihub.py](https://github.com/zaytoun/scihub.py), a "Python API and command-line tool for Sci-Hub".
  
  - If sci-hub does not work, we are out of options, maybe try #ICanHazPDF (see: https://en.wikipedia.org/wiki/ICanHazPDF) :(


## Limitations

The full html version of the paper (including references) needs to be accessible to you. Regardless, this will probably miss lots of references, won't work in some/most cases, and can get you IP sent to hell if you abuse it.   

Remember to be kind, and patient (there is a `wait_pubmed` & `wait_scihub` parameters in the functions with longish defaults to placate the internet gods).  



## References

- [Scientific publishing is a rip-off. We fund the research – it should be free](https://www.theguardian.com/commentisfree/2018/sep/13/scientific-publishing-rip-off-taxpayers-fund-research)  
- [github.com/zaytoun/scihub.py](https://github.com/zaytoun/scihub.py)
