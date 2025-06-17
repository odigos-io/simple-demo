
class ApplicationController < ActionController::API
  COUNTRIES = [
    { ticker: "ILS", origin: "Israel", flag: "🇮🇱" },
    { ticker: "EUR", origin: "European Union", flag: "🇪🇺" },
    { ticker: "GBP", origin: "United Kingdom", flag: "🇬🇧" },
    { ticker: "USD", origin: "United States of America", flag: "🇺🇸" },
  ]

  def index
    render json: {
      message: "Hello from Ruby on Rails!"
    }
  end

  def location
    loc = params[:loc].to_s.strip
    country = nil

    for c in COUNTRIES
      if c[:ticker]&.upcase == loc.upcase || c[:origin]&.upcase == loc.upcase
        country = c
      end
    end

    if country
      render json: country, content_type: 'application/json'
    else
      render json: { error: "Country not found" }, content_type: 'application/json', status: :not_found
    end
  end
end
