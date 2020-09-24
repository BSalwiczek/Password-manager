#!/bin/bash
# Author           : Bartosz Salwiczek ( s180312@student.pg.edu.pl )
# Created On       : 10.05.2020
# Last Modified By : Bartosz Salwiczek ( s180312@student.pg.edu.pl )
# Last Modified On : 24.05.2020
# Version          : 1.2
#
# Description      : Passwords manager
#                    If you always forgot your passwords, but you don't want to use passwords that
#                    can be easily guess by hacker then password manager is a right choice for you.
#                    Here you can save your passwords and be sure that they are safely encrypted
#                    by one strong password. We provide you a password generator so you don't have
#                    to be worried about making up strong password. Start using password manager today!
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

ENCRYPTED_FILENAME="user_date.gpg"
ENCRYPTED_FILENAME_COPY="user_date(copy).gpg"
PASSWORD=""
SUCCESS=0
VERSION=1.2

createAccount()
{
  "" > /tmp/user_date.txt
  SUCCESS=0
  while [ "$SUCCESS" -eq 0 ]
  do
    PASSWORDS=`zenity --forms --title="Creat account" --text="Type secure password to manager" --add-password="Your password" --add-password="Repeat password"`
    PASS1=`echo $PASSWORDS | awk -F '|' '{print $1}'`
    PASS2=`echo $PASSWORDS | awk -F '|' '{print $2}'`
    LEN=${#PASS1}
    if [[ $LEN == 0 ]]; then
      exit 1
    fi
    if [ "$PASS1" == "$PASS2" ] && [[ ! -z "$PASS1" ]] && [[ $LEN -ge 8 ]] && [[ $PASS1 =~ [0-9] ]]; then
      SUCCESS=1
      cat < /tmp/user_date.txt | gpg -c --batch --passphrase $PASS1 -o $ENCRYPTED_FILENAME
    elif [[ $LEN -lt 8 ]] || [[ ! $PASS1 =~ [0-9] ]] ; then
      zenity --error --width=400 --height=200 --text "Given password is too weak! Required at least 8 characters with at least one number"
    else
      zenity --error --width=400 --height=200 --text "Given passwords are not equal! Try again"
    fi
  done
  rm /tmp/user_date.txt
  PASSWORD=$PASS1

  zenity --info --width=500 --height=100 --title="File security" --text="We created special file user_date.gpg which contains encrypted user data. Please save copy of this file in safe (removable) drive for security after every usage of this script."

}

addNewService()
{
  SUCCESS=0
  while [ "$SUCCESS" -eq 0 ]
  do
    local SERVICE=`zenity --forms --width=400 --height=300 --title="Add service" --text="Add new service" \
     --add-entry="Service name" \
     --add-entry="Login" \
     --add-entry="Email" \
     --add-entry="Website" \
     --add-password="Password"`
    if [ -z "$SERVICE" ]; then
      SUCCESS=1
    elif [[ $SERVICE == *"||"* ]]; then
      zenity --width=200 --height=100 --error --title "Wrong data" --text="You must fill all fields to add service"
    else
      local DATA=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME)
      local UPDATED_DATA=""
      if [ -z "$DATA" ]; then
        UPDATED_DATA="
$SERVICE"
      else
        UPDATED_DATA="${DATA}
$SERVICE"
      fi

      # echo "$UPDATED_DATA" > decrypted_data_for_tests.txt

      rm $ENCRYPTED_FILENAME
      echo "$UPDATED_DATA" | gpg -c --batch --passphrase $PASSWORD -o $ENCRYPTED_FILENAME

      SUCCESS=1
    fi
  done
}

editServices()
{

  local TMP=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME | tail -n +2 | cut -d '|' -f 1)
  local OPTIONS=(`echo $TMP`)
  while opt=$(zenity --width=400 --height=400 --title="Edit service" --text="Choose service to edit" --list --column="Services" "${OPTIONS[@]}"); do
    local TMP2=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME | tail -n +2 | grep "^$opt|" | tr "|" " ")
    local OLDDATA=(`echo $TMP2`)
    echo ${OLDDATA[1]}

    SUCCESS=0
    while [ "$SUCCESS" -eq 0 ]
    do
      local SERVICE=`zenity --forms --width=400 --height=300 --title="Edit service" --text="Edit service $NEWDATA" \
       --add-entry="Service name (${OLDDATA[0]})"\
       --add-entry="Login (${OLDDATA[1]})" \
       --add-entry="Email (${OLDDATA[2]})" \
       --add-entry="Website (${OLDDATA[3]})" \
       --add-password="Password (${OLDDATA[4]})"`
       if [ -z "$SERVICE" ]; then
         SUCCESS=1
       elif [[ $SERVICE == *"||"* ]]; then
         zenity --width=200 --height=100 --error --title "Wrong data" --text="You must fill all fields to add service"
       else
         local OTHER_DATA=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME | grep "^$opt|" --invert)
         local UPDATED_DATA=""
         if [ -z "$OTHER_DATA" ]; then
           UPDATED_DATA="$SERVICE"
         else
           UPDATED_DATA="${OTHER_DATA}
