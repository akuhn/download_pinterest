require %(date)
require %(json)
require %(net/http)
require %(uri)

require_relative 'cache'
require_relative 'extensions'


class Client
  attr_reader :cache

  def initialize(cache_fname, partition = Date.today.iso8601)
    @cache = Cache.new(cache_fname, partition || Date.today.iso8601)
  end

  def each_board
    return enum_for(:each_board) unless block_given?

    each_board_page do |data|
      data.resource_response.data.each do |each|
        yield each
      end
    end
  end

  def each_pin
    return enum_for(:each_pin) unless block_given?

    each_board do |board|
      each_board_pin_page(board) do |data|
        data.resource_response.data.each do |each|
          yield each
        end
      end
    end
  end

  def get_boards_data
    @data ||= JSON.parse(self.get_boards_json)
  end

  def get_boards_json(bookmark = nil)
    key = ['boards', get_username, bookmark].compact.join(':')
    cache.fetch(key) do
      puts "Cursor #{key}"
      fetch_boards(get_username, bookmark, get_cookie)
    end
  end

  def delete_pin(id)
    response = fetch_pin_deletion(id, get_cookie)
    abort "ERR: could not delete pin #{id} (code #{response.code})" unless response.is_a?(Net::HTTPSuccess)

    response
  end

  private

  def each_board_page
    bookmark = nil

    loop do
      data = JSON.parse(get_boards_json(bookmark))
      yield data

      bookmark = get_bookmark(data)
      break if !bookmark || bookmark == '-end-'
    end
  end

  def each_board_pin_page(board)
    bookmark = nil

    loop do
      data = JSON.parse(get_board_pins_json(board, bookmark))
      yield data

      bookmark = get_bookmark(data)
      break if !bookmark || bookmark == '-end-'
    end
  end

  def get_board_pins_json(board, bookmark)
    key = ['pins', board['id'], bookmark].compact.join(':')
    cache.fetch(key) do
      puts "Cursor #{key}"
      fetch_board_pins(board, bookmark, get_cookie)
    end
  end

  def get_cookie
    @cookie ||= read_cookie(get_cookie_file)
  end

  def get_cookie_file
    @cookie_file ||= begin
      file = $flags.get(:cookie_file) || 'default_curl.txt'
      abort("Cookie file not found: #{file}") unless File.exist?(file)
      file
    end
  end

  def get_username
    @username ||= begin
      username = read_username(get_cookie_file)
      abort("Could not detect username in #{get_cookie_file}") unless username
      username
    end
  end

  def get_bookmark(data)
    data.dig('resource', 'options', 'bookmarks')&.first ||
      data.dig('resource_response', 'bookmark')
  end

  def read_cookie(file)
    text = File.read(file).strip
    abort("Cookie content is empty in #{file}") if text.empty?

    text.match(/(?:^|\s)-(?:b|--cookie)\s+(['"])(.*?)\1/m)&.captures&.last || text
  end

  def read_csrf(cookie)
    cookie.split(';').map(&:strip).find { |piece| piece.start_with?('csrftoken=') }&.split('=', 2)&.last
  end

  def read_username(file)
    text = File.read(file)
    text[/%22username%22%3A%22([^%]+)%22/, 1]
  end

  def fetch_boards(username, bookmark, cookie)
    csrf = read_csrf(cookie)
    uri = URI('https://www.pinterest.com/resource/BoardsResource/get/')
    options = {
      username: username,
      page_size: 25,
      sort: 'last_pinned_to',
      privacy_filter: 'all',
      field_set_key: 'profile_grid_item',
      filter_stories: false,
      group_by: 'mix_public_private',
      include_archived: true,
      redux_normalize_feed: true,
      filter_all_pins: true,
    }
    options[:bookmarks] = [bookmark] if bookmark

    params = {
      source_url: "/#{username}/",
      data: { options: options, context: {} }.to_json,
      _: (Time.now.to_f * 1000).to_i,
    }
    uri.query = URI.encode_www_form(params)

    request = Net::HTTP::Get.new(uri)
    {
      'accept' => 'application/json, text/javascript, */*, q=0.01',
      'accept-language' => 'en-US,en;q=0.9',
      'cookie' => cookie,
      'referer' => 'https://www.pinterest.com/',
      'user-agent' => 'Mozilla/5.0',
      'x-app-version' => 'a9c2b33',
      'x-pinterest-appstate' => 'active',
      'x-pinterest-pws-handler' => 'www/[username].js',
      'x-pinterest-source-url' => "/#{username}/",
      'x-requested-with' => 'XMLHttpRequest',
    }.each { |name, value| request[name] = value }
    request['x-csrftoken'] = csrf if csrf && !csrf.empty?

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      response = http.request(request)
      puts "HTTP #{response.code}"
      response.body
    end
  end

  def fetch_board_pins(board, bookmark, cookie)
    csrf = read_csrf(cookie)
    uri = URI('https://www.pinterest.com/resource/BoardFeedResource/get/')
    options = {
      board_id: board['id'],
      board_url: board['url'],
      currentFilter: -1,
      field_set_key: 'react_grid_pin',
      filter_section_pins: true,
      sort: 'default',
      layout: 'default',
      page_size: 25,
      redux_normalize_feed: true,
    }
    options[:bookmarks] = [bookmark] if bookmark

    params = {
      source_url: board['url'],
      data: { options: options, context: {} }.to_json,
      _: (Time.now.to_f * 1000).to_i,
    }
    uri.query = URI.encode_www_form(params)

    request = Net::HTTP::Get.new(uri)
    {
      'accept' => 'application/json, text/javascript, */*, q=0.01',
      'accept-language' => 'en-US,en;q=0.9',
      'cookie' => cookie,
      'referer' => 'https://www.pinterest.com/',
      'user-agent' => 'Mozilla/5.0',
      'x-app-version' => 'a9c2b33',
      'x-pinterest-appstate' => 'active',
      'x-pinterest-pws-handler' => 'www/[username]/[slug].js',
      'x-pinterest-source-url' => board['url'],
      'x-requested-with' => 'XMLHttpRequest',
    }.each { |name, value| request[name] = value }
    request['x-csrftoken'] = csrf if csrf && !csrf.empty?

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      response = http.request(request)
      puts "HTTP #{response.code}"
      response.body
    end
  end

  def fetch_pin_deletion(id, cookie)
    csrf = read_csrf(cookie)
    uri = URI('https://www.pinterest.com/resource/PinResource/delete/')
    source_url = "/pin/#{id}/"

    request = Net::HTTP::Post.new(uri)
    request.body = URI.encode_www_form(
      source_url: source_url,
      data: { options: { id: id }, context: {} }.to_json
    )
    {
      'accept' => 'application/json, text/javascript, */*, q=0.01',
      'accept-language' => 'en-US,en;q=0.9',
      'content-type' => 'application/x-www-form-urlencoded',
      'cookie' => cookie,
      'origin' => 'https://www.pinterest.com',
      'referer' => 'https://www.pinterest.com/',
      'user-agent' => 'Mozilla/5.0',
      'x-app-version' => 'a9c2b33',
      'x-pinterest-appstate' => 'active',
      'x-pinterest-pws-handler' => 'www/pin/[id].js',
      'x-pinterest-source-url' => source_url,
      'x-requested-with' => 'XMLHttpRequest',
    }.each { |name, value| request[name] = value }
    request['x-csrftoken'] = csrf if csrf && !csrf.empty?

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end

end
