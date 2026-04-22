module Admin
  class DashboardController < BaseController
    def index
      @total_emails_sent = Campaign.sum(:emails_sent)
      @total_clicks      = Campaign.sum(:links_clicked)
      @total_captured    = Campaign.sum(:creds_captured)

      @ctr = @total_emails_sent.zero? ? 0.0 :
               (@total_clicks.to_f / @total_emails_sent * 100).round(1)

      @breach_rate = @total_emails_sent.zero? ? 0.0 :
               (@total_captured.to_f / @total_emails_sent * 100).round(1)

      @credential_submission_rate = @breach_rate
      @campaigns = Campaign.recent.limit(10)

      # Clicks over the last 7 days (Mockup/calculation if actual timestamp logic is complex, 
      # but we have EmailEvent which has occurred_at or created_at)
      recent_clicks = EmailEvent.where(event_type: 'clicked', created_at: 7.days.ago..Time.current)
      @clicks_by_day = (0..6).to_a.reverse.map do |i|
        day = i.days.ago.to_date
        { x: day.strftime("%b %d"), y: recent_clicks.count { |e| e.created_at.to_date == day } }
      end

      # Vulnerability by department
      submissions = EmailEvent.where(event_type: 'submitted').includes(target: :campaign_targets)
      dept_counts = Hash.new(0)
      submissions.each do |sub|
        # En idealinde Event içindeki hedeften veya CT üzerinden departmanı alırız
        dept = sub.target.campaign_targets.last&.custom_data&.dig('departman') || 'Bilinmeyen'
        dept_counts[dept] += 1
      end
      
      @vuln_by_dept = dept_counts.sort_by { |_, v| -v }.first(5).to_h

      # Eğer hiç data yoksa (demo için) örnek data göster:
      if @vuln_by_dept.empty?
        @vuln_by_dept = {
          "IT & Yazılım" => 0,
          "Kütüphane" => 0,
          "Öğrenci İşleri" => 0,
          "İnsan Kaynakları" => 0 
        }
      end

      # Real-Time Activity Feed
      @recent_activity = EmailEvent.includes(:target, :campaign).order(created_at: :desc).limit(15)
    end
  end
end
