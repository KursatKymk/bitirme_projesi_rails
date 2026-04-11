class ApplicationController < ActionController::Base
  # Sadece modern tarayıcılar
  allow_browser versions: :modern
end
