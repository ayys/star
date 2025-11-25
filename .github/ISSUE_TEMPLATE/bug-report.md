---
name: Bug report
about: Create a report to help us improve star
title: ''
labels: bug
assignees: ''

---

### Describe the bug
<!-- A clear and concise description of what the bug is. -->

### To Reproduce
Steps to reproduce the behavior:

<!-- As star is heavily linked with the shell's environment, some problems can arise because of some user-defined functions/aliases. -->
<!-- If possible, try to reproduce the behaviour with a minimal shell as below (does not source shell configuration files). -->

On Bash:
```sh
bash --noprofile --norc
export PATH="path/to/star/bin:$PATH"
eval "$(command star init bash)"
... # Other commands to reproduce the bug
```

OR

On Zsh:
```sh
zsh -df
export PATH="path/to/star/bin:$PATH"
eval "$(command star init zsh)"
... # Other commands to reproduce the bug
```

<!-- If the problem only appears when you source your shell configuration files, please add your configuration files to the bug report. -->

### Expected behavior
<!-- A clear and concise description of what you expected to happen. -->

### Screenshots
<!-- If applicable, add screenshots to help explain your problem. -->

### Desktop
 - OS + distribution: <!-- e.g. Arch Linux 2019.07.01 -->
 - Terminal: <!-- e.g. Konsole -->
 - Shell + shell version: <!-- `echo $ZSH_VERSION` or `echo $BASH_VERSION` -->
 - Star version: <!-- or git commit hash if installed via git -->

### Additional context
<!-- Add any other context about the problem here. -->
