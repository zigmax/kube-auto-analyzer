#!/usr/bin/env ruby

require 'json'
#We are using HTTP Party here as rest-client has a C dependency which would bloat the image a lot.
require 'httparty'
require 'uri'

def is_port_open?(ip, port)
  begin
    Socket.tcp(ip, port, connect_timeout: 2)
  rescue Errno::ECONNREFUSED
    return false
  rescue Errno::ETIMEDOUT
    return false
  end
  true
end

target_url = ARGV[0]
results = Hash.new
port = URI.parse(target_url).port
token = File.open('/var/run/secrets/kubernetes.io/serviceaccount/token','r').read
if is_port_open?(nod, port)
    
  response = HTTParty.get(target_url, :verify => false, headers: {"Authorization" => "Bearer #{token}"})
  #Using this as an analog for whether we're cluster admin or not, bit naive
  #We don't use this as the main check as we don't want to return secrets in the evidence
  secrets_check = HTTParty.get(target_url + '/v1/secrets/', :verify => false, headers: {"Authorization" => "Bearer #{token}"})
  if response.forbidden? || secrets_check.forbidden?
    results[nod] = "Not Vulnerable - Request Forbidden"
  else
    results[nod] = response.body
  end
else
  results[nod] = "Not Vulnerable - Port Not Open"
end
puts JSON.generate(results)

