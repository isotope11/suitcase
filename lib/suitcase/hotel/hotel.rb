module Suitcase
  class EANException < Exception
    def initialize(message)
      super(message)
    end
  end

  class Hotel
    extend Suitcase::Helpers

    AMENITIES = { pool: 1,
                  fitness_center: 2,
                  restaurant: 3,
                  children_activities: 4,
                  breakfast: 5,
                  meeting_facilities: 6,
                  pets: 7,
                  wheelchair_accessible: 8,
                  kitchen: 9 }

    attr_accessor :id, :name, :address, :city, :min_rate, :max_rate, :amenities, :country_code, :high_rate, :low_rate, :longitude, :latitude, :rating, :postal_code, :supplier_type, :image_urls

    def initialize(info)
      info.each do |k, v|
        send (k.to_s + "=").to_sym, v
      end
    end

    def self.find(info)
      if info[:id]
        find_by_id(info[:id])
      else
        find_by_info(info)
      end
    end

    def self.find_by_id(id)
      url = url(:info, { hotelId: id })
      raw = parse_response(url)
      hotel_data = parse_information(raw)
      Hotel.new(hotel_data)
    end

    def self.find_by_info(info)
      params = info
      params["numberOfResults"] = params[:results] ? params[:results] : 10
      params.delete(:results)
      params["destinationString"] = params[:location]
      params.delete(:location)
      if params[:amenities]
        params[:amenities].inject("") { |old, new| old + AMENITIES[new].to_s + "," }
        amenities =~ /^(.+),$/
        amenities = $1
      end
      params["minRate"] = params[:min_rate] if params[:min_rate]
      params["maxRate"] = params[:max_rate] if params[:max_rate]
      params[:amenities] = amenities
      hotels = []
      parsed = parse_response(url(:list, params))
      handle_errors(parsed)
      split(parsed).each do |hotel_data|
        hotels.push Hotel.new(parse_information(hotel_data))
      end
      hotels
    end

    def self.parse_information(parsed)
      handle_errors(parsed)
      summary = parsed["hotelId"] ? parsed : parsed["HotelInformationResponse"]["HotelSummary"]
      parsed_info = { id: summary["hotelId"], name: summary["name"], address: summary["address1"], city: summary["city"], postal_code: summary["postalCode"], country_code: summary["countryCode"], rating: summary["hotelRating"], high_rate: summary["highRate"], low_rate: summary["lowRate"], latitude: summary["latitude"].to_f, longitude: summary["longitude"].to_f }
      if images(parsed)
        parsed_info[:image_urls] = images(parsed)
      end
      parsed_info
    end

    def self.images(parsed)
      return nil
    end

    # Bleghh. so ugly. #needsfixing
    def self.handle_errors(info)
      if info["HotelRoomAvailabilityResponse"] && info["HotelRoomAvailabilityResponse"]["EanWsError"]
        message = info["HotelRoomAvailabilityResponse"]["EanWsError"]["presentationMessage"]
      elsif info["HotelListResponse"] && info["HotelListResponse"]["EanWsError"]
        message = info["HotelListResponse"]["EanWsError"]["presentationMessage"]
      elsif info["HotelInformationResponse"] && info["HotelInformationResponse"]["EanWsError"]
        message = info["HotelInformationResponse"]["EanWsError"]["presentationMessage"]
      end
      raise EANException.new(message) if message
   end

    def self.split(parsed)
      hotels = parsed["HotelListResponse"]["HotelList"]
      hotels["HotelSummary"]
    end

    def rooms(info)
      params = { rooms: [{children: 0, ages: []}] }.merge(info)
      params[:rooms].each_with_index do |room, n|
        params["room#{n+1}"] = (room[:children] == 0 ? "" : room[:children].to_s + ",").to_s + room[:ages].join(",").to_s
      end
      params["arrivalDate"] = info[:arrival]
      params["departureDate"] = info[:departure]
      params.delete(:arrival)
      params.delete(:departure)
      params["hotelId"] = @id
      parsed = Hotel.parse_response(Hotel.url(:avail, params))
      Hotel.handle_errors(parsed)
      hotel_id = parsed["HotelRoomAvailabilityResponse"]["hotelId"]
      rate_key = parsed["HotelRoomAvailabilityResponse"]["rateKey"]
      supplier_type = parsed["HotelRoomAvailabilityResponse"]["HotelRoomResponse"][0]["supplierType"]
      Room.new(rate_key, hotel_id, supplier_type)
    end

    def payment_options
      options = []
      types_raw = JSON.parse Hotel.hit(url(:paymentInfo, true, true, {}))
      types_raw["HotelPaymentResponse"].each do |raw|
        types = raw[0] != "PaymentType" ? [] : raw[1]
        types.each do |type|
          options.push PaymentOption.new(type["code"], type["name"])
        end
      end
      options
    end
  end
end