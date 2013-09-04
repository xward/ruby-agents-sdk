# @markup markdown
# @title Guidelines
# @author Xavier Demorpion

# Guidelines #

There are a few guidelines your agent must follow if it is to run correctly on the MDI infrastructure.

## Stateless agents ##

Your agent must be stateless.

In other words, the actions trigerred by an event depends only on the nature of the event (and the data it carries) and not on the previous processed events.

You must not use global variables or similar patterns (class variables, module variables...) to store data between two requests.

The reason for this is that your agent will live in a cloud where multiple instances of your agent will run simultaneously. These instances can not share data between themselves.

If you need some kind of "history" in your agent, you must attach this history to the messages exchanged. Cookies in messages (see the Protogen guide) are a way of implementing this.

## Use the provided API ##

The VM gives you access to the API to interact with a redis database, to write logs... If you want to interact with a redis database or write logs, please use this API and not your custom solution.

Still, the SDK is an open environment and you can use your own Ruby solutions. Note however that any of your custom solutions can be subject to validation before being accepted by MDI.

## Other useful information ##

### Logs ###

In production environments, ony log levels "information", "warning" and "error" are actually written. "debug" log level is discarded.

You should use the correct log level to have useful and helpful logs:

- `log.debug` is meant to display very detailed information about the inner workings of your agent. You can use it in debug phases to print variable values or other detailed information that helps you ensuring that your agent is doing what you're expecting it to do, without worrying that this information will clutter your production log file.
- `log.info` is a higher level of logging used to print information about what your agent is doing. Such logs are expected to be useful to check at which point of the processing of a message your agent is.
- `log.warn` is used to log warnings about something that shouldn't have happened.
- `log.error` is used to log errors that your agent can handle.
- `log.fatal` is used to log errors that your agent can not handle (so your agent will abort its processing after encountering such an error).

Correct usage of logs will greatly help you debug your agent both in your development phase and in the production phase.