Protonet WidgetBridge 
=====================
The Bridge connects a LiveChat-Widget on your homepage to your protonet. 
When the Visitor wants to chat with you, this bridge creates a channel, an subscribed all relevant users to that channel.
The Users will be stored in a Database, to remove them after an amount of time. 



SETUP:
======
We build this app to run on http://www.heroku.com/


HEROKU:
-------
    heroku create
    heroku addons:add shared-database
    git push heroku master

CONFIG:
-------
Set the API_URL to your protonet webpublishing url.

    heroku config:add API_URL="http://yournode.protonet.info"

You need a protonet user with admin rights to be able to speak with the api.

    heroku config:add API_USER="apilogin"
    heroku config:add API_PW="superspecialpassword"

Get the IDs of users who should be in the LiveChat 

    heroku config:add ADMIN_USERS="1,2,3"


CLEANUP:
========
Set up a Cronjob which fetch http://yourapp.heroku.com/cleanup once in a while. 
It will delete all Channels/Users which were not active in the last 7 days.

