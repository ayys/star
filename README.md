<h1>star</h1>

star is a Unix CLI tool that allows you to bookmark your favorite folders and instantly navigate to them.

It is written in pure Bash, but can be used with Zsh as long as there is an available Bash version (>= 3.2).

<h2>Table of contents</h2>

- [Features](#features)
- [Installation](#installation)
  - [Requirements](#requirements)
  - [Installing](#installing)
    - [Recommended local installation (from source)](#recommended-local-installation-from-source)
    - [System installation (from source)](#system-installation-from-source)
  - [Uninstalling](#uninstalling)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Contributions and development](#contributions-and-development)
  - [Future work](#future-work)
  - [Pull requests](#pull-requests)
  - [Testing](#testing)
- [Contributors](#contributors)
- [License](#license)

## Features

<details>
  <summary>Dynamically add bookmarks (called "stars")</summary>
  <div align="left">
    <img width="593" height="617" alt="01-dynamically-add" src="https://github.com/user-attachments/assets/5b59adb1-c9d2-461f-a6b9-1c2579c7f8a5" alt="Dynamically add bookmarks" />
  </div>
</details>

<details>
  <summary>Instantly navigate into your favorite directories</summary>
  <div align="left">
    <img width="471" height="345" alt="02-navigate" src="https://github.com/user-attachments/assets/91c7cb10-33e3-457b-a1fa-d7f251d6a53f" />
  </div>

  > The output of `star list` is sorted according to when each element was loaded last (this can be configured).
</details>

<details>
  <summary>Autocompletion is your friend</summary>
  <div align="left">

https://github.com/user-attachments/assets/a3917ccf-4a6a-424d-a729-24860235c83f

  </div>
</details>

<details>
  <summary>Use the generated environment variables to interact with your directories</summary>
  <div align="left">
    <img width="591" height="502" alt="04-envvars" src="https://github.com/user-attachments/assets/096a7078-0e11-4b48-933d-44304ae480af" />
  </div>
</details>

<details>
  <summary>Manage your stars</summary>
  <div align="left">
    <img width="466" height="434" alt="05-management" src="https://github.com/user-attachments/assets/c80ff5c3-9b4b-4248-86b7-1ae9e5e97f59" />
  </div>
</details>

<details>
  <summary>Customize colors, listing and more</summary>
  <div align="left">
    <img width="593" height="718" alt="06-customization" src="https://github.com/user-attachments/assets/b513b556-74d4-4147-8f77-8bfeb89f4abf" />
  </div>
</details>

## Installation

### Requirements

To enable `star` to work properly, ensure your system meets the requirements:
- `GNU coreutils`
- `GNU findutils`
- `util-linux` (with `column`)

Note that `column` should be part of `util-linux`, but on some systems (e.g., older Ubuntu versions), it may be in `bsdmainutils`. `star` verifies `column`'s version output to confirm it belongs to `util-linux`.

<details>
  <summary>Install requirements using apt</summary>

```sh
# install GNU coreutils
apt install coreutils

# install GNU findutils
apt install findutils

# install util-linux
# On some versions of util-linux, column is not included, BUT the util-linux version of column is included in some bsdmainutils versions.
# star will run 'column --version' and check if the output contains "util-linux"
# Ubuntu 22.04, 24.04:
apt install bsdmainutils

apt install util-linux
```

</details>

<details>
  <summary>Install requirements using brew</summary>

When installing GNU softwares with brew, they are prefixed with a `g` to highlight the difference with the default softwares. For example: `gfind`. To solve this, we add a special directory called `gnubin` to the PATH, which contains the default names without the `g`.

```sh
# install GNU coreutils
brew install coreutils
# add the following line to your shell configuration file to enable non g-prefixed softwares
export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"

# install GNU findutils
brew install findutils
# add the following line to your shell configuration file to enable non g-prefixed softwares
export PATH="$(brew --prefix)/opt/findutils/libexec/gnubin:$PATH"

# install util-linux
brew install util-linux
# add the following line to your shell configuration file
export PATH="$(brew --prefix)/opt/util-linux/bin:$PATH"
```

</details>


### Installing

Installation can be done from source or from a release tarball. There are currently not real differences between the two, appart that the release is a bit more lightweight as it does not include documentation and tests. Either method involves two steps: running `./configure` to configure star's installation and then `./install.sh` to install the tool. Currently, `configure` can only be used to set where star will be installed.

Installation steps are the following:
- running `configure` then `install.sh`
- add the `bin` directory (where star is installed) to the PATH (the command to execute will be shown after installation)
- initialize star using `eval "$(command star init YOUR_SHELL_TYPE)"` (see `command star --help`)

#### Recommended local installation (from source)

```sh
git clone https://github.com/Fruchix/star.git
cd star
./configure --prefix=$HOME/.local
./install.sh

# Automatically add bin and initialize star
[[ ":${PATH}:" =~ ":$HOME/.local/bin:" ]] || export PATH="$HOME/.local/bin:$PATH"
eval "$(command star init "$([[ -n $BASH_VERSION ]] && echo bash || echo zsh)")"
```

#### System installation (from source)

```sh
git clone https://github.com/Fruchix/star.git
cd star
./configure         # by default, prefix is set to: /usr/local
sudo ./install.sh

# Automatically add bin and initialize star
[[ ":${PATH}:" =~ ":/usr/local/bin:" ]] || export PATH="/usr/local/bin:$PATH"
eval "$(command star init "$([[ -n $BASH_VERSION ]] && echo bash || echo zsh)")"
```

### Uninstalling

## Configuration

## Troubleshooting

## Contributions and development
<!-- Contributions are welcome! Please submit issues or pull requests to improve star. -->

### Future work

<!-- TODO: checklist -->

### Pull requests

<!-- TODO -->

### Testing

<!-- TODO -->

## Contributors

Special thanks to [@PourroyJean](https://www.github.com/PourroyJean) for contributing to this project.

## License

[Apache](./LICENSE)  
> Copyright 2025 Fruchix
