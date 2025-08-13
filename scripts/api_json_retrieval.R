library(httr2)
library(glue)
library(jsonify)
library(jsonlite)
library(tidyverse)


# check to encode this properly and if you can catch everything without having to traverse
base_url <- "https://www.parliament.gov.za/" 
parameters <- c("docsjson/HANSARD?queries%5Btype%5D=HANSARD", "&sorts%5Bdate%5D=-1", "&page={page_num}", "&perPage={per_page}", "&offset={offset_num}")

# building the request
url <- str_c(c(base_url, parameters), collapse = "")
page_num = 1
per_page = 10
offset_num = 0

req_object <- request(glue(url)) 

# check how many objects there are to retrieve
per_page = req_object %>% 
  req_perform() %>% 
  resp_body_string() %>% 
  from_json() %>% 
  .$queryRecordCount

req_object <- request(glue(url)) 


# check if it looks correct
req_object %>% 
  req_dry_run()

# if satisfied with the request, we perform it 
response <- req_object %>% 
  req_perform()

# see what the response looks like
hansard_meta <- response %>% 
  resp_body_string() %>% 
  from_json() %>% 
  .$records %>% 
  as_tibble() %>% 
  select(
    name,
    house,
    language,
    date,
    type,
    file_location
  ) %>% 
  mutate(
    # convert dates from character to date
    date = ymd(gsub("[^0-9]", "", date)),
    # some say "Joint" others "JOINT", standardise
    house = gsub("Joint", "JOINT", house),
    # NA causes issues 
    house = gsub("NA", "NATIONAL ASSEMBLY", house),
    # set to NA if language is missing
    language = na_if(x = language, ""),
    # add the base of the url to the file location for later download
    file_location = str_c("https://www.parliament.gov.za/storage/app/media/Docs/", file_location, sep = "")
  ) %>% 
  arrange(desc(date))

# visualise to see any weird patterns
hansard_meta %>% 
  mutate(month = floor_date(date, unit = "months")) %>% 
  count(month, house, name = "session_count") %>% 
  ggplot(
    aes(x = month, y = session_count, colour = house)
  ) +
  geom_line() +
  facet_wrap(~house) +
  theme_classic()

# check against what has already been scraped
read_delim("output/hansard_meta.csv", "|") %>%
  anti_join(hansard_meta)

# save the data retrieved 
hansard_meta %>% 
  write_delim(
    "output/hansard_meta.csv", 
    delim = "|",
    append = T
  )