$SERVICE"
         fi

         #echo "$UPDATED_DATA" > decrypted_data_for_tests.txt

         rm $ENCRYPTED_FILENAME
         echo "$UPDATED_DATA" | gpg -c --batch --passphrase $PASSWORD -o $ENCRYPTED_FILENAME

         SUCCESS=1
         viewMenu
       fi
     done
  done
}

viewMenu()
{
  checkIfPasswordsDidNotExpired

  local OPTIONS=("Add new service" "View your services" "Edit existing service" "Remove service" "Generate strong password" "Email security" "Set reset passwords reminder")
  while opt=$(zenity --width=400 --height=400 --title="Menu" --text="Choose option" --list --column="Options" "${OPTIONS[@]}"); do
    case "$opt" in
      "${OPTIONS[0]}" )
        addNewService
      ;;
      "${OPTIONS[1]}" )
        viewServices
      ;;
      "${OPTIONS[2]}" )
        editServices
      ;;
      "${OPTIONS[3]}" )
        removeServices
      ;;
      "${OPTIONS[4]}" )
        generateStrongPassword
      ;;
      "${OPTIONS[5]}" )
        haveibeenpwned
      ;;
      "${OPTIONS[6]}" )
        setResetPasswordsReminder
      ;;
    esac
  done
}

checkIfPasswordsDidNotExpired()
{
  local EXPIRED_DATA=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME | head -n 1)
  local TODAY=$(date '+%d.%m.%Y')
  if [[ ! -z "$EXPIRED_DATA" ]]; then

    input1=`echo $EXPIRED_DATA | awk -F "." '{print $2"/"$1"/"$3}'`
    input2=`echo $TODAY | awk -F "." '{print $2"/"$1"/"$3}'`

    date1=`date +%s --date="$input1"`
    date2=`date +%s --date="$input2"`

    if [ "$date1" -le "$date2" ]; then
      zenity --info --width=200 --height=200 --text="It's time to reset your passwords!"
    fi
  fi
}

setResetPasswordsReminder()
{
  DATE_TO_RESET=$(zenity --calendar)
  echo $DATE_TO_RESET

  local LOADED_DATA=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME | tail -n +2)
  local UPDATED_DATA=""
  if [ -z "$LOADED_DATA" ]; then
    UPDATED_DATA="$DATE_TO_RESET"
  else
    UPDATED_DATA="$DATE_TO_RESET
${LOADED_DATA}"
  fi
  # echo "$UPDATED_DATA" > decrypted_data_for_tests.txt
  rm $ENCRYPTED_FILENAME
  echo "$UPDATED_DATA" | gpg -c --batch --passphrase $PASSWORD -o $ENCRYPTED_FILENAME

}

haveibeenpwned()
{
  URL="https://haveibeenpwned.com"
  [[ -x $BROWSER ]] && exec "$BROWSER" "$URL"
  path=$(which xdg-open || which gnome-open) && exec "$path" "$URL"
  echo "Can't find browser"
  #zenity --info --width=500 --height=100 --title="Email security" --text="Unfortunately haveibeenpwned api costs 3.5\$ per month. You can access their website on this link: https://haveibeenpwned.com and check if your email is safe."
}

