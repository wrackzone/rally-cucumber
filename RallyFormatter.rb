# features/support/twitter_formatter.rb
require 'rubygems'
require 'rally_rest_api'
require 'time'

module Rally
  class RallyFormatter
  
  	features = nil
  	feature = nil
  	scenario = nil
  	slm = nil
	rally = nil
  	
  	def connect()
  	
	  	properties = Properties.load_properties("default.properties")	           
	
		@slm = RallyRestAPI.new(:base_url => properties["url"],
							    :username => properties["user.name"], 
							    :password => properties["user.password"])
		@rally = Hash.new					    
		@rally["slm"] = @slm
		@rally["workspace"] = @slm.user.subscription.workspaces.find { |w| w.name == properties["workspace"] }
		@rally["project"] = @rally["workspace"].projects.find { |p| p.name == properties["project"] }

		@rally["create_story"] = (properties["create.story"] && properties["create.story"]=="true")

		print "#{@rally["workspace"].name}\n"
		print "#{@rally["project"].name}\n"

  	end
  	
  	def create_story(name,desc) 
  		fields = { :name => name,:description => desc, :project => @rally["project"], :workspace => @rally["workspace"] }
  		story = @slm.create(:hierarchical_requirement,fields)
  		return story
  	end
 
  	def create_test_case(story,name,desc) 
  		fields = { :work_product => story,
  				   :name => name,
  				   :description => desc, 
  				   :project => @rally["project"], 
  				   :workspace => @rally["workspace"] }
  		test_case = @slm.create(:test_case,fields)
  		return test_case
  	end
 
 	def create_result(testcase,verdict,msg)
 		fields = {  :project => @rally["project"],
 			 	    :workspace => @rally["workspace"],
 				    :date => Time.now,
 					:build => "999",
 					:test_case => testcase,
 					:verdict => verdict,
 					:notes => msg }
		result = @slm.create(:test_case_result,fields) 	
		print "\n#{testcase.formatted_i_d} - #{result.verdict}\n"	
 		return result	
 	end
 
 	def find_object_by_name(name, type)  
	    if ( name != "" and name != nil )
	      query_result = @slm.find(
	        type, 
	        :project => @rally["project"],
	        :project_scope_up => false, 
	        :project_scope_down => true) {equal :name, name}

	      return query_result.first
	    end
  	end
  	
  	def find_or_create_story(name) 
  	
  		desc = name.clone
  		desc.gsub!(/[\r\t\n]/, '') 
  		name.gsub!(/[\r\t\n]/, '') 
  	
  		story = find_object_by_name(name,"hierarchical_requirement")
  		if !story
  			if @rally["create_story"] == true
  				story = create_story(name,desc)
  			end
  		end
  		return story
  	end 	 	
  	
 	def find_test_case_in_story( story, testCaseName)
		if story.test_cases
			story.test_cases.each { |test_case|
				if test_case.name == testCaseName
					return test_case
				end
			}
		end
		return nil
	end
  
	def find_or_create_test_case(story,name,desc) 
  		name.gsub!(/[\r\t\n]/, '') 
  		test_case = find_test_case_in_story(story,name)
  		if !test_case
  			test_case = create_test_case(story,name,desc)
  		end
  		return test_case
  	end 	 	

    def initialize(step_mother, io, options)
    end
    
    def feature_name(keyword,name)
		@feature = { "name" => name, "scenarios" => Array.new }
    	@features = Array.new if !@features
    	@features.push(@feature)
    end
    
    def scenario_name(keyword, name, file_colon_line, source_indent)
    	@scenario = {"name" => name, "steps" => Array.new }
    	@feature["scenarios"].push(@scenario) 
  	end

    def step_name(keyword, step_match, status, source_indent, background)
		name = step_match.format_args(lambda{|param| "*#{param}*"})
    	step_result = { "step" => name, "result" => status }
		@scenario["steps"].push(step_result)
    end
    
	def status_to_string(status)
		case status
		when :undefined
			return "undefined"
		when :passed
			return "passed"
		when :failed
			return "failed"
		else
			return "don't know"
		end
	end

	def after_features(features)
		connect
		@features.each do |feature| 
			story = find_or_create_story(feature['name'])
			print "#{feature['name']} - Scenarios:#{feature['scenarios'].length}\n"
			feature["scenarios"].each do |scenario|
				print "Steps:#{scenario['steps'].length}\n"
				desc = ""
				verdict = "Pass"
				msg= ""
				scenario['steps'].each do |step| 
					print "Step:#{step["step"]} - #{step["result"]}\n"
					if step["result"] != :passed
						verdict = "Fail"
					end
					msg += step["step"]+" ["+status_to_string(step["result"])+"]"+"<br/>"
					desc += step["step"]+"<br/>"				 				
				end
				test_case = find_or_create_test_case(story,scenario["name"],desc)		
				create_result(test_case,verdict,msg)
			end
		end
	end
  end
end
