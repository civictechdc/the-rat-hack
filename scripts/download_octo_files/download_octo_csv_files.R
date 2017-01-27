library(RCurl)
library(XML)

setwd(getSrcDirectory(function(x){}))

#####
# Major issue: a few files on the server seem to periodically become inaccessible,
# fluctuating back and forth on the order of seconds. Needed to repeatedly run the script.
#
archive_URL = "http://data.octo.dc.gov/feeds/src/archive/"

file_type_strings = list("csv" = "_CSV.zip",
                         "xml" = "lain.zip")
file_type = "xml" # "csv"

files_page_html <- getURL(archive_URL)

files_page = htmlTreeParse(files_page_html, useInternal = TRUE)

files = unlist(xpathApply(files_page, '//a', xmlValue))
files = files[unlist(lapply(files, function(x){substr(x, nchar(x) - 7, nchar(x))})) == file_type_strings[[file_type]]]

downloaded_files = list.files(paste0("../../data/311/original_sources/octo/scraped_complete_files/", file_type, "/"))

for (i in seq_along(files)) {
  if (!(files[i] %in% downloaded_files)) {
    download.file(paste0(archive_URL,files[i]),
                  paste0("../../data/311/original_sources/octo/scraped_complete_files/", file_type, "/", files[i]))
  }
}
