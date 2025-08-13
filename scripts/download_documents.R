library(glue)
library(httr2)
library(RSelenium)
library(wdman)
library(binman)
library(netstat)
library(rvest)
library(tidyverse)

# pull the html of a page
get_page <- function(rmDr){
  rmDr$getPageSource() %>% .[[1]] %>%
    read_html()
}

# screenshots remote driver client to help with headless dev
where_am_i <- function(rmDr, outname) {
  b64out <- rmDr$screenshot()
  writeBin(
    RCurl::base64Decode(b64out, "raw"),
    outname
  )
}

# pauses of random length to not overwhelm website
wait_a_bit <- function() {
  Sys.sleep(runif(n = 1, min = 1, max = 2))
}

port <- free_ports() %>% 
  .[1]

existing_container <- system(
  glue("docker ps --filter 'name=selenium_{port}' --format '{{{{.Names}}}}'"), 
  intern = TRUE
)

if (length(existing_container) > 0) {
  log_info(glue("Found running selenium container on port {port}, stopping and removing"))
  system(glue("docker stop selenium_{port}"))
  system(glue("docker rm selenium_{port}"))
}


# exit handlers to make sure remote driver ports are freed up and the selenium container is not left active
# on.exit(remDr$close(), add = TRUE)
# on.exit(system(glue("docker stop selenium_{port}")), add = TRUE)
# on.exit(system(glue("docker rm selenium_{port}")), add = TRUE)

# spin up a selenium server in a docker container and modify file permissions for writing
log_info(glue("spinning up selenium docker on port {port}..."))

system(
  glue(
    "docker run -d --name selenium_{port} -p 127.0.0.1:{port}:4444 -v ~/data/parliament/hansard:/home/seluser/downloads selenium/standalone-firefox:2.53.0"
  )
)

system(glue(
  "docker exec -u root selenium_{port} chmod 777 /home/seluser/downloads"
))

Sys.sleep(4) # to allow time for the container to spin up

# log_info(glue("selenium docker running: {existing_container}"))




profile_config <- makeFirefoxProfile(
  list(
    browser.download.dir = '/home/seluser/downloads',
    browser.download.folderList = 2L,
    browser.download.manager.showWhenStarting = FALSE,
    pdfjs.disabled = TRUE,
    plugin.scan.plid.all = FALSE,
    plugin.scan.Acrobat = "99.0",
    browser.helperApps.neverAsk.saveToDisk = 'application/pdf',
    unhandledPromptBehavior = "accept"
  )
)

remDr <- remoteDriver(
  port = as.integer(port),
  extraCapabilities = profile_config,
  
)

# rD <- rsDriver(
#   port = port,
#   browser = "firefox",
#   chromever = NULL
# )



# open the browser
remDr$open()

# navigate to the page we want
remDr$navigate("https://www.parliament.gov.za/docsjson/HANSARD?queries%5Btype%5D=HANSARD&sorts%5Bdate%5D=-1&page=1&perPage=10&offset=0")

Sys.sleep(2)

# see if we're in the right spot
where_am_i(remDr, "docs/screenshots/browser_state.png")


# get the html of the page
remDr$getPageSource() %>% 
  .[[1]] %>%
  read_html()

# Clean up after you're done
remDr$close()
system(glue("docker stop selenium_{port}"))
system(glue("docker rm selenium_{port}"))

