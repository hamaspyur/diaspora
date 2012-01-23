if AppConfig[:image_redirect_url].present?
  require 'rack-rewrite'

  Rails.application.config.middleware.insert_before(3, Rack::Rewrite) do
    pp AppConfig[:images_redirect_url]
    
    r301 '/uploads/images/(.*)', "#{AppConfig[:image_redirect_url]}/uploads/images/$1"
  end
end