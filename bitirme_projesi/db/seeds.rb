# ---------------------------------------------------------------------------
# Seed: React dashboard'unda görülen mock verilere yakın bir set oluşturur
# ---------------------------------------------------------------------------

puts "==> Clearing existing data"
Credential.delete_all
EmailEvent.delete_all
Target.delete_all
Campaign.delete_all

puts "==> Creating targets"
first_names = %w[Ahmet Mehmet Ayşe Fatma Ali Zeynep Can Elif Emre Selin Burak Deniz Mert Cem Ece]
last_names  = %w[Yılmaz Kaya Demir Çelik Şahin Öztürk Aydın Arslan Doğan Yıldız]
60.times do |i|
  Target.create!(
    email: "student#{i + 1}@khas.edu.tr",
    full_name: "#{first_names.sample} #{last_names.sample}",
    group_name: %w[undergraduate graduate staff].sample
  )
end
targets = Target.all.to_a

puts "==> Creating campaigns"
campaigns_data = [
  {
    name: "Waitlist Verification Phish",
    target_group: "all",
    prompt_type: "urgency",
    scenario_prompt: "Create a highly plausible enrollment failure email to undergraduate students with a 'waitlisted' status, asking them to immediately verify their details via a secure portal to prevent course cancellation. Emphasize urgency and professional tone.",
    email_subject: "Waitlist Verification - Action Required",
    status: "sent",
    sent_at: 3.days.ago
  },
  {
    name: "Scholarship Update",
    target_group: "graduate",
    prompt_type: "authority",
    scenario_prompt: "Notify graduate students that their scholarship is under review and immediate action is required.",
    email_subject: "Scholarship Review - Immediate Action",
    status: "sent",
    sent_at: 6.days.ago
  },
  {
    name: "Staff HR Portal Migration",
    target_group: "staff",
    prompt_type: "curiosity",
    scenario_prompt: "Staff HR portal is being migrated. Please re-verify credentials on the new portal.",
    email_subject: "HR Portal Migration Notice",
    status: "sent",
    sent_at: 10.days.ago
  },
  {
    name: "Exam Results Notification",
    target_group: "all",
    prompt_type: "urgency",
    scenario_prompt: "Exam results are being held because of missing verification.",
    email_subject: "Your Exam Results Are Ready",
    status: "draft"
  }
]

campaigns_data.each do |data|
  c = Campaign.create!(data)
  next if c.status == "draft"

  sent     = rand(200..500)
  opened   = (sent * rand(0.55..0.85)).to_i
  clicked  = (opened * rand(0.25..0.45)).to_i
  captured = (clicked * rand(0.3..0.6)).to_i

  c.update!(
    emails_sent: sent,
    emails_opened: opened,
    links_clicked: clicked,
    creds_captured: captured
  )

  captured.times do
    t = targets.sample
    Credential.create!(
      campaign: c,
      target: t,
      email: t.email,
      password: %w[Password123! khas2024 student!234 Kadir.Has1 deneme1234].sample,
      ip_address: "10.0.0.#{rand(2..254)}",
      user_agent: "Mozilla/5.0",
      captured_at: c.sent_at + rand(1..48).hours
    )
  end
end

puts "==> Done."
puts "   Campaigns:   #{Campaign.count}"
puts "   Targets:     #{Target.count}"
puts "   Credentials: #{Credential.count}"
