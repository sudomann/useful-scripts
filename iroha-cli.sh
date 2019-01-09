# DO NOT USE `set -e` Problematic; first issue discovered here was that
# this will stop the peers.list line-by-line reading loop from 
# running after first pass.
# For more info, see: 
# http://mywiki.wooledge.org/BashFAQ/089
# http://mywiki.wooledge.org/BashFAQ/105

# set -e 
halt() {
    printf '%s\n' "$1" >&2
    exit 1
}

# Gets the command name without path
cmd=`basename "$0"`

# Help command output
show_usage(){
echo "
iroha-cli; An production ready alternative to Hyperledger Iroha's convenient 
roha-cli development/testing tool; This is intended for Debian-like systems,
and relies on ed25519-cli (from https://github.com/Warchant/ed25519-cli) being available in \$PATH


${cmd} [--genesis_block] --peers_address <file>
--genesis_block=[false]; Generate genessis block; Existing genesis.block will be overwritten
--peers_address=peers.list: File that contains the peer address(es);
"
}

# Creates genesis.block file
create_genesis_block(){
    echo "Building genesis.block..."
}

# TODO: remove redundant code extracting keys
ssh_keygen_helper(){  
    echo "empty function"
}

# Generates keypairs for each node(peer) and 2 users (admin@test and user@test)
create_keypairs(){
    echo "Generating keypairs for nodes in [${*}]..."
    echo
    node_count=0 # Start counting nodes from 0
    peers_list_file_dir=$(dirname "${1}")/ # get location of peers.list file
    while IFS="" read -r p || [ -n "$p" ]
    do
        echo "--------------------------------------"
        echo "Handling "$p" as node${node_count}"
        if [[ "$p" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\:[0-9]+$ ]]; then
            temp=(`ed25519-cli keygen | grep -E '[a-zA-Z0-9]{64}' -w -o`); 
            echo "${temp[0]}%" > "${peers_list_file_dir}"/node"${node_count}".pub;
            echo "${temp[1]}%" > "${peers_list_file_dir}"/node"${node_count}".priv; 
            #chmod 644 node"${node_count}".pub # public key permission: 644
            #chmod 600 node"${node_count}".priv # private key permission: 600
            ((node_count++))
        else
            halt "ERROR: "$p" failed regex validation!"
        fi
        
    done < "$1"

    echo "Generating keypairs for admin@test and user@test..."

    temp=(`ed25519-cli keygen | grep -E '[a-zA-Z0-9]{64}' -w -o`); 
    echo ""${temp[0]}"%" > "${peers_list_file_dir}"/admin@test.pub;
    echo ""${temp[1]}"%" > "${peers_list_file_dir}"/admin@test.priv;

    temp=(`ed25519-cli keygen | grep -E '[a-zA-Z0-9]{64}' -w -o`); 
    echo ""${temp[0]}"%" > "${peers_list_file_dir}"/user@test.pub;
    echo ""${temp[1]}"%" > "${peers_list_file_dir}"/user@test.priv;
}

# Handle positional arguments
if [[ "$#" -eq 0 ]]; then
    echo "${cmd}: Missing arguments"
    echo "Try '${cmd} -h' for more information."
    exit 1
fi

# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.
peers_list_file=
verbose=0

while :; do
    case "$1" in
        -g|--genesis_block)       # Takes an option argument; ensure it has been specified.
            create_genesis_block
            ;;
        -h|-\?|--help)
            show_usage    # Display a usage synopsis.
            exit
            ;;
        -p|--peers_address)       # Takes an option argument; ensure it has been specified.
            if [[ "$2" == -* || "$2" == "" ]]; then
                halt 'ERROR: "-p|--peers_address" requires a non-empty option argument.'
            else
                peers_list_file=$2
                create_keypairs "$peers_list_file"
                shift
            fi
            ;;
        --peers_address=?*)
            peers_list_file=${1#*=} # Delete everything up to "=" and assign the remainder.
            create_keypairs "$peers_list_file"
            ;;
        --peers_address=)         # Handle the case of an empty --peers_address=
            halt 'ERROR: "--peers_address" requires a non-empty option argument.'
            ;;
        -v|--verbose)
            verbose=$((verbose + 1))  # Each -v adds 1 to verbosity.
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: No more options, so break out of the loop.
            break
    esac

    shift
done
