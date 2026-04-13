require 'net/http'
require 'uri'
require 'json'

API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
API_KEY = "GEMINI_KEY"

prompt = "GÖREV: Bir üniversite yönetiminden gelmiş gibi görünen, resmi bir e-posta hazırla. FORMAT: JSON { \"subject\": \"...\", \"body\": \"...\" } SEBARYO: Hesap doğrulama. HEDEF: Ahmet Yılmaz. LİNK: http://test.com"

uri = URI("#{API_URL}?key=#{API_KEY}")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri)
request["Content-Type"] = "application/json"
request.body = {
  contents: [{ parts: [{ text: prompt }] }]
}.to_json

response = http.request(request)
puts "STATUS: #{response.code}"
puts "BODY: #{response.body}"
