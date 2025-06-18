FROM registry.redhat.io/rhel9/rhel-bootc:9.6
#FROM registry.redhat.io/rhel10/rhel-bootc:10.0

RUN dnf group install -y GNOME \
    && dnf -y clean all \
    && dnf -y install tmux mkpasswd \
    && systemctl set-default graphical.target

RUN pass=$(mkpasswd --method=SHA-512 --rounds=4096 redhat) && useradd -m -G wheel bootc-user -p $pass \
    && echo "%wheel        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/wheel-sudo
