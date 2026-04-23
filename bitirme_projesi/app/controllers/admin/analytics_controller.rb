module Admin
  class AnalyticsController < BaseController
    def index
      @campaigns = Campaign.where(status: "sent").recent
      @total_sent    = Campaign.sum(:emails_sent)
      @total_opened  = Campaign.sum(:emails_opened)
      @total_clicked = Campaign.sum(:links_clicked)
      @total_creds   = Campaign.sum(:creds_captured)

      # 1. Trigger Effectiveness (Strategy analysis)
      # Ensure all strategies exist even if 0 results
      @strategy_data = Campaign::PROMPTS.each_with_object({}) { |p, h| h[p] = { ctr: 0, breach: 0 } }
      
      Campaign.where(status: "sent").group(:prompt_type).select(
        "prompt_type, 
         AVG(CASE WHEN emails_sent > 0 THEN CAST(links_clicked AS FLOAT) / emails_sent * 100 ELSE 0 END) as avg_ctr,
         AVG(CASE WHEN emails_sent > 0 THEN CAST(creds_captured AS FLOAT) / emails_sent * 100 ELSE 0 END) as avg_breach"
      ).each { |c| @strategy_data[c.prompt_type] = { ctr: c.avg_ctr.to_f.round(1), breach: c.avg_breach.to_f.round(1) } }

      # 2. Hourly Risk Heatmap (Peak vulnerability times)
      @hourly_data = EmailEvent.where(event_type: ['clicked', 'submitted']).group("strftime('%H', created_at)").count
      @hourly_series = (0..23).map { |h| @hourly_data[h.to_s.rjust(2, '0')] || 0 }

      # 3. Departmental Risk Radar
      # Pre-populate with all known groups
      @group_stats = Target::GROUPS.each_with_object({}) { |g, h| h[g] = { click: 0, breach: 0 } }
      
      Target.joins(:email_events).group(:group_name).select(
        "group_name, 
         COUNT(DISTINCT CASE WHEN email_events.event_type = 'clicked' THEN email_events.id END) as click_count,
         COUNT(DISTINCT CASE WHEN email_events.event_type = 'submitted' THEN email_events.id END) as sub_count"
      ).each { |g| @group_stats[g.group_name] = { click: g.click_count, breach: g.sub_count } if @group_stats.key?(g.group_name) }

      # 4. Forensic Layer: Language Effectiveness
      @language_data = Campaign::LANGUAGES.each_with_object({}) { |l, h| h[l] = { ctr: 0, breach: 0 } }
      Campaign.where(status: "sent").group(:email_language).select(
        "email_language,
         AVG(CASE WHEN emails_sent > 0 THEN CAST(links_clicked AS FLOAT) / emails_sent * 100 ELSE 0 END) as avg_ctr,
         AVG(CASE WHEN emails_sent > 0 THEN CAST(creds_captured AS FLOAT) / emails_sent * 100 ELSE 0 END) as avg_breach"
      ).each { |c| @language_data[c.email_language] = { ctr: c.avg_ctr.to_f.round(1), breach: c.avg_breach.to_f.round(1) } if @language_data.key?(c.email_language) }

      # 5. Forensic Layer: 30-Day Breach Timeline
      # Aggregate credential submissions over time
      @timeline_raw = EmailEvent.where(event_type: 'submitted')
                               .where("created_at >= ?", 30.days.ago)
                               .group("date(created_at)")
                               .count
      @timeline_labels = (30.days.ago.to_date..Date.current).map { |d| d.strftime("%d %b") }
      @timeline_series = (30.days.ago.to_date..Date.current).map { |d| @timeline_raw[d.to_s] || 0 }

      # 6. Forensic Layer: Top 5 High-Risk Targets
      # Identify targets with multiple clicks or submissions
      @top_targets = Target.joins(:email_events)
                           .where(email_events: { event_type: ['clicked', 'submitted'] })
                           .group("targets.id, targets.email")
                           .select("targets.email, 
                                   COUNT(CASE WHEN email_events.event_type = 'clicked' THEN 1 END) as click_count,
                                   COUNT(CASE WHEN email_events.event_type = 'submitted' THEN 1 END) as breach_count")
                           .order("breach_count DESC, click_count DESC")
                           .limit(5)

      # 7. Standard Funnel Series (Legacy but refined)
      @series = @campaigns.map do |c|
        {
          label: c.name,
          sent: c.emails_sent,
          opened: c.emails_opened,
          clicked: c.links_clicked,
          captured: c.creds_captured
        }
      end
    end
  end
end
