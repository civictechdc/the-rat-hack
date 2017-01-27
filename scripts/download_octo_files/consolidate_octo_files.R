library(readr)
library(dplyr)
library(stringr)

setwd(dirname(sys.frame(1)$ofile))

files = list.files("../../data/311/original_sources/octo/scraped_complete_files/")

consolidated_frame = data_frame()

clean_and_load = function(filename, path = "../../data/311/original_sources/octo/") {
  pre_load_data = read_csv(paste0(path, "scraped_complete_files/", filename))
  pre_load_data_errors = problems(pre_load_data)
  
  if (nrow(pre_load_data_errors) > 1) {
    bad_lines = pre_load_data_errors$row + 1
    lines = read_lines(paste0(path, "scraped_complete_files/", filename))
    
    lines_clean = lines
    
    field_names = strsplit(lines_clean[1], ",")[[1]]
    if (field_names[length(field_names)] == "") {
      number_of_fields = min(which(field_names == "")) - 1
      trailing_comma_string = substr(lines[1],
                                     nchar(lines[1]) - length(field_names) + number_of_fields,
                                     nchar(lines[1]))
      lines_clean[1] = substr(lines_clean[1],
                              1,
                              nchar(lines[1]) - length(field_names) + number_of_fields - 1)
    } else {
      number_of_fields = length(field_names)
      trailing_comma_string = ""
    }
    
    BAD_DMV_STRING = "\"DMV - Send Forms, Applications, Manuals\""
    BAD_DMV_STRING_ALT = "DMV - Send Forms\", Applications,\" Manuals\"\"\""
    BAD_DMV_STRING_STAND_IN = "\"DMV - Send Forms Applications Manuals\""
    
    for (i in bad_lines) {
      
      #Remove excess trailing commas
      # if (length(trailing_comma_string) > 0) {
      #   if(substr(lines_clean[i],
      #             nchar(lines_clean[i]) - nchar(trailing_comma_string) + 1,
      #             nchar(lines_clean[i])) == trailing_comma_string){
      #     lines_clean[i] = substr(lines_clean[i],
      #                             1,
      #                             nchar(lines[i]) - nchar(trailing_comma_string))
      #   }
      # }
      lines_clean[i] = gsub("(PHONE|WEB|XTERFACE|WALKIN),*$", "\\1", lines_clean[i])
      
      #Avoid bad strings with excess commas
      lines_clean[i] = gsub(BAD_DMV_STRING, BAD_DMV_STRING_STAND_IN, lines_clean[i])
      lines_clean[i] = gsub(BAD_DMV_STRING_ALT, BAD_DMV_STRING_STAND_IN, lines_clean[i])
      
      comma_matches = gregexpr(",", lines_clean[i])[[1]]
      
      
      # First, replace all qoutes with double quotes inside a quoted SERVICENOTES field
      quote_matches = gregexpr("\"", lines_clean[i])[[1]]
      
      if (quote_matches[1] > 0) {
        quote_matches_odd = quote_matches[seq(1, length(quote_matches), by = 2)]
        quote_matches_even = quote_matches[seq(2, length(quote_matches), by = 2)]
        
        # Remove commas inside quoted fields
        comma_matches = comma_matches[
          lapply(comma_matches, function(x){
            sum(x > quote_matches_odd & x < quote_matches_even) == 0
          }) %>% unlist
          ]
      }
      
      index_of_SERVICENOTES = which(field_names == "SERVICENOTES")
      beginning_of_SERVICENOTES = comma_matches[index_of_SERVICENOTES - 1] + 1
      end_of_SERVICENOTES = comma_matches[length(comma_matches) - number_of_fields + 1 + index_of_SERVICENOTES] - 1
      
      positions_to_replace = quote_matches
      if (quote_matches[1] > 0) {
        if(!(beginning_of_SERVICENOTES %in% quote_matches) |
           !(end_of_SERVICENOTES %in% quote_matches)) { # Need to add quotes, then
          str_sub(lines_clean[i],
                  beginning_of_SERVICENOTES-1,
                  beginning_of_SERVICENOTES-1) = ",\""
          end_of_SERVICENOTES = end_of_SERVICENOTES + 1
          str_sub(lines_clean[i],
                  end_of_SERVICENOTES+1,
                  end_of_SERVICENOTES+1) = "\","
          end_of_SERVICENOTES = end_of_SERVICENOTES + 1
          positions_to_replace = positions_to_replace + 1
        }
      }
      
      positions_to_replace = positions_to_replace[positions_to_replace > beginning_of_SERVICENOTES &
                                                    positions_to_replace < end_of_SERVICENOTES]
      
      
      for (j in seq_along(positions_to_replace)) {
        str_sub(lines_clean[i], positions_to_replace[j]+j-1, positions_to_replace[j]+j-1) = "\"\""
      }
      
      #Avoid bad strings with excess commas
      lines_clean[i] = gsub(BAD_DMV_STRING_STAND_IN, BAD_DMV_STRING, lines_clean[i])
      
      #Remove 'null' entries (make them blank)
      lines_clean[i] = gsub(",null", ",", lines_clean[i])
    }
    
    fname_prefix = substr(filename, 1, (nchar(filename)-4))
    fname_clean = paste0(path, "cleaned_from_scraped/", fname_prefix, "_clean.csv")
    write_lines(lines_clean, fname_clean)
    
    errors = problems(read_csv(fname_clean))
  } else {
    fname_prefix = substr(filename, 1, (nchar(filename)-4))
    fname_clean = paste0(path, "cleaned_from_scraped/", fname_prefix, "_clean.csv")
    write.csv(pre_load_data, fname_clean)
  }
  
  return(read_csv(fname_clean))
}


for (i in seq_along(files)) { #seq_along(files)
  # file_data_entries = read_csv(paste0("../../data/311/original_sources/octo/scraped_complete_files/",
  #                                     files[i]))
  file_data_entries = clean_and_load(files[i], path = "../../data/311/original_sources/octo/")
  if (nrow(consolidated_frame) > 0) {
    file_data_entries = file_data_entries %>% anti_join(consolidated_frame, by = "SERVICEREQUESTID")
  }
  consolidated_frame = rbind(consolidated_frame,
                             file_data_entries)
}
