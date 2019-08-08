require 'watir'
require 'httparty'
require 'net/ping'

def fetch_from_server
  # Get data from server.
  puts "----------------------------------------------------------------------------------------------------"
  url = 'http://10.9.152.28:3000/sites2'
  @response = HTTParty.get(url)

  json = JSON.parse(@response.body)
  puts json
  return json
end

def ping_site(ip)
  check = Net::Ping::External.new(ip)
  puts "Ping: #{check.ping?}"
  return check.ping?
end

def update_server_with_error(id)
  url = 'http://10.9.152.28:3000/error'
  puts "Raising an error"
  @result = HTTParty.post(url, :body => {:id => id})
end

def update_conversion_at_server(id)
  url = 'http://10.9.152.28:3000/completed'
  puts "COMPLETED - Saving to Server"
  @result = HTTParty.post(url, :body => {:id => id})
end

def convert(ip,block_email,block_password, cf_email)
  id = id
  ip = ip
  
  @block_email = block_email
  @block_password = block_password
  @cf_email = cf_email
  
  @browser = Watir::Browser.new :firefox

  #ip = '10.9.135.11' # Wrong password test case.
  #ip = '10.241.169.150'

  @browser.goto "http://#{ip}/wcd/login.xml"
  sleep(7)
  @browser.text_field(:xpath => '//*[@id="Admin_Pass"]').set "1234567812345678"
  sleep(1)
  @browser.text_field(:xpath => '//*[@id="LP1_OK"]').click
  sleep(10)
  
  if @browser.url == "http://#{ip}/wcd/logrecord_permit.xml"
    sleep(1)
    @browser.button(:xpath => '//*[@id="cgibtnNG"]').click
    sleep(2)
  end
  
  unless @browser.url == "http://#{ip}/wcd/a_system_counter.xml"
    raise
  end
  
  
  #==============================
  # System Settings 
  #==============================
  
  
  @browser.goto "http://#{ip}/wcd/a_environment_machine.xml"
  sleep(13)
  
  #Admin Email
  @browser.text_field(:xpath => '//*[@id="AV_DIF_AML"]').clear
  @browser.text_field(:xpath => '//*[@id="AV_DIF_AML"]').send_keys(@block_email)
  puts "Updated the SYSTEM SETTINGS block email 1/2"

  @browser.text_field(:xpath => '//*[@id="AV_DIF_HML"]').clear()
  @browser.text_field(:xpath => '//*[@id="AV_DIF_HML"]').send_keys(@block_email)
  puts "Updated the SYSTEM SETTINGS block email 2/2"

  #Hit the ok Button
  @browser.button(:xpath => '//*[@id="Apply1"]').click
  sleep(4)
  @browser.button(:xpath => '//*[@id="cgierrorbtnOK"]').click
  sleep(4)
  
  
  
  #==============================
  # Certificates
  #==============================
  
  puts "----------CERTIFICATES-----------------"
  
  @browser.goto "http://#{ip}/wcd/a_security_devicecert.xml"
  
  # Iterate over the certificates
  @cert_count = @browser.execute_script("return document.querySelectorAll('input[value=Setting]').length")
  puts "Total Certificates: #{@cert_count}"
  
  if @cert_count > 0
      (1..@cert_count).each do |count|

        @cert_count = @cert_count - 1

        puts "@cert_count: #{@cert_count} | count: #{count}"

        id_being_deleted = @browser.execute_script("return document.querySelectorAll('input[value=Setting]')[#{@cert_count}].id")
        puts "ID Being Deleted: #{id_being_deleted}"
        sleep(1)

        # CLick the setting button
        # This expects the index number, which starts at 0.
        puts "//*[@id='#{id_being_deleted}']"

        @browser.button(:xpath => "//*[@id='#{id_being_deleted}']").click
        puts "Clicked the Setting Button"
        sleep(3)

        @browser.button(:xpath => '//*[@id="Next0"]').click
        puts "Clicked the OK Button"
        sleep(6)

        @browser.button(:xpath => '//*[@id="ASE_SSL_BTN1"]').click
        puts "Clicked the OK to Remove Cert"
        sleep(9)

        puts "------------------------------"

        @browser.goto "http://#{ip}/wcd/a_security_devicecert.xml"
        sleep(3)

      end

    else
    # If no certificates
    # Create the
    end
  
    puts "---------------------------"
  
  
    @browser.goto "http://#{ip}/wcd/a_security_devicecert.xml"
    sleep(10)

    # Button creating new cert
    @browser.button(:xpath => '//*[@id="Regist"]').click
    puts "Clicking the button to create a new certificate"
    sleep(2)
    
    # Select the radio button
    @browser.radio(:xpath => '//*[@id="ASE_SSL_R_SSL0"]').set
    puts "Select radio button for type of certificate. "
    sleep(3)

    # Create and install a Self-Signed Certificate
    @browser.button(:xpath => '//*[@id="Next0"]').click
    sleep(4)
   
   
    #Enter in the form Values
    @browser.text_field(:xpath => '//*[@id="ASE_SSL_1_ORG"]').set("KCE")
    @browser.text_field(:xpath => '//*[@id="ASE_SSL_1_UNI"]').set("KCE")
    @browser.text_field(:xpath => '//*[@id="ASE_SSL_1_LOC"]').set("KCE")
    @browser.text_field(:xpath => '//*[@id="ASE_SSL_1_STA"]').set("KCE")
    @browser.text_field(:xpath => '//*[@id="ASE_SSL_1_COU"]').set("US")
    @browser.text_field(:xpath => '//*[@id="ASE_SSL_1_VAL"]').set('3650')
    sleep(4)

    # Hit the OK button to submit the form.
    @browser.button(:xpath => '//*[@id="Create0"]').click
    sleep(8)

    # Goes to the page that says "Certificate is being updated"
    # Goes to a page where it says it can now be used.

    # Hit the OK Button on that page:
    @browser.button(:xpath => '//*[@id="cgierrorbtnOK"]').click
    sleep(5)
    
  #==============================
  # Network Config
  #============================== 
  
    @browser.goto "http://#{ip}/wcd/a_network_tcpip.xml"
    sleep(10)

    # Select the DNS Server Auto Obtain to False.
    @browser.select_list(:id=> "AN_TCP_SSA").option(value: 'false').click
    sleep(1)

    @browser.text_field(:xpath => '//*[@id="AN_TCP_DNS1"]').clear
    sleep(1)
    @browser.text_field(:xpath => '//*[@id="AN_TCP_DNS1"]').set("10.4.96.229")
    sleep(1)

    @browser.text_field(:xpath => '//*[@id="AN_TCP_DNS2"]').clear
    sleep(1)
    @browser.text_field(:xpath => '//*[@id="AN_TCP_DNS2"]').set("10.4.96.230")
    sleep(1)

    @browser.text_field(:xpath => '//*[@id="AN_TCP_DNS3"]').clear
    sleep(1)
    @browser.text_field(:xpath => '//*[@id="AN_TCP_DNS3"]').set("10.4.113.25")
    sleep(1)

    # Save the settings. Hit the OK Button.
    @browser.button(:xpath => '//*[@id="Apply0"]').click
    sleep(7)

    # Hit the OK button that shows up after saving content.
    @browser.button(:xpath => '//*[@id="cgierrorbtnOK"]').click
    sleep(10)
    
  #==============================
  # Email Settings
  #==============================     
  
  puts "########### EMAIL SETTINGS ############"

  @browser.goto "http://#{ip}/wcd/a_network_send.xml"
  sleep(10)

  scan_to_email_status = @browser.checkbox(:xpath => '//*[@id="AN_ESM_SSE"]').set?

  puts "Scan to Email Status: #{scan_to_email_status}"
  
  # Scan to Email Checkbox
  # Reset the Checkbox:
  @browser.checkbox(:xpath => '//*[@id="AN_ESM_SSE"]').clear
  sleep(0.5)
  @browser.checkbox(:xpath => '//*[@id="AN_ESM_SSE"]').set
  sleep(0.5)
  
  # Scan to Email Tab
  @browser.select_list(:xpath => '//*[@id="AN_ESM_SSS"]').option(value: 'true').click
  puts "--Enabled the Scan to Email Dropdown"
  
  
  # Email Notification Tab
  @browser.select_list(:xpath => '//*[@id="AN_ESM_SNF"]').option(value: 'true').click
  puts "--Enabled the Email Notification Dropdown"
  
  
  # Total Counter Notification Tab
  @browser.select_list(:xpath => '//*[@id="AN_ESM_TNF"]').option(value: 'true').click
  puts "--Enabled the Total Counter Dropdown"
  
  # SMTP Server Address Checkbox
  @browser.checkbox(:xpath => '//*[@id="AN_ESM_C_HOS"]').clear
  sleep(0.5)
  @browser.checkbox(:xpath => '//*[@id="AN_ESM_C_HOS"]').set
  sleep(0.5)
  puts "--Enabled the SMTP Server Address Checkbox"
  
  
  # SMTP Server Address
  @browser.text_field(:xpath => '//*[@id="AN_ESM_SMP"]').clear
  @browser.text_field(:xpath => '//*[@id="AN_ESM_SMP"]').set "smtp.office365.com"
  puts "--Put the SMTP Server Address "
  
  # Enable TLS:
  @browser.select_list(:xpath => '//*[@id="AN_ESM_TSL"]').option(value: 'StartTls').click
  
  
  # SSL Port Number
  @browser.text_field(:xpath => '//*[@id="AN_ESM_POR"]').clear
  @browser.text_field(:xpath => '//*[@id="AN_ESM_POR"]').set '587'
  puts "--Put the TLS Port Number"
  
  # Scroll to the page:
  # You need to do this for the C308, because it has an overlay that obscures it, and throws an error
  @browser.execute_script("window.scrollTo(0, document.body.scrollHeight);")
  sleep(1)
  
  
  # Certificate Verification Level Settings
  # Validity Period
  @browser.select_list(:xpath => '//*[@id="AN_ESM_EXD"]').option(value: 'Off').click
  puts "--Cert Settings: 1/5"
  
  # CN
  @browser.select_list(:xpath => '//*[@id="AN_ESM_CND"]').option(value: 'Off').click
  puts "--Cert Settings: 2/5"
  
  # Key Usage
  @browser.select_list(:xpath => '//*[@id="AN_ESM_KYD"]').option(value: 'Off').click
  puts "--Cert Settings: 3/5"
  
  # Chain
  @browser.select_list(:xpath => '//*[@id="AN_ESM_CHD"]').option(value: 'Off').click
  puts "--Cert Settings: 4/5"
  
  # Expiration Date Confirmation
  @browser.select_list(:xpath => '//*[@id="AN_ESM_LCD"]').option(value: 'Off').click
  puts "--Cert Settings: 5/5"
  
  # Device Email Address:
  @browser.text_field(:xpath => '//*[@id="AN_ESM_MAI"]').clear
  @browser.text_field(:xpath => '//*[@id="AN_ESM_MAI"]').set @block_email
  puts "--Input the Block Email Username"
  
  # SMTP Authentication
  @browser.checkbox(:xpath => '//*[@id="AN_ESM_SAU"]').clear
  @browser.checkbox(:xpath => '//*[@id="AN_ESM_SAU"]').set
  puts '--Checked the SMTP Authentication Checkbox'
  
  
  # SMTP Authentication methods
  @browser.select_list(:xpath => '//*[@id="AN_ESM_AM1"]').option(value: 'Off').click
  @browser.select_list(:xpath => '//*[@id="AN_ESM_AM2"]').option(value: 'Off').click
  @browser.select_list(:xpath => '//*[@id="AN_ESM_AM3"]').option(value: 'Off').click
  @browser.select_list(:xpath => '//*[@id="AN_ESM_AM4"]').option(value: 'Off').click
  @browser.select_list(:xpath => '//*[@id="AN_ESM_AM5"]').option(value: 'On').click
  @browser.select_list(:xpath => '//*[@id="AN_ESM_AM6"]').option(value: 'Off').click
  puts '--Set all the SMTP Authentication methods'
  
  # User ID
  @browser.text_field(:xpath => '//*[@id="AN_ESM_USE"]').clear
  @browser.text_field(:xpath => '//*[@id="AN_ESM_USE"]').set @block_email
  puts '--Input the Block Account Email'
  
  # Password Checkbox
  @browser.checkbox(:xpath => '//*[@id="AN_ESM_PAC"]').set
  sleep(0.5)
  
  # Password
  @browser.text_field(:xpath => '//*[@id="AN_ESM_PAS"]').set @block_password
  puts "--Input the Block Account Password: #{@block_password}"
  
  # Hit the OK Button
  @browser.button(:xpath => '//*[@id="Apply13"]').click
  
  sleep(5)
  
  @browser.button(:xpath => '//*[@id="cgierrorbtnOK"]').click
  puts '--Clicked the button to save the changes to the server.'
  sleep(5)    
  
  #======================
  # Center Friendly Email Address
  #========================
  
  @browser.goto "http://#{ip}/wcd/a_abbr.xml"
  sleep(10)
  
  # Hit the New Registration Button
  @browser.button(:xpath => '//*[@id="Regist"]').click
  
  # Select the Email Registration Button
  @browser.radio(:xpath => '//*[@id="R_SEL1"]').set
  sleep(0.5)
  
  # Click OK to Create:
  @browser.button(:xpath => '//*[@id="Next"]').click
  sleep(8)
  
  # Type in the Name:
  @browser.text_field(:xpath => '//*[@id="AC_A_EML_NAM"]').set "Scan to Email"
  
  # Select the Main Checkbox
  @browser.checkbox(:xpath => '//*[@id="AC_A_EML_WEL"]').set
  
  # Input the Center Friendly Email Address:
  @browser.text_field(:xpath => '//*[@id="AC_A_EML_ADD"]').set @cf_email
  
  # Hit Apply Button
  @browser.button(:xpath => '//*[@id="AC_A_EML_Apply"]').click
  sleep(8)
  
  # Return the Center Friendly Email Page
  @browser.button(:xpath => '//*[@id="btnOption1"]').click  
  sleep(5)
  
  
  #======================
  # Network Error Code Display
  #========================
  puts "-----------Enable Error Code Display-------------"
  
  @browser.goto "http://#{ip}/wcd/a_system_errorcode.xml"
  sleep(10)
  
  # Enable the Error Code Display
  @browser.select_list(:xpath => '//*[@id="AS_NED_DEC"]').option(value: 'On').click
  puts "--Enable Error Code Display"
  
  # Hit OK to save changes
  @browser.button(:xpath => '//*[@id="AS_NED_NE"]/div[2]/input[1]').click
  sleep(4)
  
  @browser.button(:xpath => '//*[@id="cgierrorbtnOK"]').click
  
  puts "--Enabled Network Error Code Display"
  
  
  #==========================
  # Reset Controller
  #===========================
  
  puts "----------- Reset Controller -----------"
  
  @browser.goto "http://#{ip}/wcd/a_system_reset.xml"
  sleep(10)
  puts "Hit the reset controller"
  
  # Hit the Reset Button
  @browser.button(:xpath => '//*[@id="Reset"]').click
  sleep(2)
  
  # Hit OK to actuall reset the controller.
  @browser.button(:xpath => '//*[@id="Ok1"]').click
  puts "Restarting"
  
  puts "-------------------END----------------------"
  
  @browser.quit

end


    
    # Fetch a entry from the server.
    site = fetch_from_server

    # Ping it.
    puts "Pinging #{site['ip']}"
    status = ping_site(site['ip'])

    if status == true
      begin
        puts "Starting"
        convert(site['ip'], site['block_email'], site['block_password'], site['cf_email'])
        update_conversion_at_server(site['id'])
        #@browser.quit
        puts "-------------------------------------------------------------------------------------------"
      rescue => e
        @browser.quit
        puts e
        puts "Got error in script"
        update_server_with_error(site['id'])
      end
    else
      puts "Failed Ping"
      update_server_with_error(site['id'])
      #@browser.quit
    end





