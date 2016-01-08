class Alert < ActiveRecord::Base
	belongs_to :user

# returns list of departments to check from alerts
	def self.get_departments
		depts = []
		Alert.all.each do |alert|
			depts.push(alert.department) unless depts.include?(alert.department)
		end
		return depts
	end

# Sends emails to users of alerts that have open seats
# Returns array of alerts that have been sent (to be deleted)
	def self.check_seats
		depts = get_departments
		all_seats = Hash.new
		open_seats = Hash.new
		alerts_sent = []

		depts.each do |dept|
			all_seats[dept] = fetch_dept_info(dept)
		end

		Alert.all.each do |alert|
			department_seats = all_seats[alert.department]
			if (department_seats[alert.course_number] != "Closed" && department_seats[alert.course_number] != nil)
				open_seats[alert] = department_seats[alert.course_number] 
			end
		end
		open_seats.each do |alert , seats|
			AlertMailer.alert_email(alert).deliver_now
			alerts_sent << alert
			# alert.destroy
		end

		alerts_sent
	end


private 


#need to refactor this so that it only logs in once per check, not once for every department
#should seperate into 2 methods, one to log in and then another to fetch after that, 
#call log in method first in self.check_seats before the depts.each loop 
	def self.fetch_dept_info(dept)
		id = ENV["ID"]
		pw = ENV["PW"]
		term = " Spring 2016"
		# This uses "Classic version" of web reg, 
		# should also try to implement on new version
		base_link = "https://camel2.usc.edu/webreg/crsesoffrd.asp?DEPT="
		agent = Mechanize.new
		page = agent.get('https://camel2.usc.edu/webreg/')
		form = page.form('LoginForm')
		form['Login::SSN'] = id
		form['Login::PIN'] = pw
		page = agent.submit(form)
		page = agent.page.link_with(:text => term).click
		page = agent.get(base_link + dept)


		section_numbers = agent.page.search(".sectiondata").map(&:text).map(&:strip)
		section_seats = agent.page.search(".seatsdata").map(&:text).map(&:strip)

		sections = Hash.new
		section_numbers.zip(section_seats).each do |number,seats|
			sections[number] = seats
			## puts number + " " + sections[number]
		end

		return sections
	end

end
