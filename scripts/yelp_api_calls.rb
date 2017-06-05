require 'csv'
require 'yelp'
require 'pry'
require 'yaml'

data_rows = []

csv_path = "restaurant_code_violations/yelp_crosswalk.csv"

yelp_config = YAML.load_file("yelp_keys.yml")

binding.pry

client = Yelp::Client.new({ consumer_key: yelp_config["consumer_key"],
                            consumer_secret: yelp_config["consumer_secret"] ,
                            token: yelp_config["token"],
                            token_secret: yelp_config["token_secret"]
                          })

CSV.foreach(csv_path, headers: true) do |csv_row|
  begin
  yelp_id = csv_row["YelpID"]
  next if yelp_id.nil?
    api_response = client.business(yelp_id)
    csv_row["Name"] = api_response.business.name rescue ""
    csv_row["Address"] = api_response.business.location.address.join(" ") rescue ""
    csv_row["City"] = api_response.business.location.city rescue ""
    csv_row["State"] = api_response.business.location.state_code rescue ""
    csv_row["Zip"] = api_response.business.location.postal_code rescue ""
    csv_row["Phone"] = api_response.phone rescue ""
    csv_row["Latitude"] = api_response.business.location.coordinate.latitude rescue ""
    csv_row["Longitude"] = api_response.business.location.coordinate.longitude rescue ""
    data_rows << csv_row
  rescue Exception=>e
    puts "#{e} - #{csv_row}"
    next
  end
end

CSV.open("yelp_data_from_calls.csv", "w") do |csv|
  csv << ["PermitID","YelpID","Name","Address","City","State","Zip","Phone","Latitude","Longitude"]
  data_rows.each do |dr|
    csv << dr
  end
end