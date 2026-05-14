S6_OVERLAY_VERSION=$(curl -sL https://raw.githubusercontent.com/just-containers/s6-overlay/refs/heads/master/conf/defaults.mk | grep '^VERSION' | awk '{print $3}')
