library(httr2)
library(glue)
library(jsonify)
library(jsonlite)
library(tidyverse)

# check what has been downloaded already
downloaded_pdfs <- list.files("docs/hansard_pdfs/")

hansard_meta <- read_delim("output/hansard_meta.csv", "|") %>% 
  filter(!name %in% downloaded_pdfs) %>% 
  mutate(
    name = case_when(
      grepl("^.*\\.doc$", file_location) ~ glue("{name}.doc"),
      grepl("^.*\\.pdf$", name) ~ name,
      !grepl("^.*\\.pdf$", name) ~glue("{name}.pdf"),
    )
  )

# check that all patterns are accounted for 
hansard_meta %>% 
  filter(!grepl("^.*\\.pdf$", name)) %>% 
  filter(!grepl("^.*\\.doc$", file_location))

# define a function that download the documents
download_hansard_documents <- function(file_location, name){
  
  # make the request
  response <- request(file_location) %>% 
    req_perform(path = glue("docs/hansard_pdfs/{name}"))
  
  return(TRUE)
  
}

hansard_meta %>% 
  select(file_location, name) %>% 
  pmap(download_hansard_documents)


