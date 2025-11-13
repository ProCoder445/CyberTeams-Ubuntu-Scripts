#!/usr/bin/env bash
#
# manage-users.sh
# Mint/Debian/Ubuntu-style script to:
# - accept a list of "good" users
# - set passwords for them (excluding the current user)
# - remove local non-system users not in that list (excluding current user/root)
# - prompt to add users until you type literal "NULL"
# - accept a list of admins and ensure admin membership and password state
#
# Run as root. Test on a non-production system first.

set -o errexit
set -o nounset
set -o pipefail

# === Configuration ===
# Minimum UID to consider as a "normal" (non-system) user on Debian/Ubuntu family
MIN_USER_UID=1000
SUDO_GROUP="sudo"   # Mint/Ubuntu default admin group. Change to "admin" if you use that.
PASSWORD_MAX_AGE_DAYS=365  # for password age check when validating admin passwords

# === Helpers ===

trim() {
  # trim whitespace
  local s="$*"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# Convert input string to array of unique usernames
to_user_array() {
  local input="$1"
  # replace commas with spaces, then split
  # remove empty items and de-dup
  read -r -a arr <<< "$(tr ',' ' ' <<< "$input")"
  declare -A seen
  local out=()
  for u in "${arr[@]}"; do
    u="$(trim "$u")"
    if [[ -n "$u" && -z "${seen[$u]:-}" ]]; then
      seen[$u]=1
      out+=("$u")
    fi
  done
  printf "%s\n" "${out[@]}"
}

# Check if a user exists
user_exists() {
  local u="$1"
  if getent passwd "$u" > /dev/null; then
    return 0
  else
    return 1
  fi
}

# Get UID of a user, or empty
user_uid() {
  local u="$1"
  getent passwd "$u" | cut -d: -f3 || true
}

# Add user if missing (create home)
ensure_user() {
  local u="$1"
  if user_exists "$u"; then
    echo "User '$u' already exists."
  else
    echo "Creating user '$u'..."
    useradd -m -s /bin/bash "$u"
    echo "User '$u' created."
  fi
}

# Prompt and set password (secure prompt) for a user
set_password_for_user() {
  local u="$1"
  local skip_if_current="$2" # if "yes" skip when u == CURRENT_USER
  if [[ "$skip_if_current" == "yes" && "$u" == "$CURRENT_USER" ]]; then
    echo "Skipping password set for the current user: $CURRENT_USER"
    return
  fi

  echo
  echo "Set password for user: $u"
  # prompt twice like passwd would
  while true; do
    read -r -s -p "Password for $u: " p1; echo
    read -r -s -p "Confirm password for $u: " p2; echo
    if [[ "$p1" != "$p2" ]]; then
      echo "Passwords do not match — try again."
    elif [[ -z "$p1" ]]; then
      echo "Empty password not allowed — try again."
    else
      # Use chpasswd (input "user:password")
      printf '%s:%s\n' "$u" "$p1" | chpasswd
      echo "Password for $u set."
      break
    fi
  done
}

# List removable users (UID >= MIN_USER_UID) excluding root and current
list_removable_users() {
  awk -F: -v minuid="$MIN_USER_UID" -v cur="$CURRENT_USER" '
    $3 >= minuid && $1 != "root" && $1 != cur { print $1 }
  ' /etc/passwd
}

# Safely delete a user (and its home)
delete_user() {
  local u="$1"
  if [[ "$u" == "root" || "$u" == "$CURRENT_USER" ]]; then
    echo "Refusing to delete root or current user: $u"
    return 1
  fi
  if ! user_exists "$u"; then
    echo "User $u does not exist; skipping deletion."
    return 0
  fi
  echo "Deleting user $u and their home directory..."
  userdel -r "$u"
  echo "Deleted $u."
}

# Check if user is in a given group
user_in_group() {
  local u="$1"
  local g="$2"
  getent group "$g" | awk -F: -v user="$u" '{ split($4, a, ","); for(i in a) if(a[i]==user) { print "yes"; exit } }'
}

# Ensure group membership
ensure_group_membership() {
  local u="$1"
  local g="$2"
  if id -nG "$u" | tr ' ' '\n' | grep -qx "$g"; then
    echo "$u is already in $g"
  else
    echo "Adding $u to $g"
    usermod -aG "$g" "$u"
  fi
}

# Remove from group
remove_from_group() {
  local u="$1"
  local g="$2"
  if id -nG "$u" | tr ' ' '\n' | grep -qx "$g"; then
    echo "Removing $u from $g"
    gpasswd -d "$u" "$g" || usermod -G "$(id -nG "$u" | sed "s/\b${g}\b//g" | tr ' ' ',')" "$u" || true
  else
    echo "$u is not in $g"
  fi
}

# Check password "state" for a user: not locked and last change within age
check_password_state() {
  local u="$1"
  # passwd -S username -> fields: name status date ... status P (password set) or L (locked)
  local line
  if ! line=$(passwd -S "$u" 2>/dev/null); then
    echo "Could not get passwd -S for $u"
    return 2
  fi
  local status
  status=$(awk '{print $2}' <<<"$line")
  if [[ "$status" == "L" ]]; then
    echo "locked"
    return 1
  fi

  # Check last change days: chage -l username
  # chage -l prints "Last password change : <date>" or "never"
  local lastchg
  lastchg=$(chage -l "$u" | awk -F: '/Last password change/{print $2}' | sed 's/^ *//;s/ *$//')
  if [[ -z "$lastchg" || "$lastchg" == "never" ]]; then
    echo "no-change"
    return 3
  fi

  # Convert date to days ago
  # Expect format like "Jul 01, 2025" or "2025-07-01" depending on locale; try parsing robustly
  local lastchg_epoch
  lastchg_epoch=$(date -d "$lastchg" +%s 2>/dev/null || true)
  if [[ -z "$lastchg_epoch" ]]; then
    echo "unknown-date"
    return 4
  fi
  local now_epoch
  now_epoch=$(date +%s)
  local days_diff=$(( (now_epoch - lastchg_epoch) / 86400 ))
  if (( days_diff > PASSWORD_MAX_AGE_DAYS )); then
    echo "old ($days_diff days)"
    return 5
  fi

  echo "ok ($days_diff days)"
  return 0
}

# === Start ===

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Use sudo."
  exit 1
fi

CURRENT_USER="$(whoami)"
echo "Current user (will be excluded from destructive operations): $CURRENT_USER"
echo

# --- 1) Ask for list of good users ---
echo "Enter a list of GOOD users (space or comma separated). Include admins in this list."
echo "Example: alice,bob,charlie"
read -r GOOD_INPUT
mapfile -t GOOD_USERS < <(to_user_array "$GOOD_INPUT")

if [[ ${#GOOD_USERS[@]} -eq 0 ]]; then
  echo "No good users provided. Exiting."
  exit 1
fi

echo "Good user list:"
printf ' - %s\n' "${GOOD_USERS[@]}"
echo

# Ensure listed users exist (create if missing), and set password for them (excluding current user)
for u in "${GOOD_USERS[@]}"; do
  ensure_user "$u"
done

echo
echo "Now setting passwords for listed users (except current user: $CURRENT_USER)."
for u in "${GOOD_USERS[@]}"; do
  set_password_for_user "$u" "yes"
done

# --- 2) Remove users who are not in that list ---
echo
echo "Computing removable users (UID >= $MIN_USER_UID), excluding root and current user..."
mapfile -t EXISTING_REMOVABLE < <(list_removable_users)

# Build associative set of good users for quick membership test
declare -A good_set
for u in "${GOOD_USERS[@]}"; do
  good_set["$u"]=1
done

echo
for u in "${EXISTING_REMOVABLE[@]}"; do
  if [[ -n "${good_set[$u]:-}" ]]; then
    echo "Keeping $u (in good list)."
  else
    # Safety: do not remove system-critical or unknown special users
    # Double-check UID again
    uid=$(user_uid "$u")
    if [[ -z "$uid" ]]; then
      echo "Could not determine UID for $u; skipping."
      continue
    fi
    if (( uid < MIN_USER_UID )); then
      echo "Skipping removal of $u (uid $uid < $MIN_USER_UID)."
      continue
    fi

    # Delete user
    delete_user "$u"
  fi
done

# --- 3) Ask to add users until "NULL" ---
echo
echo "Now: enter usernames to ADD one-by-one. Type literal 'NULL' to stop adding."
while true; do
  read -r -p "Add user (or NULL to finish): " newu
  newu="$(trim "$newu")"
  if [[ "$newu" == "NULL" ]]; then
    echo "Add loop finished."
    break
  fi
  if [[ -z "$newu" ]]; then
    echo "Empty input; try again."
    continue
  fi
  if user_exists "$newu"; then
    echo "User $newu already exists."
  else
    useradd -m -s /bin/bash "$newu"
    echo "User $newu created."
    set_password_for_user "$newu" "no"
  fi
done

# --- 4) Ask for list of admins and verify ---
echo
echo "Enter a list of ADMIN users (space or comma separated). These will be ensured to be in the '$SUDO_GROUP' group."
read -r ADMIN_INPUT
mapfile -t ADMIN_USERS < <(to_user_array "$ADMIN_INPUT")

declare -A admin_set
for a in "${ADMIN_USERS[@]}"; do admin_set["$a"]=1; done

echo
echo "Checking admin list and password states..."
# For each admin: ensure user exists, ensure in sudo group, check password state
for a in "${ADMIN_USERS[@]}"; do
  if [[ -z "$a" ]]; then continue; fi
  if ! user_exists "$a"; then
    echo "Admin user $a does not exist. Creating..."
    useradd -m -s /bin/bash "$a"
    echo "Please set a password for newly created admin $a."
    set_password_for_user "$a" "no"
  fi

  echo
  echo "Admin check for $a:"
  # A) good passwords: check status (not locked) and last change within threshold
  pstate=$(check_password_state "$a" || true)
  echo "  Password state: $pstate"

  # B) are admins (in sudo)
  if id -nG "$a" | tr ' ' '\n' | grep -qx "$SUDO_GROUP"; then
    echo "  $a is already in $SUDO_GROUP"
  else
    echo "  $a is not in $SUDO_GROUP. Adding..."
    ensure_group_membership "$a" "$SUDO_GROUP"
  fi
done

# For users who are NOT supposed to be admins: if they're in sudo, remove them
echo
echo "Ensuring users that are NOT in the admin list are NOT in $SUDO_GROUP..."
# build good users set if not yet
# we'll consider all system users with uid >= MIN_USER_UID
mapfile -t ALL_NORMAL_USERS < <(awk -F: -v minuid="$MIN_USER_UID" '$3 >= minuid { print $1 }' /etc/passwd)
for u in "${ALL_NORMAL_USERS[@]}"; do
  # skip if in admin list
  if [[ -n "${admin_set[$u]:-}" ]]; then
    continue
  fi
  # skip root and current user
  if [[ "$u" == "root" || "$u" == "$CURRENT_USER" ]]; then
    continue
  fi
  # if user is in sudo group, remove them
  if id -nG "$u" | tr ' ' '\n' | grep -qx "$SUDO_GROUP"; then
    echo "User $u is NOT supposed to be admin but is in $SUDO_GROUP. Removing..."
    remove_from_group "$u" "$SUDO_GROUP"
  fi
done

echo
echo "All operations complete."
echo "Summary:"
echo " - Good users: ${GOOD_USERS[*]}"
echo " - Admins: ${ADMIN_USERS[*]}"
echo " - Current user (excluded): $CURRENT_USER"
echo
echo "If you need a dry-run version or want changes (e.g. different admin group name), ask and I can adjust the script."

exit 0
