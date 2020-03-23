# Instagram Token Agent

## A service to keep your Instagram Basic Display API token fresh.

⚠️**This is a work in progress and not ready for use yet!**

This agent is designed to run as a small, self-contained app on [Heroku](https://heroku.com) (though there are other ways to run it if you prefer). By default, it runs using free services and will keep your token up to date once set up correctly.

This agent is designed to be used alongside services like [instafeed.js](https://github.com/stevenschobert/instafeed.js) which need a valid token to operate. These tokens need to be periodically refreshed - **Instagram Token Agent** takes care of that for you.

## You will need

To begin, you'll need the following:

 - [] A Facebook Developer account
 - [] An Instagram account
 - [] A Heroku account

## Usage

[Follow the instructions here](https://developers.facebook.com/docs/instagram-basic-display-api/getting-started) to create an application on Facebook to connect to Instagram and generate a Long-lived Basic Display API token for your user. Copy this token and keep it handy for the next step.

Click the 'Deploy' button! [![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

On the page that follows, fill in the following values:

 - **App name**: Make up a name for your app - it needs to be unique, like a username. Something like `your-name-token-agent` will do.

_Under 'Config vars'_

 - **Starting Token**: Paste your initial token from Facebook here.
 - **App name**: Copy+paste your app name here as well.

Everything else can be left as default. Click _Deploy App_.

The deployment process can take a minute or so. Once complete, you'll see a button to visit your new application.

## Configuration options

Instagram Token Agent is designed to be configured using Heroku's web UI or CLI. It understands the following environment variables:

| Key  | Description  | Default  |
|---|---|---|
| ALLOWED_DOMAINS  | White-list of the domains that can request the token via JS snippet or JSON object | none (any domain is allowed)  |
| REFRESH_MODE  | How should the refresh schedule work? Currently, only 'cron' is allowed, which refreshes on a set schedule | `cron`  |
| REFRESH_FREQUENCY  | How often should we refresh the token? Currently 'daily', 'weekly', 'monthly' are supported.  | `weekly`  |
| JS_CONSTANT_NAME | Set the name of the constant provided by the JS snippet  | `InstagramToken` |

## To do

This is a first cut of this application, and there are still a lot of things to be done:

 - Add tests (!)
 - Improve documentation
 - Investigate a better scheduling/refresh solution
 - Work out a nice way to trigger the refresh tasks within the app or in heroku
 - Add a switch to turn the 'hello world' pages off in production
