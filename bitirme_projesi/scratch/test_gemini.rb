require 'net/http'
require 'uri'
require 'json'
require 'dotenv'

# .env dosyasını manuel yükleyelim
Dotenv.load('.env')

api_key = ENV['GEMINI_API_KEY']
# Model ismini tam olarak kontrol edelim
model = "gemini-3-flash-preview" 
api_url = "https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent?key=#{api_key}"

puts "--- Gemini API Bağlantı Testi ---"
puts "Kullanılan Model: #{model}"
puts "API Anahtarı Mevcut mu?: #{api_key ? 'Evet (' + api_key[0..5] + '...)' : 'Hayır'}"

uri = URI(api_url)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri)
request["Content-Type"] = "application/json"
request.body = { contents: [{ parts: [{ text: "Merhaba, bağlantı testi." }] }] }.to_json

begin
  response = http.request(request)
  puts "HTTP Durum Kodu: #{response.code}"
  
  if response.code == "200"
    puts "BAŞARILI: API yanıt verdi!"
    puts JSON.parse(response.body).dig("candidates", 0, "content", "parts", 0, "text")
  else
    puts "HATA: API hata döndürdü."
    puts "Yanıt Gövdesi: #{response.body}"
  end
rescue => e
  puts "SİSTEM HATASI: #{e.message}"
end
