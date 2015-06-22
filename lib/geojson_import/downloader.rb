module Geojson

  class Downloader

    def initialize(files, local_folder = "etc/shapes")
      @files = files
      @local_folder = local_folder
    end

    def download!
      @files.map { |remote| download_file(remote) }.compact
    end

    def local_file_name(remote)
      File.join(Rails.root, @local_folder, URI(remote).path.split('/').last)
    end

    def download_file(remote)
      uri = URI(remote)
      local = local_file_name(remote)
      downloaded = false

      Geojson.logger.info("Download file #{remote} into #{local}")

      req = Net::HTTP::Get.new(uri.request_uri)
      req['If-Modified-Since'] = File.stat(local).mtime.rfc2822 if File.exists?(local)

      Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req) do |response|
          if response.is_a?(Net::HTTPSuccess)
            open(local, 'wb') do |io|
              response.read_body do |chunk|
                io.write chunk
              end
            end
            downloaded = true
            Geojson.logger.info(" File download complete")
          elsif response.is_a?(Net::HTTPNotModified)
            Geojson.logger.info(" File was not modified")
          else
            Geojson.logger.warn(" Error downloading file from #{remote}: #{response.status}")
          end
        end
      end

      return local if downloaded
    end

  end

end
