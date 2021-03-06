# frozen_string_literal: true

require_relative "./feeds/feed"
require_relative "./feeds/ayashige"
require_relative "./feeds/urlscan"

module Miteru
  class Feeds
    attr_reader :directory_traveling

    def initialize(urlscan_size = 100, directory_traveling: false)
      @feeds = [
        Ayashige.new,
        UrlScan.new(urlscan_size)
      ]
      @directory_traveling = directory_traveling
    end

    def suspicious_urls
      @suspicious_urls ||= [].tap do |arr|
        urls = @feeds.map do |feed|
          feed.urls.select { |url| url.start_with?("http://", "https://") }
        end.flatten.uniq

        urls.map { |url| breakdown(url) }.flatten.uniq.sort.each { |url| arr << url }
      end
    end

    def breakdown(url)
      begin
        uri = URI.parse(url)
      rescue URI::InvalidURIError => _
        return []
      end

      base = "#{uri.scheme}://#{uri.hostname}"
      return [base] unless directory_traveling

      segments = uri.path.split("/")
      return [base] if segments.length.zero?

      urls = (0...segments.length).map { |idx| "#{base}#{segments[0..idx].join('/')}" }
      urls.reject do |breakdowned_url|
        # Reject a url which ends with specific extension names
        %w(.htm .html .php .asp .aspx).any? { |ext| breakdowned_url.end_with? ext }
      end
    end
  end
end
