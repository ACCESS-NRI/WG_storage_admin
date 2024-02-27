# Copyright 2024 ACCESS-NRI and contributors. See the top-level COPYRIGHT file for details.
# SPDX-License-Identifier: Apache-2.0

# Set the ACLs on an experiment folder. 
# It creates the folder and sets the correct ACLs for the experiment.
# 
# Input: 
# experiment: name of the experience we want to modify the ACLs. Format: YYYY-MM-DD_<exp-title>
# users: NCI login IDs of the collaborators on the experiment
#

# Read in command line arguments (code is a mix from https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash and man getopt example) 
help_text=0
SHORT=e:u:h
LONG=experiment:,users:,help

PARSED=$(getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@")
if [[ $? != 0 ]] ; then echo "Wrong arguments. Terminating..." >&2 ; exit 1 ; fi


eval set -- "$PARSED"

while true; do
    case "$1" in
	-e|--experiments) exp_name="$2"; shift 2 ;;
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
    echo "-u, --users=  followed by the NCI login IDs of the users 
    working on the experiment."
    echo
    # Help
    echo "-h, --help  writes this help text"
    echo

    exit 0
fi


# Parameters:
wg_project=$(stat -c '%G' $0)
wg_root=/g/data/${wg_project}

# Create exp. directory if needed
if [ ! -d ${wg_root}/experiments/${exp_name} ]; then
    mkdir ${wg_root}/experiments/${exp_name}
fi

acl_filename=${wg_root}/admin/acl_files/${exp_name}
if [ ! -f $acl_filename ]; then
    # We need to remove the last line in the created file
    # as getfacl leaves 2 empty lines at the end. This is so one
    # can concatenate the ACLs of several files in one file but it
    # is not our current use case.
    getfacl -p ${wg_root}/experiments/${exp_name} > ${acl_filename}
    sed -i '$ d' ${acl_filename}
fi

# Add ACLs for all the user IDs provided with rwx access
for user in ${users}; do
    acl=user:${user}:rwx
    cat >> ${acl_filename} << EOF_gp
${acl}
EOF_gp
done

# Add ACLs for the writer projects to the ACL file if not already present.
writer_acl=group:${wg_project}_w:rwx
default_writer_acl=default:${writer_acl}

for acl in $writer_acl $default_writer_acl; do
    if ! grep -q -x -F "${acl}" "${acl_filename}"; then
        cat >> ${acl_filename} << EOF_gp
${acl}
EOF_gp
    fi
done

# Set the ACLs
setfacl --restore=${acl_filename}