#!/bin/bash

# Add Exchange Account OS X Script
# Version 1.0 (10/11/2015)
# Copyright Michael Page

# Script blog post: http://errorfreeit.com.au/blog/2015/11/10/automating-exchange-setup-without-mdm

# This script automates the setup of an Exchange account on OS X.
# This includes setup for Apple Mail, Contacts, Calendars, Reminders and Notes.

# Usage is simple:
# First deploy Joseph Chilcote's Outset script: https://github.com/chilcote/outset/releases/latest
# Customise the required DOMAIN and EXCHANGE_HOST values below.
# Then copy this script into /usr/local/outset/login-once/, remember to make it executable. 
# That's it! The first time a user logs in they are prompted to enter their Exchange account password and then the script does the rest.

### Required Configuration ###

# Organisation's domain name (e.g. errorfreeit.com.au)
DOMAIN="errorfreeit.com.au"

# Exchange server address
EXCHANGE_HOST="outlook.office365.com"



### Optional Configuration ###

# The number of past days of email to synchronise
# Note: 0 means no limit
DAYS_OF_MAIL_TO_SYNC="0"

# Obtain logged in username
USERNAME=$(/usr/bin/whoami)

# Formulate email address
EMAIL_ADDRESS="${USERNAME}@${DOMAIN}"

# Exchange account username
EXCHANGE_USERNAME="$EMAIL_ADDRESS"

# Account description displayed in OS X
ACCOUNT_DESCRIPTION="$EMAIL_ADDRESS"

# Prompt user for Exchange account password
PASSWORD=$(/usr/bin/osascript -e 'display dialog "To complete the setup of your Exchange account ('$EMAIL_ADDRESS') please enter your password:" default answer "" with hidden answer buttons {"Save"} default button {"Save"} with title "Add Exchange Account" with icon file "Macintosh HD:System:Library:CoreServices:CoreTypes.bundle:Contents:Resources:Accounts.icns"
set givenPassword to text returned of result')

# Password was not entered, end script with error.
if [ -z "$PASSWORD" ]
then
	echo "No input detected!"
	exit 1
fi

# Get the reverse of the domain (e.g. errorfreeit.com.au becomes au.com.errorfreeit)
ORGANISATION_IDENTIFIER=$(echo "$DOMAIN" | awk '{n=split($0,A,".");S=A[n];{for(i=n-1;i>0;i--)S=S"."A[i]}}END{print S}')

# Profile identifier
PAYLOAD_IDENTIFIER="${ORGANISATION_IDENTIFIER}.addexchangeaccount"

# Generate random payload UUIDs
PRIMARY_PAYLOAD_UUID=$(/usr/bin/uuidgen)
SECONDARY_PAYLOAD_UUID=$(/usr/bin/uuidgen)

# Temporary profile path
TMP_PROFILE="/tmp/addexchangeaccount.mobileconfig"

# Generate profile
echo '<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
    <dict>
        <key>PayloadIdentifier</key>
        <string>'$PAYLOAD_IDENTIFIER'</string>
        <key>PayloadRemovalDisallowed</key>
        <false />
        <key>PayloadScope</key>
        <string>User</string>
        <key>PayloadType</key>
        <string>Configuration</string>
        <key>PayloadUUID</key>
        <string>'$PRIMARY_PAYLOAD_UUID'</string>
        <key>PayloadOrganization</key>
        <string>'$DOMAIN'</string>
        <key>PayloadVersion</key>
        <integer>1</integer>
        <key>PayloadDisplayName</key>
        <string>Exchange Account</string>
        <key>PayloadContent</key>
        <array>
            <dict>
                <key>PayloadType</key>
                <string>com.apple.ews.account</string>
                <key>PayloadVersion</key>
                <integer>1</integer>
                <key>PayloadIdentifier</key>
                <string>com.apple.mdm.'$DOMAIN'.'$PRIMARY_PAYLOAD_UUID'.alacarte.exchange.'$SECONDARY_PAYLOAD_UUID'</string>
                <key>PayloadUUID</key>
                <string>'$SECONDARY_PAYLOAD_UUID'</string>
                <key>PayloadEnabled</key>
                <true />
                <key>PayloadDisplayName</key>
                <string>'$ACCOUNT_DESCRIPTION'</string>
                <key>PreventMove</key>
                <false />
                <key>disableMailRecentsSyncing</key>
                <false />
                <key>PreventAppSheet</key>
                <false />
                <key>SSL</key>
                <true />
                <key>MailNumberOfPastDaysToSync</key>
                <integer>'$DAYS_OF_MAIL_TO_SYNC'</integer>
                <key>ExternalSSL</key>
                <true />
                <key>SMIMEEnabled</key>
                <false />
                <key>SMIMEEnablePerMessageSwitch</key>
                <false />
                <key>EmailAddress</key>
                <string>'$EMAIL_ADDRESS'</string>
                <key>UserName</key>
                <string>'$EXCHANGE_USERNAME'</string>
                <key>Host</key>
                <string>'$EXCHANGE_HOST'</string>
                <key>Port</key>
                <integer>443</integer>
                <key>Password</key>
                <string>'$PASSWORD'</string>
            </dict>
        </array>
    </dict>
</plist>' > "$TMP_PROFILE"

# Install generated temporary profile
/usr/bin/profiles -I -F "$TMP_PROFILE"

# Securely remove temporary profile
/usr/bin/srm "$TMP_PROFILE"