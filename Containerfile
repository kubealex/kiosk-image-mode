<<<<<<< HEAD
FROM registry.stage.redhat.io/rhel10/rhel-bootc:10.0
=======
FROM registry.redhat.io/rhel9/rhel-bootc:9.6
#FROM registry.redhat.io/rhel10/rhel-bootc:10.0
>>>>>>> e69dd247e7db77eeb21f05459b1193350c044c2f

RUN dnf group install -y GNOME \
    && dnf -y clean all \
    && dnf -y install tmux mkpasswd \
    && systemctl set-default graphical.target

RUN pass=$(mkpasswd --method=SHA-512 --rounds=4096 redhat) && useradd -m -G wheel bootc-user -p $pass \
    && echo "%wheel        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/wheel-sudo

COPY ./nginx.container /usr/share/containers/systemd/nginx.container
RUN ln -s /usr/share/containers/systemd/nginx.container /usr/lib/bootc/bound-images.d/nginx.container
