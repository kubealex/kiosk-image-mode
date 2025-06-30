FROM registry.stage.redhat.io/rhel10/rhel-bootc:10.0

RUN dnf group install -y GNOME \
    && dnf -y install tmux mkpasswd firefox \
    && systemctl set-default graphical.target \
    && dnf -y clean all

RUN pass=$(mkpasswd --method=SHA-512 --rounds=4096 redhat) && useradd -m -G wheel bootc-user -p $pass \
    && echo "%wheel        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/wheel-sudo

COPY ./nginx.container /usr/share/containers/systemd/nginx.container
RUN ln -s /usr/share/containers/systemd/nginx.container /usr/lib/bootc/bound-images.d/nginx.container
