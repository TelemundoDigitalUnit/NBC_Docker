set -x PROJECT "main"
argparse --name=local_init 'p/project=' -- $argv

if [ "$_flag_project" != "" ]
    set -x $PROJECT $_flag_project
end
