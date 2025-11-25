FROM ubuntu:24.04

RUN yes | unminimize

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y \
    wget \
    bash-completion \
    vim \
    git \
    tree

RUN apt-get install -y \
    bsdmainutils
    # util-linux \

# User setup
RUN useradd -ms /bin/bash fruchix
USER fruchix
WORKDIR /home/fruchix

# setup fake directories
RUN bash -c 'mkdir -p "$HOME"/{Documents/{projects,work,tools},.config,.local/bin,Downloads}'
RUN bash -c 'mkdir -p "$HOME/Documents/tools"/{tree,bat,htop}'
RUN bash -c 'mkdir -p "$HOME/Documents/projects"/{cheatsheets,SIU,wikigraph,dotfiles}'
RUN bash -c 'mkdir -p "$HOME/Documents/work"/{LibFabric,OpenMPI}'
RUN bash -c 'mkdir -p /tmp/mounts/{google-drive,workshare}'
RUN bash -c 'echo "# Project Documentation" > /tmp/mounts/google-drive/project.md'
RUN bash -c 'echo "" >> /tmp/mounts/google-drive/project.md'
RUN bash -c 'echo "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum." >> /tmp/mounts/google-drive/project.md'
RUN bash -c 'touch "$HOME/Downloads/tree-2.0.4.tar.gz"'

# copy star into projects
COPY --chown=fruchix:fruchix . /home/fruchix/Documents/projects/star

# install star
RUN cd /home/fruchix/Documents/projects/star && \
    ./configure --prefix=/home/fruchix/.local && \
    ./install.sh

# setup bashrc
RUN echo "export PS1='\n\[\033[01;34m\] \w \$\[\033[00m\] '" >> /home/fruchix/.bashrc
RUN echo 'export PATH=$HOME/.local/bin:$PATH' >> /home/fruchix/.bashrc
RUN echo 'eval "$(star init bash)"' >> /home/fruchix/.bashrc

CMD ["bash"]
