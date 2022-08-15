# Authentication and authorization backend for small scale deployments

This project is most certainly not safe for production!

Author is a barely competent hobbyist who knows just enough to be dangerous.
Like a toddler running around breaking stuff.
If you find any glaring security holes, please be nice and report them via issues.
There is no value to be gained exploiting those.


## Rationale

Most existing open source auth backends are too large and too complex for a
single person to understand. They all seem to target medium and large
businesses (often hoping to gain paying customers for author's startup/consultancy).

Web interface for accounts/roles/access configuration seems to be the default
approach. That's understandable in enterprise environment (less skills
required to add a new user), but feels bothersome on a small scale:
it's a lot faster to write all configuration in text editor, commit it to
revision control and not to touch again for a long time.

This app aims to be simple and understandable, to favor file based configs
over web UI and never to become a point of vendor lock-in.
