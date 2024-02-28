# Copyright 2024 ACCESS-NRI and contributors. See the top-level COPYRIGHT file for details.
# SPDX-License-Identifier: Apache-2.0

# Add new collaborators to an experiment.
# A collaborator is a member of the project that needs write access to the experiment
#
# Input:
# experiment: the experiment name
# users: the NCI login IDs of the new users.

# Read in command line arguments (code is a mix from https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash and man getopt example) 
help_text=0
SHORT=e:u:h
LONG=experiment:,users:,help

PARSED=$(getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@")
if [[ $? != 0 ]] ; then echo "Wrong arguments. Terminating..." >&2 ; exit 1 ; fi


eval set -- "$PARSED"

while true; do
    case "$1" in
	-e|--experiment) exp_name="$2"; shift 2 ;;
	-u|--users) users=(${2//,/ }); shift 2;;
	-h|--help) help_text=1; shift ;;
	--) shift; break ;;
	*) echo "Programming error"; exit 1 ;;
    esac
done

if [[ ${help_text} == 1 ]]; then
    echo "The optional arguments are:"

    # Experiment name
    echo "-e, --experiment= followed by the name of the experiment. "
    echo "    The name of the experiment should follow the format YYYY-MM-DD_<exp-title>."
    echo
    # Users
    echo "-u, --users=  followed by the NCI login IDs of the new users."
    echo
    # Help
    echo "-h, --help  writes this help text"
    echo

    exit 0
fi

# Parameters:
wg_project=$(stat -c '%G' $0)
wg_root=/g/data/${wg_project}

if [ ! -d ${wg_root}/experiments/${exp_name} ]; then
    echo "FAIL: the experiment directory ${wg_root}/experiments/${exp_name} does not exist."
    exit 1
fi

acl_filename=${wg_root}/admin/acl_files/${exp_name}
if [ ! -f $acl_filename ]; then
    echo "FAIL: missing ACL file ${acl_filename}."
    exit 1
fi

# Add ACLs for all the user IDs provided with rwx access
for user in ${users}; do
    acl=user:${user}:rwx
    cat >> ${acl_filename} << EOF_gp
${acl}
EOF_gp
done

# Set the ACLs
setfacl --restore=${acl_filename}