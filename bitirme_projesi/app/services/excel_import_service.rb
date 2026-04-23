require 'roo'

class ExcelImportService
  def initialize(campaign, file_path)
    @campaign = campaign
    @file_path = file_path
  end

  def import
    xlsx = Roo::Spreadsheet.open(@file_path)
    sheet = xlsx.sheet(0)
    
    # Assuming first row is header
    raw_header = sheet.row(1).map(&:to_s).map(&:downcase)
    
    # Normalize headers to match user specifications
    header_map = {}
    raw_header.each_with_index do |h, idx|
      # Remove any invisible characters or surrounding whitespace
      clean_h = h.strip.downcase
      
      case clean_h
      when 'email', /e-posta|mail/
        header_map['email'] = idx
      when 'full name', /full-name|full_name|ad soyad|isim|name/
        header_map['full_name'] = idx
      when 'role', /rol|gorev|gorevi|pozisyon/
        header_map['role'] = idx
      when 'department', /departman|birim|fakulte|bolum/
        header_map['department'] = idx
      end
    end
    
    (2..sheet.last_row).each do |i|
      row_data = sheet.row(i)
      
      email = row_data[header_map['email']]
      full_name = row_data[header_map['full_name']]
      role = row_data[header_map['role']]
      department = row_data[header_map['department']]
      
      next if email.blank?

      target = Target.find_or_create_by!(email: email.to_s.strip.downcase) do |t|
        t.full_name = full_name
        t.group_name = @campaign.target_group if Target::GROUPS.include?(@campaign.target_group)
      end

      # Update name if it changed or was nil
      target.update!(full_name: full_name) if full_name.present? && target.full_name != full_name

      # Link to campaign and store metadata (normalized)
      campaign_target = CampaignTarget.find_or_initialize_by(campaign: @campaign, target: target)
      campaign_target.custom_data = {
        'role' => role,
        'department' => department
      }
      campaign_target.save!
    end
  end
end
