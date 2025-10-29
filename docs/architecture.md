
## Naming conventions

### Environment variables

All environment variables should be in upper snake case.

Environment variables used by the star program such as the path to installation, color codes, etc. must follow the following conventions:
- MUST NEVER be prefixed with `$STAR_*`. This is reserved to dynamically set environment variables, which is a feature designed for the user
- should be prefixed with `$_STAR_*` for variables related to the software installation (e.g. `$_STAR_DATA_HOME`)
- should be prefixed with `$__STAR_*` for variable related to the software configuration (e.g. `$__STAR_COLOR_NAME`) (this should cover all other cases).

### Program variables

When working with functions that will be put in the user's environment, all variables should be declared local, in lower snake case.

```bash
local variable_example
```