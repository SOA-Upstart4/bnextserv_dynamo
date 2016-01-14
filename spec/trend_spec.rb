require_relative 'spec_helper'
require_relative 'spec_answers'
require 'json'
require 'dynamoid'

describe 'Checking newest feeds' do
  before do
    Trend.delete_all
  end

  it 'should return tech & marketing feeds' do
    header = { 'CONTENT_TYPE' => 'application/json' }
    body = {
      description: 'Check tech and marketing feeds',
      categories: %w(marketing tech) }

    # Check redirect URL from post request
    post '/api/v1/trend', body.to_json, header
    last_response.must_be :redirect?
    next_location = last_response.location
    next_location.must_match %r{api\/v1\/trend\/\w+}

    # Check if request parameters are stored in ActiveRecord data store
    trend_id = next_location.scan(%r{trend\/(\w+)}).flatten[0].to_s
    save_trend = Trend.where(:id => "#{trend_id}").all
    save_trend.size.must_equal 0

    # Check if redirect works
    VCR.use_cassette('post_trend') do
      follow_redirect!
    end
    last_request.url.must_match %r{api\/v1\/trend\/\w+}

  end

  it 'should return 400 for bad JSON formatting' do
    header = { 'CONTENT_TYPE' => 'application/json' }
    body = random_str(15)
    post '/api/v1/trend', body, header
    last_response.must_be :bad_request?
  end

  it 'should return 404 for unknown category type' do
    header = { 'CONTENT_TYPE' => 'application/json' }
    body = {
      description: 'Check invalid categories type',
      categories: [random_str(10)] }
    post '/api/v1/trend', body.to_json, header
    last_response.must_be :redirect?
    VCR.use_cassette('post_random') do
      follow_redirect!
    end
    last_response.body.must_match("")
  end
end
