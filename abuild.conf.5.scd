abuild.conf(5)

# NAME

*abuild.conf* - configuration file for abuild

# DESCRIPTION

*abuild.conf* is the configuration for the *abuild(1)* program.

# FORMAT

The configuration file is parsed as a shell script; variables are defined as
regular shell variables.

For a list of supported variables, see the ENVIRONMENT section of the
*abuild(1)* manual page.

# EXAMPLE

```
PACKAGER_PRIVKEY="/home/jane/.abuild/jane@example.com-87ac18ca.rsa"
PACKAGER="Jane Doe <jane@example.com>"
USE_COLORS=1
```

# SEE ALSO

abuild(1)
