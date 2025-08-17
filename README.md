# star

star is a CLI tool that allows you to bookmark your favorite folders and instantly navigate to them.

## Requirements

This software has been developed on bash >= 5.2, untested on prior versions (pretty sure it does not work on bash 3).
It uses GNU tools such as `find`, `basename`, which are not always the default (e.g. find exists on MacOS, but does not have the same options as the GNU version).

On MacOS, GNU utils can be installed using brew: https://apple.stackexchange.com/questions/69223/how-to-replace-mac-os-x-utilities-with-gnu-core-utilities.

## Installation

Clone the repo and source the file [`star.sh`](./star.sh):
```bash
git clone https://github.com/Fruchix/star.git
cd star
source star.sh
```

Also source the file in your `.bashrc`:
```
echo "source $(pwd)/star.sh" >> ~/.bashrc
```
or `.zshrc`:
```
echo "source $(pwd)/star.sh" >> ~/.zshrc
```

### Customization

You can customize star by editing the following variables at the top of the `star.sh` file:

| Variable | Value | Description |
| - | - | - |
| `_STAR_EXPORT_ENV_VARIABLES` | `yes\|no` | Enable or disable [environment variables](#environment-variables). |
| `_STAR_ENV_PREFIX` | String composed of upper case letters and underscores | The common prefix of the environment variables created according to the star names |
| `_STAR_DIR` | Path | Directory in which to store the symbolink links (stars). Will be created if it does not exist. Will be removed when resetting star. |

I strongly advise against modifying the value of `_STAR_DIR_SEPARATOR`.

## Usage

```
star [MODE [ARGUMENTS...]]
```
Without MODE:
- Show this help message.

With `MODE`:
- Will execute the feature associated with this option.
- `MODE` can be one of `add`, `list`, `load`, `rename`, `remove`, `reset`, `help`, or one of their shortnames (such as `-h` for `help`). Use `star help` for more information on short parameters and aliases.

---
```
star add [NAME]
sa [NAME]
```
Add the current directory to the list of starred directories.
The new star will be named after `NAME` if provided, otherwise it will use the basename of the current directory.
`NAME` must be unique (among all stars).
`NAME` can contain slashes `/`.

---
```
star list
sL
```
List all starred directories, sorted according to last load (top ones are the last loaded stars).

---
```
star load [STAR]
sl
```
Navigate (cd) into the specified STAR directory.
If no argument is provided, it displays the list of starred directories (same behavior as star list).

`STAR` should be the name or index of a starred directory (one that is listed using "star list").

> Also updates the last accessed time (used to sort stars when listing them).
---
```
star rename <EXISTING_STAR> <NEW_STAR_NAME>
```
Rename an existing star.

---
```
star remove <STAR> [STAR]...
srm <STAR> [STAR]...
```
Remove one or more starred directories.

`STAR` should be the name of a starred directory.

---
```
star reset [-f|--force]
```
Remove the ".star" directory (thus remove the starred directories).
The argument -f or --force will force the reset without prompting the user.

---
```
star help
```
Get more information.

## Faster Usage

> Use `star help` for all options and aliases.

The following aliases are provided to make your life easier:
- `sa` = star add
- `sah` = star add
- `sL` = star list
- `sl` = star load (which is the same as "star list" when no argument is provided)
- `unstar` = star remove
- `srm` = star remove

## Example

```bash
fruchix@debian:~/Documents/star$ star list
No ".star" directory (will be created when adding new starred directories).

fruchix@debian:~/Documents/star$ star add
Added new starred directory: star -> /home/fruchix/Documents/star

fruchix@debian:~/Documents/star$ star list
1:  star  ->  /home/fruchix/Documents/star

fruchix@debian:~/Documents/star$ cd ..

fruchix@debian:~/Documents$ star add my/docs
Added new starred directory: my/docs -> /home/fruchix/Documents

# my/doc is not composed of two directories "my" and "docs", 
# but is a star name containing a slash

fruchix@debian:~/Documents$ sl
1:  my/docs  ->  /home/fruchix/Documents
2:  star     ->  /home/fruchix/Documents/star

fruchix@debian:~/Documents$ cd

fruchix@debian:~$ sl star

fruchix@debian:~/Documents/star$ sl my/docs

fruchix@debian:~/Documents$ unstar my/docs
Removed starred directory: my/docs
```

## Environment variables

To allow users to list, copy or even archive their files located in a starred directory, `star` exports environment variables that leads to them.

For each starred directory, an environment variable is exported with the format: `STAR_NAME=/path/to/starred/directory`. 

For example, with the following stars:
- work
- one-drive
- projects/star

The following environment variables will be exported:
- STAR_WORK
- STAR_ONE_DRIVE
- STAR_PROJECTS_STAR

By default, the prefix of the environment variable is "STAR_", but it can be edited by changing the value of `_STAR_ENV_PREFIX` (see [Customization](#customization)).

This default prefix allows users to type `$STAR` then use tab and autocompletion to select a starred directory.

Example usages:
- List files in starred directory: `ls $STAR_WORK`
- Copy a file: `cp $STAR_ONE_DRIVE/myfile .`


## License

[Apache](./LICENSE)  
> Copyright 2025 Fruchix

## Contributing
Contributions are welcome! Please submit issues or pull requests to improve star.

## Contributors

Special thanks to [@PourroyJean](https://www.github.com/PourroyJean) for contributing to this project.
