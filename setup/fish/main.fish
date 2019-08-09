set -l WP_CONTENT_PATH $BASE_SCRIPT_PATH/wp-container/wp-content
set -l BUILD_PLUGINS \
    byline-manager \
    nbc-library \
;

set -l BUILD_THEMES \
    nbc-station \
;

for plugin in $BUILD_PLUGINS
    pushd $WP_CONTENT_PATH/plugins/$plugin
        npm install --quiet
        npm run build -s
    popd
end

for theme in $BUILD_THEMES
    pushd $WP_CONTENT_PATH/themes/$theme
        npm install --quiet
        npm run build
    popd
end