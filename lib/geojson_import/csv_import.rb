module Geojson
	module CSVImport
		def load_csv_for(filename)
			@csvdata ||= {}

      csvfile = filename.gsub(/\..+$/, '.csv')

      if File.exist?(csvfile)
        Geojson.logger.info "Loading csv file with names from #{csvfile}"
        CSV.foreach(csvfile, headers: true) do |row|        	
          @csvdata[csv_id(row)] = row
        end
      else
        @csvdata = {}
      end
    end

    def csv_id(row)
      (0..4).map{|i| row["ID_#{i}"]}.compact.join('_')
    end
	end
end