generateStrongPassword()
{
  # ctr+miejsce = podwojenie kursora w atom :O
  SUCCESS=0
  while [ "$SUCCESS" -eq 0 ]
  do
    local PASS_OPTIONS=`zenity --forms --width=400 --height=300 --title="Generate Strong Password" --text="Password options (Y-yes, N-no)" \
     --add-entry="Length" \
     --add-entry="Special characters (Y/N)" \
     --add-entry="Lower case letters (Y/N)" \
     --add-entry="Upper case letters (Y/N)"`
    if [[ ! -z "$PASS_OPTIONS" ]]; then
      local REQUEST="http://passwordwolf.com/api/?"
      local LENGTH=`echo $PASS_OPTIONS | cut -d '|' -f 1`
      REQUEST="$REQUEST?length=$LENGTH"
      local SC=`echo $PASS_OPTIONS | cut -d '|' -f 2`
      if [ "$SC" == "Y" ]; then
        REQUEST="$REQUEST&special=on"
      else
        REQUEST="$REQUEST&special=off"
      fi
      local LCL=`echo $PASS_OPTIONS | cut -d '|' -f 3`
      if [ "$LCL" == "Y" ]; then
        REQUEST="$REQUEST&lower=on"
      else
        REQUEST="$REQUEST&lower=off"
      fi
      local UCL=`echo $PASS_OPTIONS | cut -d '|' -f 4`
      if [ "$UCL" == "Y" ]; then
        REQUEST="$REQUEST&upper=on"
      else
        REQUEST="$REQUEST&upper=off"
      fi

      REQUEST="$REQUEST&repeat=1"
      local GENERATED_PASS=$(curl $REQUEST | cut -d '"' -f 4 |
           sed -e 's/\\/\\\\/g' -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g') # parse special characters in password
      if [ "$GENERATED_PASS" == "Server error." ]; then
        zenity --error --width=400 --height=200 --text "Wrong input! Try again"
      else
        zenity --info --width=200 --height=200 --title="Success" --text="Here is your new password: $GENERATED_PASS"
        SUCCESS=1
      fi
    else
      SUCCESS=1
    fi
  done
}

removeServices()
{
  local TMP=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME | tail -n +2 | cut -d '|' -f 1)
  local OPTIONS=(`echo $TMP`)
  while opt=$(zenity --width=400 --height=400 --title="Remove service" --text="Choose service to remove" --list --column="Services" "${OPTIONS[@]}"); do
    if [[ ! -z "$opt" ]]; then
      zenity --question --width=300 --height=300 --text="Are you sure to remove service $opt?"
      THERE=$?
      if [[ $THERE == 0 ]]; then
        local DATA=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME | grep "^$opt|" --invert)
        #echo "$DATA" > decrypted_data_for_tests.txt
        rm $ENCRYPTED_FILENAME
        echo "$DATA" | gpg -c --batch --passphrase $PASSWORD -o $ENCRYPTED_FILENAME
        viewMenu
      fi
    fi
  done
}

viewServices()
{
  local DATA=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME | tail -n +2 | cut -d '|' -f 1)
  local OPTIONS=(`echo $DATA`)
  local NAMES=("Service name: " "Login: " "Email: " "Website: " "Password: " )

  while opt=$(zenity --width=400 --height=400 --title="Services" --text="Choose service" --list --column="Services" "${OPTIONS[@]}"); do
    local NEWDATA=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME | tail -n +2 | grep "^$opt|" | tr "|" "\n")
    local OUTPUT=""
    local count=0
    for item in $NEWDATA
    do
      OUTPUT="$OUTPUT ${NAMES[count]} $item \n"
      count=$((count+1))
    done
    zenity --info --width=400 --title="Zapisane dane dla $opt" --text="$OUTPUT"
  done
}

showHelp() {
# `cat << EOF` This means that cat should stop reading when EOF is detected
cat << EOF
> Welcome to password manager!
To run it simply type: ./pass_manager.sh

> Options
If no options provided zenity login window opens

-h                  --help                       Display help

-v                  --version                    Display version

-p=<password>       --password=<password>        Quick login to manager, after login zenity window opens

> Getting service

-g=<service_name>   --getpassword=<service_name> Quick chceck password for service, -p flag required

> Adding new service
To add new service all fields are required.

-n=<service_name>   --name=<service_name>        Service name

-e=<email>          --email=<email>              Email used in service

-w=<website>        --website=<website>          Link or name to the service website

-s=<service_pass>   --setpassword=<service_pass>   Password to service

EOF
# EOF is found above and hence cat command stops reading. This is equivalent to echo but much neater when printing out.
}

ZENITY_MODE=1

