# downloadReferences

After finding an important scientific paper, downloading all its references is both very useful and arduous. Although scientific knowledge should be easily accessible and [free](https://www.theguardian.com/commentisfree/2018/sep/13/scientific-publishing-rip-off-taxpayers-fund-research), not many tools help scientists with these types of time-wasting tasks. 

Here you can find a couple R functions to help download references from scientific papers. Of course, this is just a coding exercise, not meant to be used unlawfully.  


## How to use

You will need to download the full repo for the functions to work. See some examples in `examples.R`.  


## How it works  

With `get_dois_from_paper()` we get DOIs and/or PUBMED ids from a paper. Right now the functions needs a link to the html version of the paper, or a DOI (we try to get to the html version with `http://dx.doi.org/`).    

With `download_papers()` we try to download the papers:  

  - First, from `https://www.ncbi.nlm.nih.gov/pmc/`  
  
  - If that does not work, we use [scihub.py](https://github.com/zaytoun/scihub.py), a "Python API and command-line tool for Sci-Hub".


## Limitations

The full html version of the paper (including references) needs to be accessible to you. Regardless, this will probably miss lots of references, won't work in some/most cases, and can get you IP sent to hell if you abuse it.   

Remember to be kind, and patient (there is  a wait_x parameter in the functions to placate the internet gods).  



## References

- [Scientific publishing is a rip-off. We fund the research – it should be free](https://www.theguardian.com/commentisfree/2018/sep/13/scientific-publishing-rip-off-taxpayers-fund-research)  
- [github.com/zaytoun/scihub.py](https://github.com/zaytoun/scihub.py)