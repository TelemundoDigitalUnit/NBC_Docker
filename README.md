# First Time Setup
```
git clone --recursive https://github.com/TelemundoDigitalUnit/NBC_Docker.git
cd NBC_Docker
./local_init.sh
```

# Bringing environments down
```
./dkr.sh down --remove-orphans
```

# Bringing environments up
```
./dkr.sh up -d
```

You will have to wait a while for mysql and apache to come up.

If you learn the various docker commands, you can monitor the status of the containers booting up.

Typically it can take 1-5minutes for MySQL to be ready, the NGINX and WordPress containers will be up almost instantly.

# Troubles?

Open an [issue](https://github.com/TelemundoDigitalUnit/NBC_Docker/issues) in GitHub.

# Looking for the old README?

The old README is still here: [README.old.md](https://github.com/TelemundoDigitalUnit/NBC_Docker/blob/master/README.old.md)
