# Password Manager
Easy to use a console password manager. Passwords are encrypted using GPG.
Uses zenity dialog or console for adding and reminding password. You can set password reminders so you'll never forget to change your password. The manager can also help you generate new strong passwords.


## Instalation

To run it simply type: `./pass_manager.sh`

## Usage
### Options
If no options provided zenity login window opens
```
-h                  --help                       Display help
-v                  --version                    Display version
-p=<password>       --password=<password>        Quick login to manager, after login zenity window opens
```
### Getting service
```
-g=<service_name>   --getpassword=<service_name> Quick chceck password for service, -p flag required
```
### Adding new service
```
To add new service all fields are required.
-n=<service_name>   --name=<service_name>        Service name
-e=<email>          --email=<email>              Email used in service
-w=<website>        --website=<website>          Link or name to the service website
-s=<service_pass>   --setpassword=<service_pass>   Password to service
```

## License
[MIT](https://choosealicense.com/licenses/mit/)
