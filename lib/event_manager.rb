require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody',  'legislatorLowerBody']
    ).officials
  rescue
    'you can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end 

def clean_phone_number(num)
  cleaned = num.gsub(/[()-+.]/,'').gsub(/\s+/, '').ljust(10, '0')[0..11]
  if cleaned.len == 11 && cleaned[0] == 1
    cleaned[1..11]
  elsif cleaned.len == 11
    cleaned[0..10]
  else
    cleaned
  end
end

def time_target_hour(date){
  t = DateTime.strptime(date, '%m/%d/%y %H:%M')
  t.hour
}

def time_target_day(date){
  t = DateTime.strptime(date, '%m/%d/%y %H:%M')
  t.wday
}

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers:  true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end