# MAIN
if [ -f $ENCRYPTED_FILENAME ]; then
  SUCCESS=0
  while [ "$SUCCESS" -eq 0 ]
  do
    NAME=""
    LOGIN=""
    EMAIL=""
    WEBSITE=""
    SPASSWORD=""
    ADDING_SERVICE=0
    options=$(getopt -l "help,version,password:,getpassword:,name:,login:,email:,website:,setpassword:" -o "hvp:g:n:l:e:w:s:" -a -- "$@")
    eval set -- "$options"
    while true
    do
    case $1 in
    -h|--help)
        showHelp
        exit 0
        ;;
    -v|--version)
        shift
        echo "Version: $VERSION"
        exit 0
        ;;
    -p|--password)
        shift
        PASSWORD=$1
        #PASSWORD=${PASSWORD#?}; #Removing first character (=)
        ZENITY_MODE=0
        ;;
    -g|--getpassword)
        shift
        STATUS=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME 2> /tmp/Error)
        ERROR=`cat /tmp/Error`
        if [[ ${#ERROR} == 59 ]]; then
          SERVICE_PASSWORD=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME | tail -n +2 | grep "^$1|" | cut -d '|' -f 5)
          if [[ -z "$SERVICE_PASSWORD" ]]; then
            echo "No password saved for this service"
          else
            echo "Password to service \"$1\" is \"$SERVICE_PASSWORD\""
          fi
        else
          echo "Wrong password"
        fi
        exit 1
        ;;
    -n|--name)
        shift
        ADDING_SERVICE=1
        NAME="$1"
        ;;
    -l|--login)
        shift
        ADDING_SERVICE=1
        LOGIN="$1"
        ;;
    -e|--email)
        shift
        ADDING_SERVICE=1
        EMAIL="$1"
        ;;
    -w|--website)
        shift
        ADDING_SERVICE=1
        WEBSITE="$1"
        ;;
    -s|--setpassword)
        shift
        ADDING_SERVICE=1
        SPASSWORD="$1"
        ;;
    --)
        shift
        break;;
    esac
    shift
    done

    if [[ "$ADDING_SERVICE" == "1" ]] && [[ -z "$PASSWORD" ]]; then
      echo "No password provided"
      exit 1
    fi

    if [[ "$ADDING_SERVICE" == "1" ]]; then
      if [[ ! -z "$NAME" ]] && [[ ! -z "$LOGIN" ]] && [[ ! -z "$EMAIL" ]] && [[ ! -z "$WEBSITE" ]] && [[ ! -z "$SPASSWORD" ]]; then
        echo "Adding service"
        STATUS=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME 2> /tmp/Error)
        ERROR=`cat /tmp/Error`
        if [[ ${#ERROR} == 59 ]]; then
          SERVICE_LINE="$NAME|$LOGIN|$EMAIL|$WEBSITE|$SPASSWORD"
          DATA=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME)
          UPDATED_DATA=""
          if [ -z "$DATA" ]; then
            UPDATED_DATA="
$SERVICE_LINE"
          else
            UPDATED_DATA="${DATA}
$SERVICE_LINE"
          fi

          # echo "$UPDATED_DATA" > decrypted_data_for_tests.txt

          rm $ENCRYPTED_FILENAME
          echo "$UPDATED_DATA" | gpg -c --batch --passphrase $PASSWORD -o $ENCRYPTED_FILENAME
          echo "Service $NAME succesfully added"
        else
          echo "Wrong password"
        fi
      else
        #echo "$NAME|$LOGIN|$EMAIL|$WEBSITE|$SPASSWORD"
        echo "Not enough data to add a new service"
      fi
      exit 1
    fi

    if [[ "$ZENITY_MODE" == "1" ]]; then
      PASSWORD=`zenity --forms --title="Login" --text="Manager password" --add-password="Your password"`
    fi

    STATUS=$(gpg -d --batch --passphrase $PASSWORD $ENCRYPTED_FILENAME 2> /tmp/Error)
    ERROR=`cat /tmp/Error`
    if [[ ${#ERROR} == 59 ]]; then
      SUCCESS=1
      cp $ENCRYPTED_FILENAME $ENCRYPTED_FILENAME_COPY
      viewMenu
    else
      if [[ -z "$PASSWORD" ]]; then
        SUCCESS=1
      else
        if [[ "$ZENITY_MODE" == "1" ]]; then
          zenity --error --width=400 --height=200 --text "Wrong password! Try again"
        else
          echo $PASSWORD
          echo "Wrong password"
          exit 1
        fi
      fi
    fi

    if [ -f $ENCRYPTED_FILENAME_COPY ]; then
      rm $ENCRYPTED_FILENAME_COPY
    fi
  done

else
  SUCCESS=0
  while [ "$SUCCESS" -eq 0 ]
  do
    createAccount
  done
  viewMenu
fi
