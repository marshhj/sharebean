# SHAREBEAN

## About
Sharebean is a tool to share files with other.  
Base on [redbean](https://redbean.dev/), [tus](https://github.com/tus/tus-js-client), [router.lua](https://github.com/APItools/router.lua), [vue2](https://v2.vuejs.org/), [wing.css](https://kbrsh.github.io/wing/).  

## Build
Just run `build.bat` or `build.sh`


## Usage
```bash
# base usage
# win
    sharebean
# linux
    ./sharebean


# set config
# win
    sharebean config.lua
# linux
    ./sharebean config.lua
```

## Folder setting
When you create a folder, you can set the folder password and some rules to hide files.  

### Hide rules.
```bash
#examples:
# hide all
*

# hide *.lua
*.lua

# just show *.jpg
*
*.jpg


# hide scripts
*.js
*.lua

# just show image
*
*.jpg
*.png
*.gif
*.webp
```

## Config
```lua
VERSION = '0.0.1'               --version
DATA_PATH = "data/"             --share data path
TEMP_PATH = "data/_temp/"       --temp path,for tus upload job
SUPER_PWD = "sharebean"         --invite code to create folder
MAX_PAYLOAD_SIZE = 65535        --max payload size for tus upload
HTTP_PORT = 8080                --http port
CODE_CACHE = true               --enable code cache
LOG_PATH = ''                   --log path
```