require 'csv'
require 'httparty'
require 'pry'

data_rows = []

csv_path = "/Users/zohebnensey/dev/side_projects/the-rat-hack/restaurant_code_violations/opentable_crosswalk.csv"

CSV.foreach(csv_path, headers: true) do |csv_row|
  begin
    opentable_url = "http://opentable.herokuapp.com/api/restaurants/"+csv_row["OpenTableID"]
    csv_row["OpenTable URL"] = opentable_url
    api_response = HTTParty.get(opentable_url)
    csv_row["Name"] = api_response["name"]
    csv_row["Address"] = api_response["address"]
    csv_row["City"] = api_response["city"]
    csv_row["State"] = api_response["state"]
    csv_row["Zip"] = api_response["postal_code"]
    csv_row["Phone"] = api_response["phone"]
    csv_row["Latitude"] = api_response["lat"]
    csv_row["Longitude"] = api_response["lng"]
    data_rows << csv_row
  rescue Exception=>e
    binding.pry
    next
  end
end

CSV.open("csv_with_urls.csv","w") do |csv|
  csv << ["PermitID","OpenTableID","OpenTable URL","Name","Address","City","State","Zip","Phone","Latitude","Longitude"]
  data_rows.each do |dr|
    csv << dr
  end
end