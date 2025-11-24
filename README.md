# star <!-- omit from toc -->

star is an (over-engineered) Unix command line bookmark manager. Dynamically star your favorite folders and instantly navigate (cd) to them.

It is written in Bash, but can be used with Zsh as long as there is an available Bash version (>= 3.2) (the autocompletion uses bash features even for Zsh).

## Table of contents <!-- omit from toc -->

- [Features](#features)
- [Installation](#installation)
  - [Requirements](#requirements)
  - [Installing](#installing)
  - [Uninstalling](#uninstalling)
- [Configuration](#configuration)
  - [Files configuration](#files-configuration)
  - [Runtime configuration](#runtime-configuration)
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
    <img width="593" height="718" alt="06-customization" src="https://github.com/user-attachments/assets/05a6030c-bb90-420a-ae33-09f6fda6226a" />
  </div>
</details>

More documentation:
> Use `star --help` to get more information on the different modes and options.  
> Use `star MODE_NAME --help` to get more information on a specific mode (e.g. `star config --help`)

## Installation

### Requirements

To enable `star` to work properly, ensure your system meets the requirements:
- package `GNU coreutils` (for `realpath`, `printf`, `mkdir`, `rm`, `mv`, `cp`, `echo`, etc.)
- package `GNU findutils` (for `find`)
- command `column` (uses portable options `-t` and `-s` to format the listing, so any version should work)
- `bash >= 3.2` (star uses Bash's autocompletion features, even for Zsh)

On MacOS, the default utils for `find`, `printf`, `echo`, etc. are not GNU versions. You can install the GNU versions using Homebrew (see below). However, MacOS comes with `bash` version 3.2 by default, and has a `column` implementation that has `-t` and `-s` options.

<details>
  <summary>Install requirements using apt</summary>

```sh
# install GNU coreutils
apt install coreutils

# install GNU findutils
apt install findutils

# install column (util-linux version)
apt install bsdmainutils
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

# install column (util-linux version)
brew install util-linux
# add the following line to your shell configuration file
export PATH="$(brew --prefix)/opt/util-linux/bin:$PATH"
```

</details>


### Installing

Installation can be done from source or from a release tarball. There are currently no real differences between the two, appart that the release is a bit more lightweight as it does not include documentation and tests. Either method involves two steps: running `./configure` to configure star's installation and then `./install.sh` to install the tool. Currently, `configure` is only used to set where star will be installed (but in the future, it may enable/disable features).

Installation steps are the following:
- running `configure` then `install.sh`
- add the `bin` directory (where star is installed) to the PATH if it is not alredy in it (the command to execute will be shown after installation)
- initialize star using `eval "$(command star init YOUR_SHELL_TYPE)"` (see `command star --help`)

#### Recommended user installation (from source) <!-- omit from toc -->

```sh
git clone https://github.com/Fruchix/star.git
cd star
./configure --prefix=$HOME/.local
./install.sh

# Automatically add bin and initialize star
[[ ":${PATH}:" =~ ":$HOME/.local/bin:" ]] || export PATH="$HOME/.local/bin:$PATH"
eval "$(command star init "$([[ -n $BASH_VERSION ]] && echo bash || echo zsh)")"

# Do not forget to also add those commands to your ~/.bashrc or ~/.zshrc
```

#### Recommended system installation (from source) <!-- omit from toc -->

```sh
git clone https://github.com/Fruchix/star.git
cd star
./configure         # by default, prefix is set to: /usr/local
sudo ./install.sh

# Automatically add bin and initialize star
[[ ":${PATH}:" =~ ":/usr/local/bin:" ]] || export PATH="/usr/local/bin:$PATH"
eval "$(command star init "$([[ -n $BASH_VERSION ]] && echo bash || echo zsh)")"

# Any user that would want to use star would have to add those commands to their ~/.bashrc or ~/.zshrc
```

### Uninstalling

Each installation of star can be uninstalled using the provided `uninstall.sh` script. This script should be located at `$_STAR_HOME/share/star/uninstall.sh`.

The script requires a manifest file to remove all installed files. This manifest file is created at installation time. It is by default located at `$_STAR_HOME/share/star/manifest.txt`. The uninstallation script uses by default the `_STAR_HOME` variable to locate the manifest file, but if it is unset you can manually pass the manifest file using the `--input` option.

Note that the best way to uninstall star is to have it initialized in the current shell, so that `_STAR_HOME` and other variables such as `$_STAR_DATA_HOME` and `$_STAR_CONFIG_FILE` are set properly.

## Configuration

### Files configuration

star respects the [XDG base directory specification](https://specifications.freedesktop.org/basedir/latest/). By default, star's configuration file is stored in `${XDG_CONFIG_HOME}/star/`, and its data files (the stars) are stored in `${XDG_DATA_HOME}/star/`.

You can override these locations by setting the following environment variables before initializing star:
- `_STAR_CONFIG_HOME`: path to star's configuration file directory (the configuration file is named `config.sh`)
- `_STAR_CONFIG_FILE`: path to star's configuration file (overrides `_STAR_CONFIG_HOME`) (for example to use a custom named configuration file)
- `_STAR_DATA_HOME`: path to star's data files (the stars)

### Runtime configuration

The behaviour of star can be customized with environment variables. Those variables are prefixed with `__STAR_`. They can be exported anywhere, preferably before initializing star (e.g., in your shell configuration file).

However, the recommended way is to run `star config`:
- it opens the configuration file in an editor (as defined by the `EDITOR` environment variable, else in `nano`/`vi`)
- when closing the editor, star is re-initialized to apply the new configuration
- if the configuration file does not exist, star displays the command to create one from a [template](./share/star/config/star_config.sh.template)

When creating the configuration file from a [template](./share/star/config/star_config.sh.template), all variables are well documented with their possible values, default value and description.

Below is the list of the different environment variables that can be used to customize star.

#### Enabling/disabling features <!-- omit from toc -->

There is currently only one feature that can be enabled or disabled manually. When updating the environment variable, the change will only be effective at the next invocation of star.

| Variable | Value | Default | Description |
|----------|-------|---------|-------------|
| `__STAR_ENABLE_ENVVARS` | `yes` / `no` | `yes` | Whether to dynamically set environment variables named after the bookmarks (see [Features](#features)) |

#### Configure the colors <!-- omit from toc -->

Some terminals support 24-bits colors (aka true color), some do not and only support 256 different colors. Star will try to use 24-bits colors by default, and fallback to 256 colors.

| Variable | Value | Default | Description |
|----------|-------|---------|-------------|
| `__STAR_COLOR_NAME` | 24-bits color with format `$'\033[...m'` | `$'\033[38;2;255;131;0m'` | Color for the name of a bookmark |
| `__STAR_COLOR_PATH` | 24-bits color with format `$'\033[...m'` | `$'\033[38;2;1;169;130m'` | Color for the path of a bookmark |
| `__STAR_COLOR_RESET` | 24-bits color with format `$'\033[...m'` | `$'\033[0m'` | The default color to use |
| `__STAR_COLOR256_NAME` | 256 color `$'\033[...m'` | `$'\033[38;5;214m'` | Fallback color for the name of a bookmark |
| `__STAR_COLOR256_PATH` | 256 color `$'\033[...m'` | `$'\033[38;5;36m'` | Fallback color for the path of a bookmark |
| `__STAR_COLOR256_RESET` | 256 color `$'\033[...m'` | `$'\033[0m'` | Fallback default color |

#### Configure the listing <!-- omit from toc -->

| Variable | Value | Default | Description |
|----------|-------|---------|-------------|
| `__STAR_LIST_FORMAT` | string | `<INDEX>:<BR><COLNAME>%f<COLRESET><BR>-><BR><COLPATH>%l<COLRESET>` | The format of each line when listing bookmarks. Check the formatting in the [configuration file template](./share/star/config/star_config.sh.template). |
| `__STAR_LIST_COLUMN_COMMAND` | command stored as a string | `command column -t -s $'\t'` | The command into which the bookmark listing is piped, used to align columns. Note the usage of the tab character as the column separator: the <BR> placeholder is replaced by a tab. |
| `__STAR_LIST_SORT` | `loaded` / `name` / `none` | `loaded` | How to sort the bookmarks. |
| `__STAR_LIST_ORDER` | `asc` / `desc` | `desc` | The order in which to display bookmarks |
| `__STAR_LIST_INDEX` | `asc` / `desc` | `asc` | The order of the index |

See the [configuration file template](./share/star/config/star_config.sh.template) to know how to properly customize `__STAR_LIST_FORMAT` and `__STAR_LIST_COLUMN_COMMAND` (and the other variables).

## Troubleshooting

## Contributions and development
<!-- Contributions are welcome! Please submit issues or pull requests to improve star. -->

### Future work

#### Features  <!-- omit from toc -->
- [ ] Add setting for `star-purge`: automatically remove stars (auto), ask for user confirmation (ask), never remove stars (never)
  - [ ] Add a way to ignore some directories from being purged (e.g., using a `.starignore` file)

#### Improvements  <!-- omit from toc -->
- [ ] Replace echo -e with printf for better portability
- [ ] Output all errors into stderr instead of stdout

#### Tests  <!-- omit from toc -->
- [ ] Complete the tests for `star list` to test all options and combinations
- [ ] Add a "no pollution test" that ensures that all local variables are declared as local, and no unwanted global variables are created
- [ ] Add tests for environment variable generation
- [ ] Add shellcheck testing in CI

#### Dependencies removal  <!-- omit from toc -->
- [ ] Remove dependency on `bash >= 3.2` for Zsh by translating the bash autocompletion system in pure Zsh

### Pull requests

<!-- TODO -->

### Testing

<!-- TODO -->

## Contributors

Special thanks to [@PourroyJean](https://www.github.com/PourroyJean) for contributing to this project.

## License

[Apache](./LICENSE)  
> Copyright 2025 Fruchix
