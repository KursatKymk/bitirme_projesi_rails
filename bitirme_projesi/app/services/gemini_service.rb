require 'net/http'
require 'uri'
require 'json'

class GeminiService
  # Switched to Gemini 2.5 Flash Lite for optimized speed and cost
  API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent"

  def initialize
    @api_key = Rails.application.credentials.dig(:gemini, :api_key) || ENV["GEMINI_API_KEY"]
  end

  def generate_personalized_email(campaign, target, link)
    custom_data = target.campaign_targets.find_by(campaign: campaign)&.custom_data || {}
    language = campaign.email_language || "English"
    use_custom = campaign.use_custom_scenario

    prompt_instructions = if use_custom
      "REHBER SENARYO: #{campaign.scenario_prompt}\nBu senaryoyu temel alarak kişiselleştirilmiş bir içerik üret."
    else
      "OTONOM MOD: Bir üniversite yönetiminden gelebilecek, gerçekçi ve idari bir phishing konusu yarat."
    end

    prompt = <<~PROMPT
      GÖREV: Aşağıdaki bilgilere dayanarak, bir üniversite yönetiminden gelmiş gibi görünen, son derece resmi, kurumsal ve KİŞİYE ÖZEL bir oltalama (phishing) e-postası hazırla.
      
      HEDEF KİŞİ: #{target.full_name}
      ROL: #{custom_data['role'] || custom_data['rol']}
      DEPARTMAN: #{custom_data['department'] || custom_data['departman']}
      HEDEF LİNK: #{link}
      
      [!!!] KESİN DİL KURALI (MUTLAKA UYULACAK) [!!!]
      Çıktısı verilecek e-postanın KONU ve GÖVDE kısımları KESİNLİKLE ve SADECE [ #{language.upcase} ] dilinde yazılmalıdır.
      Örneğin dil 'English' ise metin tamamen kusursuz akademik İngilizce olmalı, dil 'Turkish' ise Türkçe olmalıdır. Senaryo kuralları Türkçe yazılmış olsa dahi ÇIKTI METNİ SADECE İSTENEN DİLDE (#{language.upcase}) OLMALIDIR. Hiçbir yabancı kelime sızmamalıdır.

      KESİN KURAL 1 (BAĞLAMSAL YARATICILIK): E-posta, hedefin departmanına ve rolüne UYGUN bir idari konuyu işlemelidir. 
      - Örn: Hedef 'Kütüphane' ise gecikmiş kitap iadesi veya yeni veritabanı erişimi hakkında yaz. 
      - Örn: Hedef 'İdari Personel' ise zorunlu İSG eğitimi, yıllık izin kotası veya otopark kartı aktivasyonu hakkında yaz.
      - ASLA sadece "sistem güncellemesi" gibi yüzeysel ve genel konuları kullanma. Her seferinde FARKLI bir senaryo uydur.

      KESİN KURAL 2 (GERÇEKÇİ BİRİM): Gönderen olarak aşağıdaki gerçek üniversite birimlerinden sadece birini seç ve konuyu o birimle ilişkilendir:
      [Bilgi Teknolojileri ve Dijital Dönüşüm Direktörlüğü, İnsan Kaynakları Direktörlüğü, Satın Alma Ofisi, Kurumsal İletişim ve Tanıtım Direktörlüğü, Kütüphane Direktörlüğü, Mezunlar Ofisi, Yapı Teknik ve Operasyon Direktörlüğü, Mali Kontrol Direktörlüğü, Finans Kaynakları Yönetimi Birimi, Öğrenci İşleri Direktörlüğü, Öğrenim ve Öğretimde Mükemmeliyet Merkezi (CELT)].

      KESİN KURAL 3 (ANTI-SPAM DİLİ):
      - "Acil", "Hemen", "Önemli!", "Giriş yapmazsanız hesabınız silinir" gibi klasik oltalama kelimelerinden kaçın.
      - Soğukkanlı, bilgilendirici ve profesyonel bir kurumsal dil kullan. 
      - Linki metnin içine "Detayları sistem üzerinden görüntüleyebilirsiniz" gibi doğal bir şekilde yedir.

      #{prompt_instructions}
      
      FORMAT: Sadece JSON çıktısı ver. Örn: { "subject": "...", "body": "..." }
    PROMPT

    raw_response = make_api_request(prompt)
    parsed = parse_gemini_json(raw_response)
    
    if parsed && parsed["subject"] && parsed["body"]
      parsed
    else
      if language.downcase == 'english'
        { "subject" => "Information: Corporate System Access", "body" => "Dear #{target.full_name}, as per our corporate security policies, you are required to sign in via #{link}." }
      else
        { "subject" => "Bilgilendirme: Kurumsal Sistem Erişimi", "body" => "Sayın #{target.full_name}, kurumsal güvenlik politikalarımız gereği #{link} üzerinden oturum açmanız beklenmektedir." }
      end
    end
  rescue => e
    Rails.logger.error "Gemini Email Generation Error: #{e.message}"
    if language.downcase == 'english'
      { "subject" => "System Notification", "body" => "Dear #{target.full_name}, please access the details here: #{link}" }
    else
      { "subject" => "Sistem Bildirimi", "body" => "Sayın #{target.full_name}, detaya buradan ulasin: #{link}" }
    end
  end

  def evaluate_spam_score(subject, body)
    return { "score" => -1, "analysis" => "İçerik eksik, analiz yapılamadı." } if subject.blank? || body.blank?

    prompt = <<~PROMPT
      GÖREV: Spam/Phishing Analizi (SCL Skoru).
      Aşağıdaki içeriği 0-9 arası puanla (0:Temiz, 9:Kesin Phishing).
      
      ÖNEMLİ NOT (DEMO MODU): Bağlantıların 'localhost' içermesi veya 'http' olması şu anki test ortamı için NORMALDİR. 
      Lütfen 'localhost' veya 'http' protokolünü bir spam belirtisi veya düşük güvenlik faktörü olarak DİKKATE ALMA. 
      Sadece metnin diline, kurumsallığına ve aldatma/manipülasyon (sosyal mühendislik) tekniklerine odaklan.

      KONU: #{subject}
      İÇERİK: #{body}
      FORMAT: Sadece JSON. { "score": 4, "analysis": "..." }
    PROMPT

    raw_response = make_api_request(prompt)
    parsed = parse_gemini_json(raw_response)

    if parsed && parsed["score"]
      parsed
    else
      { "score" => -1, "analysis" => "API Hatası veya JSON ayrıştırma sorunu." }
    end
  rescue => e
    Rails.logger.error "Gemini Spam Evaluation Error: #{e.message}"
    { "score" => -1, "analysis" => "Sistem hatası oluştu." }
  end

  private

  def make_api_request(prompt, retries = 3)
    attempts = 0
    begin
      attempts += 1
      uri = URI("#{API_URL}?key=#{@api_key}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 60 # Zaman aşımını 60 saniyeye çıkardım

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = { contents: [{ parts: [{ text: prompt }] }] }.to_json

      response = http.request(request)
      
      if response.code == "200"
        json_resp = JSON.parse(response.body)
        return json_resp.dig("candidates", 0, "content", "parts", 0, "text")
      else
        raise "HTTP #{response.code}: #{response.body}"
      end
    rescue => e
      if attempts < retries
        Rails.logger.warn "Gemini API Attempt #{attempts} failed. Reason: #{e.message}. Retrying in #{2**attempts}s..."
        sleep(2**attempts)
        retry
      end
      nil
    end
  end

  def parse_gemini_json(text)
    clean_text = text.gsub("```json", "").gsub("```", "").strip
    JSON.parse(clean_text)
  rescue
    nil
  end
end
