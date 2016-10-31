# bash-dcos
Bash completion for dcos cli

## Requirements
 * [jq](https://stedolan.github.io/jq) JSON processor

## Installation

Download [`dcos_completion.sh`](https://github.com/stuartleeks/bash-dcos/blob/master/dcos_completion.sh) to `/etc/bash_completion.d`

```bash
    sudo curl -o /etc/bash_completion.d/dcos_completion.sh https://raw.githubusercontent.com/stuartleeks/bash-dcos/master/dcos_completion.sh
```

## Notes
This is an early version of the completion, but the main portions of the major commands are in place. If you run into any functionality that is missing or not behaving as expected then please file an issue :-)