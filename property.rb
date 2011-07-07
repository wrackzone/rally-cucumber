
  module Properties
    PROPERTIES = { }

    # Load java style properties from a file.
    # It will substitute simple RHS values of the form ${value}
    # from values already loaded into the hash
    #
    # If the RHS is of the form ${env.foo}, foo will be loaded from ENV
    #
    def Properties.load_properties(properties_filename)
      File.open(properties_filename, 'r') do |properties_file|
	properties_file.read.each_line do |line|
	  line.strip!
	  if (line[0] != ?# and line[0] != ?=)
	      i = line.index('=')
	    if (i)
	      name = line[0..i - 1].strip
	      value = line[i + 1..-1].strip

	      # check for the form ${value}
	      if value =~ /^\$\{(.*)\}/
		stripped_value = $1
		# check for the form ${env.foo}
		if stripped_value =~ /^env\.(.*)/
		  value = ENV[$1]
		else
		  value = PROPERTIES[stripped_value]
		end
	      end
	      PROPERTIES[name] = value
	    else
	      PROPERTIES[line] = ''
	    end
	  end
	end      
      end
      PROPERTIES
    end

    def Properties.hostname
      PROPERTIES['http.hostName']
    end
    
    def Properties.port
      PROPERTIES['http.listenPort']
    end

    def Properties.base_url
      "http://#{Properties::PROPERTIES['http.hostName']}:#{Properties::PROPERTIES['http.listenPort']}/slm"
    end

  end
