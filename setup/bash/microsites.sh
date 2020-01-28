WP_CONTENT_PATH=$BASE_SCRIPT_PATH/wp-container-microsites/wp-content
BUILD_PLUGINS=(
)
BUILD_THEMES=(
    nbc-parallax
    project-innovation
    supporting-our-schools
)

for plugin in ${BUILD_PLUGINS[*]}
do
    pushd ${WP_CONTENT_PATH}/plugins/${plugin} && \
        npm install --quiet && \
        npm run build -s && \
    popd
done

for theme in ${BUILD_THEMES[*]}
do
    pushd ${WP_CONTENT_PATH}/themes/${theme} && \
        npm install --quiet && \
        npm run build && \
    popd
done
