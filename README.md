
# NBC WordPress Docker Setup

- [NBC WordPress Docker Setup](#nbc-wordpress-docker-setup)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Troubleshooting](#troubleshooting)
  - [Questions?](#questions)

A Docker Container which setups up WordPress with PHP-FPM, Nginx with a self-signed SSL certificate, WordPress CLI, MariaDB, memcache and phpMyAdmin. In addition, the setup script will install the WordPress VIP MU Plugins and the NBCOTS VIP repository if you have access. You will need to learn the Docker Compose commands to spin down containers and spin them back up.

## Prerequisites

Here are a list of frameworks you need to have pre-installed on your machine. If you happen to shortcut the installation the local development environment will not run properly.

* __Homebrew__
  * ```/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"```
* __PHP__
    * ```brew install php```
    * Installing PHP 7.2+? You will need to disable PCL by creating an `ini` file.
        1. Copy and paste the following commands into Terminal after you've installed PHP:
        ```
        cd /usr/local/etc/php/7.3/conf.d
        touch myphp.ini
        ```
        2. Copy the text below:
        ```
        ; Fix for PCRE "JIT compilation failed" error
        [Pcre]
        pcre.jit=0
        ```
        3. Paste into `myphp.ini` file you just created.
* __nvm - Node Version Manager__
    * https://github.com/nvm-sh/nvm
* __npm - Node Package Manager__
    * ```brew install npm```
* __composer__
    * ``` brew install composer```
* __Docker for macOS__
    * https://docs.docker.com/docker-for-mac/install/

## Installation

1. Start Docker Desktop and wait till the status reads `Docker Desktop is running`
2. In Terminal, run the following command:
```./local_init.sh```
3. Once setup has been completed, add this line above `require_once( ABSPATH . 'wp-settings.php' );` in your `wp-config.php`:

`require_once( ABSPATH . 'wp-content/vip-config/vip-config.php' );`

4. Visit `http://localhost/wp-admin` on your browser and sign in using credentials stored inside of the `.env` file.
5. Activate the [NBC Theme](#enable-theme/wp-plugin-error).
6. All your work should be within the `wp-content` folder. __DO NOT__ commit to the main Docker Container repository.


## Troubleshooting

### Removing Orphan Containers

Run the following commands to ensure orphaned containers are removed.

```bash
docker-compose down --remove-orphans
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
```

### Enable theme/WP Plugin error

If you get an error similar to:

`Uncaught Error: Call to undefined function NBC\get_site_host() ...`

It's likely the `nbc-station` theme didn't get activated. Run this to fix:

```
docker-compose run wp-cli theme enable nbc-station --network
docker-compose run wp-cli theme activate nbc-station
```

## Questions?

Have you got questions? Problems with the installation? Use Google, ask your neighbor or ask questions in Slack.
