library(glue)

port = 2202
system(glue("docker ps --filter 'name=selenium_{port}' --format '{{{{.Names}}}}'"), intern = TRUE)

if (length(existing_container) > 0) {
  log_info(glue("Found running selenium container on port {port}, stopping and removing"))
  system(glue("docker stop selenium_{port}"))
  system(glue("docker rm selenium_{port}"))
}

# saves a screenshot of the remote driver
screenshot_save <- function(remote_driver, file_name) {
  
  screen_shot <- remote_driver$screenshot()
  
  writeBin(
    RCurl::base64Decode(screen_shot, "raw"),
    file_name
  )
  
}

# read the html from the page
get_page <- function(rmDr){
  
  rmDr$getPageSource() %>% 
    .[[1]] %>%
    read_html()

}

start_up_remDr <- function(port){
  
  # list of profile settings that allows pdfs to be downloaded on click without any interactive nonsense
  cprof <- makeFirefoxProfile(
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
  
  remDr <- remoteDriver(port = as.integer(port),
                        extraCapabilities = cprof)
  remDr$open(silent = TRUE)
  
  return(remDr)
}