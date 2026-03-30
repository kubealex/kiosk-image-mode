FROM registry.redhat.io/rhel10/rhel-bootc:10.1

# =============================================================================
# SYSTEM PACKAGES
# Install GNOME desktop environment and utilities.
# Packages are installed and cache cleaned in a single layer to minimize image size.
# gnome-initial-setup and gnome-tour are removed to suppress first-boot pop-ups.
# =============================================================================
COPY etc/yum.repos.d/ /etc/yum.repos.d/

RUN dnf -y install tmux mkpasswd git unzip curl insights-client flightctl-agent && \
    dnf group install -y --allowerasing "GNOME" "Fonts" && \
    dnf remove -y gnome-initial-setup gnome-tour && \
    dnf clean all

# =============================================================================
# DEFAULT USER
# Create the 'redhat' user with a hashed password, added to the wheel group.
# Passwordless sudo is granted via a dedicated sudoers drop-in file.
# =============================================================================
RUN pass=$(mkpasswd --method=SHA-512 --rounds=4096 redhat) && \
    useradd -m -G wheel redhat -p "$pass"

# =============================================================================
# GRAPHICAL TARGET
# Set graphical.target as the default systemd target so the system boots into
# the GNOME desktop environment.
# =============================================================================
RUN systemctl set-default graphical.target

# =============================================================================
# DASH-TO-DOCK EXTENSION
# Downloaded to /usr/share/dash-to-dock for provisioning via tmpfiles.d.
# Version: extensions.gnome.org-v103
# =============================================================================
RUN mkdir -p /usr/share/dash-to-dock && \
    curl -fsSL \
        https://github.com/micheleg/dash-to-dock/releases/download/extensions.gnome.org-v103/dash-to-dock@micxgx.gmail.com.zip \
        -o /tmp/dash-to-dock.zip && \
    unzip /tmp/dash-to-dock.zip -d /usr/share/dash-to-dock && \
    rm /tmp/dash-to-dock.zip

# =============================================================================
# CONFIGURATION OVERLAY
# A single COPY drops the entire /etc/ tree and tmpfiles.d from the repo.
# Each subdirectory maps directly to its target path on the running system,
# making it easy to see and extend what is being configured:
#
#   etc/dconf/        — GNOME/dconf system settings
#   etc/gdm/          — GDM autologin
#   etc/ostree/       — Container registry credentials
#   etc/rhc/          — Red Hat Insights registration credentials
#   etc/sudoers.d/    — Passwordless sudo for wheel group
#
# tmpfiles.d/ provisions the dash-to-dock extension into the user profile
# directory at first boot.
#
# NOTE: auth.json and .rhc_connect_credentials must be populated before
# building. See README.md for details.
# =============================================================================
COPY etc/ /etc/
COPY usr/ /usr/

# =============================================================================
# SYSTEMD UNITS
# rhc-connect.service registers the machine with Red Hat Insights on first boot.
# Enabled here after the /usr tree is already in place via the COPY above.
# =============================================================================
RUN systemctl enable rhc-connect flightctl-agent && \
    touch /etc/rhc/.run_rhc_connect_next_boot

# =============================================================================
# DCONF COMPILATION
# Must run after the /etc/dconf tree is in place to compile the binary database
# that GNOME reads at session start.
# =============================================================================
RUN dconf update
