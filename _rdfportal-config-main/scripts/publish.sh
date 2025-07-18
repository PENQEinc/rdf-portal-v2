set -eu

function exec_ssh() {
  local host=$1
  local cmd=$2

  ssh "$host" "$cmd"
}

function copy_data() {
  local host=$1
  local remote_release_dir=$2

  exec_ssh "$host" "$(cat <<-EOS
    set -eu

    [[ -e "${remote_release_dir}" ]] && rm -rfv "${remote_release_dir}"

    mkdir -pv "${remote_release_dir}"
EOS
)"

  echo "copying database files, please be patient..."
  scp -pr "${RDFPORTAL_PUBLISH_LATEST_RELEASE}/db" "${host}:${remote_release_dir}/"
}

function virtuoso() {
  local host=$1
  local cmd=$2

  case $cmd in
  start)
    exec_ssh $host "$(cat <<-EOS
      set -eu

      cd "${RDFPORTAL_PUBLISH_VIRTUOSO_DIR}"
      docker compose start ${RDFPORTAL_PUBLISH_VIRTUOSO_CONTAINER}
EOS
)"
    ;;
  stop)
    exec_ssh $host "$(cat <<-EOS
      set -eu

      cd "${RDFPORTAL_PUBLISH_VIRTUOSO_DIR}"
      docker compose stop ${RDFPORTAL_PUBLISH_VIRTUOSO_CONTAINER}
EOS
)"
    ;;
  esac
}

function replace() {
  local host=$1
  local remote_release_dir=$2
  local remote_database_dir=$3
  local remote_database_old_dir=$4

  exec_ssh "$host" "$(cat <<-EOS
    set -eu

    dest_dir="$remote_release_dir"
    database_dir="$remote_database_dir"
    database_old_dir="$remote_database_old_dir"

    if [[ -e "\$database_dir" ]]; then
      rm -rfv "\$database_old_dir"
      mv -v "\$database_dir" "\$database_old_dir"
    fi

    [[ -e "\$database_dir" ]] || mkdir -pv "\$database_dir"

    ln -v "\${dest_dir}/db/virtuoso.db" "\${database_dir}/virtuoso.db"
EOS
)"
}

function proxy() {
  local cmd=$1

  case $cmd in
  restart)
    cd "${RDFPORTAL_PUBLISH_PROXY_DIR}"
    docker-compose stop "${RDFPORTAL_PUBLISH_PROXY_CONTAINER}"
    docker-compose rm -f "${RDFPORTAL_PUBLISH_PROXY_CONTAINER}"
    docker-compose up -d "${RDFPORTAL_PUBLISH_PROXY_CONTAINER}"
    ;;
  esac
}

SUFFIX_OLD_DIR=.bk

#for host in rdfp01 rdfp02; do
for host in rdfp02; do
  echo "$host"

  remote_release_dir="${RDFPORTAL_PUBLISH_REMOTE_DIR}/endpoints/${RDFPORTAL_PUBLISH_ENDPOINT_NAME}/releases/${RDFPORTAL_PUBLISH_LATEST_RELEASE##*/}"
  remote_database_dir="${RDFPORTAL_PUBLISH_VIRTUOSO_DIR}/${RDFPORTAL_PUBLISH_ENDPOINT_NAME}/database"
  remote_database_old_dir="${remote_database_dir}${SUFFIX_OLD_DIR}"

  copy_data "$host" "$remote_release_dir"
  virtuoso "$host" stop
  replace "$host" "$remote_release_dir" "$remote_database_dir" "$remote_database_old_dir"
  virtuoso "$host" start

  echo
done

echo "restart proxy"
proxy restart
