library(XML)
library(dplyr)

setwd(getSrcDirectory(function(x){}))

files = list.files("../../data/311/original_sources/octo/scraped_complete_files/xml/")

temp_directory = tempdir()
consolidated_frame = data_frame()
bad_indices = list()

for (i in seq_along(files)) {
  print(files[i])
  unzip(paste0("../../data/311/original_sources/octo/scraped_complete_files/xml/",
               files[i]), exdir = temp_directory)
  tryCatch({
    file_data = xmlInternalTreeParse(paste0(temp_directory, "/", gsub(".zip", ".xml", files[i])))
    #file_data_frame = xmlToDataFrame(file_data)
    file_data_frame = data_frame(
      SERVICEREQUESTID = xpathSApply(file_data, "//dcst:servicerequestid", xmlValue),
      SERVICEPRIORITY = xpathSApply(file_data, "//dcst:servicepriority", xmlValue),
      SERVICECODE = xpathSApply(file_data, "//dcst:servicecode", xmlValue),
      SERVICECODEDESCRIPTION = xpathSApply(file_data, "//dcst:servicecodedescription", xmlValue),
      SERVICETYPECODE = xpathSApply(file_data, "//dcst:servicetypecode", xmlValue),
      SERVICETYPECODEDESCRIPTION = xpathSApply(file_data, "//dcst:servicetypecodedescription", xmlValue),
      SERVICEORDERDATE = xpathSApply(file_data, "//dcst:serviceorderdate", xmlValue), # TODO: remove 'T'?
      SERVICEORDERSTATUS = xpathSApply(file_data, "//dcst:serviceorderstatus", xmlValue),
      SERVICECALLCOUNT = xpathSApply(file_data, "//dcst:servicecallcount", xmlValue),
      AGENCYABBREVIATION = xpathSApply(file_data, "//dcst:agencyabbreviation", xmlValue),
      INSPECTIONFLAG = xpathSApply(file_data, "//dcst:inspectionflag", xmlValue),
      INSPECTIONDATE = xpathSApply(file_data, "//dcst:inspectiondate", xmlValue),
      RESOLUTION = xpathSApply(file_data, "//dcst:resolution", xmlValue),
      RESOLUTIONDATE = xpathSApply(file_data, "//dcst:resolutiondate", xmlValue),
      SERVICEDUEDATE = xpathSApply(file_data, "//dcst:serviceduedate", xmlValue),
      SERVICENOTES = xpathSApply(file_data, "//dcst:servicenotes", xmlValue),
      PARENTSERVICEREQUESTID = xpathSApply(file_data, "//dcst:parentservicerequestid", xmlValue),
      ADDDATE = xpathSApply(file_data, "//dcst:adddate", xmlValue),
      LASTMODIFIEDDATE = xpathSApply(file_data, "//dcst:lastmodifieddate", xmlValue),
      SITEADDRESS = xpathSApply(file_data, "//dcst:siteaddress", xmlValue),
      LATITUDE = xpathSApply(file_data, "//geo:lat", xmlValue, namespaces = c(geo = "http://www.w3.org/2003/01/geo/wgs84_pos#")),
      LONGITUDE = xpathSApply(file_data, "//geo:long", xmlValue, namespaces = c(geo = "http://www.w3.org/2003/01/geo/wgs84_pos#")),
      ZIPCODE = xpathSApply(file_data, "//dcst:zipcode", xmlValue),
      MARADDRESSREPOSITORYID = xpathSApply(file_data, "//dcst:maraddressrepositoryid", xmlValue),
      DCSTATADDRESSKEY = xpathSApply(file_data, "//dcst:dcstataddresskey", xmlValue),
      DCSTATLOCATIONKEY = xpathSApply(file_data, "//dcst:dcstatlocationkey", xmlValue),
      WARD = xpathSApply(file_data, "//dcst:ward", xmlValue),
      ANC = xpathSApply(file_data, "//dcst:anc", xmlValue),
      SMD = xpathSApply(file_data, "//dcst:smd", xmlValue),
      DISTRICT = xpathSApply(file_data, "//dcst:district", xmlValue),
      PSA = xpathSApply(file_data, "//dcst:psa", xmlValue),
      NEIGHBORHOODCLUSTER = xpathSApply(file_data, "//dcst:neighborhoodcluster", xmlValue),
      HOTSPOT2006NAME = xpathSApply(file_data, "//dcst:hotspot2006name", xmlValue),
      HOTSPOT2005NAME = xpathSApply(file_data, "//dcst:hotspot2005name", xmlValue),
      HOTSPOT2004NAME = xpathSApply(file_data, "//dcst:hotspot2004name", xmlValue),
      SERVICESOURCECODE = xpathSApply(file_data, "//dcst:servicesourcecode", xmlValue)
    ) %>%
      mutate(SERVICEORDERDATE = gsub("T", " ", SERVICEORDERDATE),
             INSPECTIONDATE = gsub("T", " ", INSPECTIONDATE),
             RESOLUTIONDATE = gsub("T", " ", RESOLUTIONDATE),
             SERVICEDUEDATE = gsub("T", " ", SERVICEDUEDATE),
             ADDDATE = gsub("T", " ", ADDDATE),
             LASTMODIFIEDDATE = gsub("T", " ", LASTMODIFIEDDATE))
    
    if (nrow(consolidated_frame) > 0) {
      file_data_frame = file_data_frame %>% anti_join(consolidated_frame, by = "SERVICEREQUESTID")
    }
    consolidated_frame = rbind(consolidated_frame,
                               file_data_frame)
  }, error = function(e) {
    print(e)
    bad_indices <<- append(bad_indices, i)
  })
}

#library(readr)
#write_csv(consolidated_frame, "consolidated_frame_01_22_17.csv")
#
# Ended with error 1-17-17
# (i = 18)
# [1] "src_2011_05_17_plain.zip"
# StartTag: invalid element name
