require 'rubygems'
require 'httparty'
require 'json'
require 'pp'

API_KEY = 'e1b4ea3b9f0b8b1a689df3bc506901a7152fac07'
JOB = '3452'
ANSWER_FIELDS = ['business_url', 'business_has_website']
UPPER_BOUND = 1.0
LOWER_BOUND = 0.8
NUM_UNITS = 10

class CrowdFlower
  include HTTParty
  format :json
end

def copy_gold_from_job(job_id)
  response = CrowdFlower.get(
    "https://api.crowdflower.com/v1/jobs/#{job_id}/copy.json",
    :body =>
      {
        'gold' => true,      
        'key' => API_KEY
      }
    )
  JSON.parse(response.body)['id']
end

def copy_units_to(job_id)
  response = CrowdFlower.get(
    "https://api.crowdflower.com/v1/jobs/#{JOB}/judgments.json",
    :body =>
      {
        'key' => API_KEY
      }
    )
  units = JSON.parse(response.body)
  pp units.length
  units.delete_if do |k,v| 
    !v['_agreement'].between?(LOWER_BOUND, UPPER_BOUND) or
    v.to_s =~ /gold/
  end
  pp units.length
  units.first(NUM_UNITS).each do |pair|
    unit = pair[1]
    unit.delete_if {|k,v| k =~ /^_/ }
    unit.each_key do |key| 
      if ANSWER_FIELDS.include?(key)
        unit['original_' + key] = unit[key]
        unit.delete(key)
      end
    end
    copy = CrowdFlower.post(
      "https://api.crowdflower.com/v1/jobs/#{job_id}/units",
      :body =>
        {
          'key' => API_KEY,
          'unit' => { 'data' => unit }
        }
      )
    pp JSON.parse(copy.body)
  end
end

new_job = copy_gold_from_job(JOB)
puts new_job
copy_units_to(new_job)