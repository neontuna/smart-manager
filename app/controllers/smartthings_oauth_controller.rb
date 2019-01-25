require 'oauth2'
require 'httparty'

class SmartthingsOauthController < ApplicationController
  OPTIONS = {
    site: 'https://graph.api.smartthings.com',
    authorize_url: '/oauth/authorize',
    token_url: '/oauth/token'
  }
  REDIRECT_URI = 'http://localhost:3000/smartthings_oauth/callback'
  CLIENT_ID = Rails.application.credentials[Rails.env.to_sym][:st_client_id]
  CLIENT_SECRET = Rails.application.credentials[Rails.env.to_sym][:st_client_secret]
  ENDPOINTS_URI = 'https://graph.api.smartthings.com/api/smartapps/endpoints'

  def create
    token = get_smartthings_token(params[:code])
    endpoint = get_smartthings_endpoints(token)
    @listing = Listing.find(params[:state])

    if @listing.update(smartthings_token: token, smartthings_endpoint: endpoint)
      flash[:success] = "Successfully connected to Smartthings, syncing devices now..."
      redirect_to @listing
    end
  end

  def get_smartthings_token(callback_code)
    client = OAuth2::Client.new(CLIENT_ID, CLIENT_SECRET, OPTIONS)
    handle_http_exception do
      response = client.auth_code.get_token(callback_code, redirect_uri: REDIRECT_URI, scope: 'app')
      response.token
    end
  end

  def get_smartthings_endpoints(auth_token)
    handle_http_exception do
      response = HTTParty.get(
        ENDPOINTS_URI,
        headers: {
          Authorization: "Bearer #{auth_token}"
        }
      )

      if response.code == 200
        response.parsed_response[0]['uri']
      else
        puts "error #{response.parsed_response}"
      end
    end
  end

  def get_devices_for(listing_id)
    listing = Listing.find(listing_id)

    handle_http_exception do
      response = HTTParty.get(
        "#{listing.smartthings_endpoint}/devices",
        headers: {
          Authorization: "Bearer #{listing.smartthings_token}"
        }
      )

      if response.code == 200
        response.parsed_response
      else
        puts "error #{response.parsed_response}"
      end
    end    
  end

  def update_devices_for(listing_id)
    devices = get_devices_for(listing_id)
    listing = Listing.find(listing_id)

    devices.each do |remote_device|
      listing.devices.where(smartthings_id: remote_device['id']).first_or_create do |local_device|
        local_device.update(
          display_name: remote_device['name'],
          hardware_type: remote_device['type'],
          status: remote_device['value'],
          meta: remote_device['meta']
        )
      end
    end
  end

  def handle_http_exception
    yield
  rescue HTTParty::Error, SocketError, Net::OpenTimeout, OAuth2::Error => error
    puts error
  end
end