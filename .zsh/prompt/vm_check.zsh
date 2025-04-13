#!/usr/bin/env zsh

# Cache file location
local VM_CHECK_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/vm_check_cache.zsh"

# Function to detect virtualization (runs only once)
function _detect_virtualization() {
  # Try systemd-detect-virt first
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    local sd_virt=$(systemd-detect-virt 2>/dev/null)
    [[ "$sd_virt" != "none" ]] && { echo "$sd_virt"; return }
  fi

  # Check CPU vendor in /proc/cpuinfo
  if [[ -f /proc/cpuinfo ]]; then
    case "$(grep -m1 'hypervisor vendor' /proc/cpuinfo 2>/dev/null)" in
      *KVM*)      echo "kvm";    return ;;
      *VMware*)   echo "vmware"; return ;;
      *Microsoft*|*Hyper-V*) echo "hyperv"; return ;;
      *Xen*)      echo "xen";    return ;;
      *QEMU*)     echo "qemu";   return ;;
    esac
  fi

  # Check /sys/hypervisor
  if [[ -d /sys/hypervisor ]] && [[ -f /sys/hypervisor/type ]]; then
    case "$(</sys/hypervisor/type 2>/dev/null)" in
      xen) echo "xen"; return ;;
      kvm) echo "kvm"; return ;;
    esac
  fi

  # Check DMI/sysfs
  if [[ -f /sys/class/dmi/id/product_name ]]; then
    case "$(</sys/class/dmi/id/product_name 2>/dev/null)" in
      *[Vv]irtual[Mm]achine*|*KVM*|*QEMU*|*VMware*)
        echo "${(L)$(</sys/class/dmi/id/product_name)}" | tr ' ' '-'
        return
        ;;
    esac
  fi

  # WSL detection
  if [[ -f /proc/version ]] && grep -qi "microsoft" /proc/version 2>/dev/null; then
    [[ $(uname -r) == *microsoft* ]] && echo "wsl2" || echo "wsl1"
    return
  fi

  # Container detection (multiple methods)
  if [[ -f /.dockerenv ]]; then
    echo "container"
    return
  fi

  if [[ -f /proc/1/cgroup ]] && grep -q "docker\|lxc\|kubepods" /proc/1/cgroup 2>/dev/null; then
    echo "container"
    return
  fi

  # User-mode Linux
  [[ $(uname -r) == *uml* ]] && { echo "uml"; return }

  echo "none"
}

# Main function to get virtualization status
function get_virtualization_status() {
  # Use cached result if available
  if [[ -f "$VM_CHECK_CACHE" ]]; then
    source "$VM_CHECK_CACHE"
    [[ -n "$VIRTUALIZATION_TYPE" ]] && return
  fi

  # Detect and cache the result
  local virt_type=$(_detect_virtualization)
  typeset -g VIRTUALIZATION_TYPE="$virt_type"
  typeset -g IS_VIRTUALIZED="false"

  [[ "$virt_type" != "none" ]] && IS_VIRTUALIZED="true"

  # Cache the result
  mkdir -p "${VM_CHECK_CACHE:h}"
  echo "VIRTUALIZATION_TYPE='$VIRTUALIZATION_TYPE'" > "$VM_CHECK_CACHE"
  echo "IS_VIRTUALIZED='$IS_VIRTUALIZED'" >> "$VM_CHECK_CACHE"
}

# Initialize on load
get_virtualization_status

