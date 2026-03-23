#!/bin/sh

export LANG=C

#arguments
cache_path="$1"
cache_timeout="$2"
location="$3"
textbox_format="$4"
tooltip_format="$5"

textbox_format="${location}${textbox_format}"
tooltip_format="${location}${tooltip_format}"
fullcast_format="${location}"

textbox_cache="${cache_path}/textbox"
tooltip_cache="${cache_path}/tooltip"
fullcast_cache="${cache_path}/fullcast"

url="https://wttr.in"

textbox=""
textboxold="$textbox"

tooltip=""
tooltipold="$tooltip"

textboxsig="wttr::textbox"
tooltipsig="wttr::tooltip"

cycles_per_second=2

cycles=$(( cycles_per_second * cache_timeout ))

sig_handler () {
    cont=1
}

cont=0

# usage: get_weather "cache_file" "format"
get_weather () {
    format=""
    cache_file="$1"
    shift
    tmp="${cache_file}_tmp"
    if [ -n "$1" ]; then
        format="$1"
        shift
    fi
    curl \
        --silent --show-error --fail --get --compressed \
        -o "$tmp" \
        -X GET "${url}/${format}" && mv "$tmp" "$cache_file"
}

main () {
    if [ ! -f "$textbox_cache" ]; then
        get_weather "$textbox_cache" "$textbox_format"
    fi
    if [ ! -f "$tooltip_cache" ]; then
        get_weather "$tooltip_cache" "$tooltip_format"
    fi
    if [ ! -f "$tooltip_cache" ]; then
        get_weather "$fullcast_cache" "$fullcast_format"
    fi
    i=0
    while [ "$cont" -eq 0 ]; do
        textbox=$(head "$textbox_cache")
        tooltip=$(head "$tooltip_cache")
        if [ "$textbox" != "$textboxold" ]; then
            awesome-client "awesome.emit_signal('$textboxsig','$textbox')"
            textboxold="$textbox"
        fi
        if [ "$tooltip" != "$tooltipold" ]; then
            awesome-client "awesome.emit_signal('$tooltipsig','$tooltip')"
            tooltipold="$tooltip"
        fi
        if [ "$i" -le "$cycles" ]; then
            i=$(( i + 1))
        else
            get_weather "$textbox_cache" "$textbox_format"
            get_weather "$tooltip_cache" "$tooltip_format"
            get_weather "$fullcast_cache" "$fullcast_format"
            i=0
        fi
        sleep 0.5
    done
}

trap 'sig_handler' INT TERM HUP

main > /dev/null 2>&1
